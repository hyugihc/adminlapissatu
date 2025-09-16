import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Enum untuk tipe data kolom agar lebih aman dan mudah dibaca
enum DataType { string, number, timestamp }

// Class sederhana untuk menyimpan definisi setiap kolom
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
  int _currentStep = 1; // 1: Definisi Kolom, 2: Input Data
  final List<ColumnDefinition> _columns = [];
  final List<Map<String, dynamic>> _rowData = [];

  // 2. STATE UNTUK FORM INPUT
  final _formKey = GlobalKey<FormState>();
  // Menyimpan controller dan nilai untuk form yang dinamis
  late Map<String, TextEditingController> _controllers;
  late Map<String, DateTime?> _dateValues;

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

  // --- UI & LOGIKA UNTUK LANGKAH 1: DEFINISI KOLOM ---

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
      return;
    }
    // Inisialisasi controller berdasarkan kolom yang sudah dibuat
    setState(() {
      for (var col in _columns) {
        if (col.type == DataType.string || col.type == DataType.number) {
          _controllers[col.name] = TextEditingController();
        } else if (col.type == DataType.timestamp) {
          _dateValues[col.name] = null;
        }
      }
      _currentStep = 2; // Pindah ke langkah input data
    });
  }

  // --- UI & LOGIKA UNTUK LANGKAH 2: INPUT DATA ---

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

  void _addRowToPreview() {
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
        _rowData.add(newRow);
        // Reset form
        _formKey.currentState!.reset();
        for (var controller in _controllers.values) {
          controller.clear();
        }
        for (var key in _dateValues.keys) {
          _dateValues[key] = null;
        }
      });
    }
  }

  void _finishAndSave() {
    if (_rowData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk disimpan.')),
      );
      return;
    }

    // Konversi hasil akhir ke List<Map<String, String>>
    final List<Map<String, String>> finalResult = _rowData.map((row) {
      return row.map((key, value) {
        String stringValue;
        if (value is DateTime) {
          stringValue = DateFormat(
            'yyyy-MM-dd',
          ).format(value); // Format tanggal standar
        } else {
          stringValue = value.toString();
        }
        return MapEntry(key, stringValue);
      });
    }).toList();

    // Tampilkan hasil di dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Input Selesai'),
        content: SingleChildScrollView(child: Text(finalResult.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    // print(finalResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == 1
              ? 'Langkah 1: Tentukan Kolom'
              : 'Langkah 2: Input Data',
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

  // --- WIDGET BUILDER UNTUK SETIAP LANGKAH ---

  Widget _buildColumnDefinitionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                        onPressed: () =>
                            setState(() => _columns.removeAt(index)),
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

  Widget _buildDataInputStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Input Data Baru:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ..._columns.map(
            (col) => _buildDynamicInputField(col),
          ), // Widget inputan dinamis
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Tambah ke Tabel Preview'),
            onPressed: _addRowToPreview,
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
            child: DataTable(
              columns: _columns
                  .map((c) => DataColumn(label: Text(c.name)))
                  .toList(),
              rows: _rowData.map((row) {
                return DataRow(
                  cells: _columns.map((col) {
                    final value = row[col.name];
                    String displayValue = '';
                    if (value is DateTime) {
                      displayValue = DateFormat('dd/MM/yyyy').format(value);
                    } else {
                      displayValue = value.toString();
                    }
                    return DataCell(Text(displayValue));
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _finishAndSave,
            child: const Text('Selesaikan Input & Simpan'),
          ),
        ],
      ),
    );
  }
}
