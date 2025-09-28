import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

enum DataType { string, number, timestamp }

class ColumnDefinition {
  final String name;
  final DataType type;

  ColumnDefinition({required this.name, required this.type});
}

class ManualInputPage extends StatefulWidget {
  const ManualInputPage({super.key});

  @override
  State<ManualInputPage> createState() => _ManualInputPageState();
}

class _ManualInputPageState extends State<ManualInputPage> {
  // 1. STATE UNTUK MANAJEMEN ALUR
  int _currentStep = 1;
  final List<ColumnDefinition> _columns = [];
  final List<Map<String, dynamic>> _rowData = [];

  // 2. STATE UNTUK FORM INPUT
  final _formKey = GlobalKey<FormState>();
  // Menyimpan controller dan nilai untuk form yang dinamis
  late Map<String, TextEditingController> _controllers;
  late Map<String, DateTime?> _dateValues;
  final TextEditingController _titleController = TextEditingController();
  bool editing = false;
  int? idxEdited;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _dateValues = {};
  }

  @override
  void dispose() {
    // Pastikan untuk dispose semua controller
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showAddColumnDialog() {
    final nameController = TextEditingController();
    DataType selectedType = DataType.string;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kolom Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Kolom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama kolom tidak boleh kosong';
                  }
                  if (_columns.any((c) => c.name == value)) {
                    return 'Nama kolom sudah ada';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Dropdown untuk memilih tipe data
              DropdownButtonFormField<DataType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Tipe Data'),
                items: DataType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    !_columns.any((c) => c.name == nameController.text)) {
                  setState(() {
                    _columns.add(
                      ColumnDefinition(
                        name: nameController.text,
                        type: selectedType,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _confirmColumns() {
    if (_columns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tolong tambahkan setidaknya satu kolom.'),
        ),
      );
      if (_rowData.isNotEmpty) {
        _rowData.clear();
      }
      return;
    }

    setState(() {
      for (var col in _columns) {
        if (col.type == DataType.string || col.type == DataType.number) {
          _controllers[col.name] = TextEditingController();
        } else if (col.type == DataType.timestamp) {
          _dateValues[col.name] = null;
        }
      }
      _currentStep = 2;
      editing = false;
      idxEdited = null;
    });
  }

  Widget _buildDynamicInputField(ColumnDefinition column) {
    switch (column.type) {
      case DataType.string:
        return TextFormField(
          controller: _controllers[column.name],
          decoration: InputDecoration(labelText: column.name),
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Wajib diisi' : null,
        );
      case DataType.number:
        return TextFormField(
          controller: _controllers[column.name],
          decoration: InputDecoration(labelText: '${column.name} (Angka)'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Wajib diisi' : null,
        );
      case DataType.timestamp:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(column.name),
          subtitle: Text(
            _dateValues[column.name] == null
                ? 'Pilih Tanggal'
                : DateFormat('dd-MM-yyyy').format(_dateValues[column.name]!),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null) {
              setState(() {
                _dateValues[column.name] = picked;
              });
            }
          },
        );
    }
  }

  void _addRowToPreview({bool isEdit = false, int? idx}) {
    if (_formKey.currentState!.validate()) {
      // Validasi tambahan untuk timestamp
      bool allDatesSelected = true;
      for (var col in _columns) {
        if (col.type == DataType.timestamp && _dateValues[col.name] == null) {
          allDatesSelected = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kolom tanggal "${col.name}" wajib diisi.')),
          );
          break;
        }
      }
      if (!allDatesSelected) return;

      final newRow = <String, dynamic>{};
      for (var col in _columns) {
        if (col.type == DataType.string || col.type == DataType.number) {
          newRow[col.name] = _controllers[col.name]!.text;
        } else if (col.type == DataType.timestamp) {
          newRow[col.name] = _dateValues[col.name];
        }
      }

      setState(() {
        if (isEdit) {
          _rowData[idx!] = newRow;
        } else {
          _rowData.add(newRow);
        }
        // Reset form
        _formKey.currentState!.reset();
        for (var controller in _controllers.values) {
          controller.clear();
        }
        for (var key in _dateValues.keys) {
          _dateValues[key] = null;
        }
        editing = false;
        idxEdited = null;
      });
    }
  }

  Future<String?> uploadDataBatch(
    String namaKoleksiBaru,
    List<Map<String, dynamic>> dataList,
  ) async {
    final String link = '/data-umum/list_data/$namaKoleksiBaru';
    final firestore = FirebaseFirestore.instance;
    final koleksiRef = firestore.collection(link);

    WriteBatch batch = firestore.batch();

    print('Mempersiapkan batch...');
    try {
      for (var dataMap in dataList) {
        DocumentReference docRef = koleksiRef
            .doc(); // Membuat dokumen dengan ID acak

        batch.set(docRef, dataMap);
      }
      await batch.commit();

      print('✅ Selesai! Semua data berhasil diunggah dengan batch.');
      return link;
    } catch (e) {
      print('❌ Terjadi error saat mengunggah data dengan batch: $e');
      return null;
    }
  }

  String generateRandomString(int length) {
    const String chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rnd = Random();

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }

  void _showStatusDialog(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Otomatis tutup dialog setelah 2 detik
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 80),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _finishAndSave({required BuildContext context}) async {
    if (_rowData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk disimpan.')),
      );
      return;
    }
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Judul Harus Diisi')));
      return;
    }

    try {
      final String idlink = generateRandomString(10);
      final String link =
          await uploadDataBatch('data_$idlink', _rowData) as String;
      FirebaseFirestore.instance.collection('/data-umum/title/list_title').add({
        'judul': _titleController.text,
        'link': link,
      });

      if (context.mounted) {
        _showStatusDialog(
          context,
          icon: Icons.check_circle_outline,
          color: Colors.green,
          message: 'Berhasil Disimpan!',
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      if (!context.mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      print(e);

      if (!context.mounted) return;
      _showStatusDialog(
        context,
        icon: Icons.highlight_off,
        color: Colors.red,
        message: 'Gagal Terkirim\nSilakan Coba Lagi',
      );
    }

    // Tampilkan hasil di dialog
    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: const Text('Input Selesai'),
    //     content: SingleChildScrollView(child: Text(finalResult.toString())),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.of(context).pop(),
    //         child: const Text('OK'),
    //       ),
    //     ],
    //   ),
    // );
    // print(finalResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 1) {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _currentStep = 1;
              });
            }
          },
        ),
        title: Text(
          _currentStep == 1 ? 'Tentukan Nama Judul & Kolom' : 'Tambahkan Data',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _currentStep == 1
            ? _buildColumnDefinitionStep()
            : _buildDataInputStep(),
      ),
    );
  }

  Widget _buildColumnDefinitionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Judul Data',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(labelText: 'Judul'),
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Wajib diisi' : null,
        ),
        const SizedBox(height: 20),
        const Text(
          'Kolom yang Akan Dibuat:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _columns.isEmpty
            ? const Text('Belum ada kolom. Klik (+) untuk menambahkan.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _columns.length,
                itemBuilder: (context, index) {
                  final col = _columns[index];
                  return Card(
                    child: ListTile(
                      title: Text(col.name),
                      subtitle: Text('Tipe: ${col.type.name}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            for (var dt in _rowData) {
                              dt.remove(_columns[index].name);
                            }
                            _columns.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Tambah Kolom'),
          onPressed: _showAddColumnDialog,
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _confirmColumns,
          child: const Text('Konfirmasi & Lanjutkan Input'),
        ),
      ],
    );
  }

  void _delData({required int idx}) {
    setState(() {
      _rowData.removeAt(idx);
    });
  }

  void _editData({required int idx}) {
    setState(() {
      for (var col in _columns) {
        if (col.type == DataType.string || col.type == DataType.number) {
          _controllers[col.name]!.text = _rowData[idx][col.name];
        } else if (col.type == DataType.timestamp) {
          _dateValues[col.name] = _rowData[idx][col.name];
        }
      }
      editing = true;
      idxEdited = idx;
    });
  }

  Widget _buildDataInputStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _titleController.text,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ..._columns.map((col) => _buildDynamicInputField(col)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: editing
                ? const Icon(Icons.thumb_up_alt_outlined)
                : const Icon(Icons.add),
            label: editing
                ? const Text('OKE')
                : const Text('Tambah ke Tabel Preview'),
            onPressed: () {
              if (editing) {
                _addRowToPreview(isEdit: editing, idx: idxEdited);
              } else {
                _addRowToPreview();
              }
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Table Preview:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Tabel Preview
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                // --- BAGIAN KOLOM ---
                columns: [
                  // 1. Tampilkan semua kolom data yang sudah ada
                  ..._columns.map((c) => DataColumn(label: Text(c.name))),
                  // 2. Tambahkan satu kolom baru untuk 'Aksi' di akhir
                  const DataColumn(label: Text('')),
                ],
                // --- BAGIAN BARIS ---
                rows: _rowData.asMap().entries.map((rowEntry) {
                  int rowIndex =
                      rowEntry.key; // Ini indeks baris (0, 1, 2, ...)
                  var row = rowEntry.value;
                  return DataRow(
                    cells: [
                      // 3. Tampilkan semua sel data yang sudah ada
                      ..._columns.map((col) {
                        final value = row[col.name];
                        String displayValue = '';
                        if (value is DateTime) {
                          displayValue = DateFormat('dd/MM/yyyy').format(value);
                        } else {
                          displayValue =
                              value?.toString() ?? ''; // Tambahkan null check
                        }
                        return DataCell(Text(displayValue));
                      }),
                      // 4. Tambahkan satu sel baru untuk tombol di akhir
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize
                              .min, // Agar row tidak makan banyak tempat
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit',
                              onPressed: () {
                                _editData(idx: rowIndex);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Hapus',
                              onPressed: () {
                                _delData(idx: rowIndex);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              _finishAndSave(context: context);
            },
            child: const Text('Selesai & Simpan'),
          ),
        ],
      ),
    );
  }
}
