// import 'package:excel/excel.dart';
import 'package:admin_lapissatu/atoms/const_var.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:collection/collection.dart';

import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_lapissatu/atoms/enum_var.dart';
import 'package:admin_lapissatu/atoms/widgets_data.dart';
import 'package:admin_lapissatu/atoms/snackbar_info.dart';

class ColumnDefinition {
  final String name;
  final DataType type;

  ColumnDefinition({required this.name, required this.type});
}

class ManualInputPage extends StatefulWidget {
  final Map<String, dynamic>? dataIn;
  const ManualInputPage({super.key, this.dataIn});

  @override
  State<ManualInputPage> createState() => _ManualInputPageState();
}

class _ManualInputPageState extends State<ManualInputPage> {
  int _currentStep = 1;
  final List<ColumnDefinition> _columns = [
    ColumnDefinition(name: 'id_row', type: DataType.integer),
  ];
  Map<String, dynamic> _atribut = {};
  List<Map<String, dynamic>> _rowData = [];

  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  late Map<String, DateTime?> _dateValues;
  final TextEditingController _titleController = TextEditingController();
  String? _kategoriData;
  final List<String> _items = Category.values
      .map((e) => e.name.toUpperCase())
      .toList();
  bool editing = false;
  int? idxEdited;

  final String _atributKey = 'atribut_data';
  final String _draftKey = 'isi_data_draft';
  String? _subKategoriData;
  List<String> _subItems = [];
  late final Map<Category, List<String>> _subCategoryOptions;

  late final List<Map<String, dynamic>>? _oriRowData;
  late final Map<String, dynamic>? _oriAtribut;
  late final int? _oriCategory;
  late final int? _oriSubCategory;
  late final String? _oriTitle;
  String? _linkCollection;
  String? _metaId;

  String _selectedChartType = 'Bar Chart';
  final List<String> _chartTypeOptions = [
    'Bar Chart',
    'Line Chart',
    'Tidak Perlu Ditampilkan',
  ];

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _dateValues = {};
    _subCategoryOptions = AppVar.subCategory;
    if (widget.dataIn == null) {
      _loadDraft();
    } else {
      _loadDataIn();
      print('IDMETA : $_metaId');
      print('ORI ATRIBUT  $_oriAtribut');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showAddColumnDialog({int? idx}) {
    final nameController = TextEditingController();
    DataType? selectedType;
    if (idx == null) {
      selectedType = DataType.string;
    } else {
      ColumnDefinition kolom = _columns[idx];
      selectedType = kolom.type;
      nameController.text = kolom.name;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: idx == null
              ? const Text('Tambah Kolom Baru')
              : const Text('Edit Kolom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Kolom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    SnackbarHelper.show(
                      context,
                      message: 'Nama kolom tidak boleh kosong',
                      type: SnackbarType.error,
                    );
                    return 'Nama kolom tidak boleh kosong';
                  }
                  if (_columns.any((c) => c.name == value) && idx == null) {
                    SnackbarHelper.show(
                      context,
                      message: 'Nama kolom tidak boleh kosong',
                      type: SnackbarType.error,
                    );
                    return 'Nama kolom sudah ada';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DataType>(
                isExpanded: true,
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Tipe Data'),
                items: DataType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(overflow: TextOverflow.ellipsis, switch (type) {
                      DataType.integer => 'Integer -> 10',
                      DataType.float => 'Desimal -> 10.5',
                      DataType.string => 'String -> "Hello"',
                      DataType.datetime =>
                        'Tanggal Waktu -> 2023-01-01 12:00:00',
                      DataType.year => 'Tahun -> 2025',
                      DataType.month => 'Bulan -> 01-2025',
                      DataType.date => 'Tanggal -> 06-01-2025',
                      DataType.money => 'Uang -> Rp. 100,00',
                    }),
                  );
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
                if (idx == null) {
                  if (nameController.text.isNotEmpty &&
                      !_columns.any((c) => c.name == nameController.text)) {
                    setState(() {
                      _columns.add(
                        ColumnDefinition(
                          name: nameController.text,
                          type: selectedType!,
                        ),
                      );
                    });
                  }
                } else {
                  if (nameController.text.isNotEmpty &&
                      !_columns.asMap().entries.any(
                        (col) =>
                            col.key != idx &&
                            col.value.name == nameController.text,
                      )) {
                    setState(() {
                      _columns[idx] = ColumnDefinition(
                        name: nameController.text,
                        type: selectedType!,
                      );
                    });
                  }
                }
                Navigator.pop(context);
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
    _atribut['title'] = _titleController.text;

    setState(() {
      _atribut['column'] = null;
      for (var col in _columns) {
        if (col.name == 'id_row') {
          print('id_row exist');
        } else if (col.type == DataType.string ||
            col.type == DataType.integer ||
            col.type == DataType.float ||
            col.type == DataType.money ||
            col.type == DataType.year) {
          _controllers[col.name] = TextEditingController();
        } else {
          _dateValues[col.name] = null;
        }
        var columnMap = _atribut['column'] as List<Map<String, dynamic>>? ?? [];
        columnMap.add({col.name: DataType.values.indexOf(col.type)});
        _atribut['column'] = columnMap;
        print('kolom ${col.name} ditambahkan');
      }
      _currentStep = 2;
      editing = false;
      idxEdited = null;
    });
  }

  void _confirmData() {
    if (_rowData.isNotEmpty && _atribut.isNotEmpty) {
      setState(() {
        _currentStep = 3;
        if (_atribut['chart'] == null) {
          _atribut['chart'] = 0;
        }
      });
    }
  }

  Widget _buildDynamicInputField(ColumnDefinition column) {
    switch (column.type) {
      case DataType.string:
        return TextFormField(
          controller: _controllers[column.name],
          decoration: InputDecoration(labelText: '${column.name} (teks)'),
        );
      case DataType.integer:
        return TextFormField(
          controller: _controllers[column.name],
          decoration: InputDecoration(
            labelText: '${column.name} (bilangan bulat)',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\-?\d*')),
          ],
        );
      case DataType.float:
        return TextFormField(
          controller: _controllers[column.name],
          decoration: InputDecoration(labelText: '${column.name} (desimal)'),
          // 1. Ubah keyboardType agar mendukung input desimal
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          // 2. Ganti formatter untuk mengizinkan angka dan satu titik desimal
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\-?\d*\.?\d*')),
          ],
        );
      case DataType.date:
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
      case DataType.year:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(column.name),
          subtitle: Text(
            _controllers[column.name]!.text.isEmpty
                ? 'Pilih Tahun'
                : _controllers[column.name]!.text,
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                final int initialYear =
                    int.tryParse(_controllers[column.name]!.text) ??
                    DateTime.now().year;

                return AlertDialog(
                  title: const Text('Pilih Tahun'),
                  content: SizedBox(
                    width: 300,
                    height: 300,
                    child: YearPicker(
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                      // initialDate: DateTime(initialYear),
                      // selectedDate harus berupa DateTime, jadi kita buat dari initialYear
                      selectedDate: DateTime(initialYear),
                      onChanged: (DateTime dateTime) {
                        // Update controller dengan tahun yang baru dipilih
                        setState(() {
                          _controllers[column.name]!.text = dateTime.year
                              .toString();
                        });
                        // Tutup dialog setelah memilih
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      case DataType.month:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(column.name),
          subtitle: Text(
            _dateValues[column.name] == null
                ? 'Pilih Bulan'
                : DateFormat(
                    'MMMM yyyy',
                    'id_ID',
                  ).format(_dateValues[column.name]!),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showMonthYearPicker(
              context: context,
              initialDate: _dateValues[column.name] ?? DateTime.now(),
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
      case DataType.money:
        return TextFormField(
          controller: _controllers[column.name],
          decoration: InputDecoration(labelText: '${column.name} (Rupiah)'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\-?\d*\.?\d*')),
          ],
        );
      case DataType.datetime:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(column.name),
          subtitle: Text(
            _dateValues[column.name] == null
                ? 'Pilih Tanggal & Waktu'
                // Format untuk menampilkan tanggal dan waktu
                : DateFormat(
                    'dd-MM-yyyy HH:mm',
                  ).format(_dateValues[column.name]!),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            // 1. Tampilkan dialog untuk memilih tanggal
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _dateValues[column.name] ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );

            // Jika pengguna batal memilih tanggal, hentikan proses
            if (pickedDate == null) return;

            // Pastikan widget masih ada sebelum melanjutkan (praktik terbaik)
            if (!context.mounted) return;

            final TimeOfDay? pickedTime = await showTimePicker(
              context: context.mounted
                  ? context
                  : throw Exception('Context is null'),
              initialTime: TimeOfDay.fromDateTime(
                _dateValues[column.name] ?? DateTime.now(),
              ),
            );

            // Jika pengguna batal memilih waktu, hentikan proses
            if (pickedTime == null) return;

            // 3. Gabungkan tanggal dan waktu menjadi satu objek DateTime
            final DateTime finalDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );

            // 4. Update state dengan nilai yang baru
            setState(() {
              _dateValues[column.name] = finalDateTime;
            });
          },
        );
    }
  }

  void _addRowToPreview({bool isEdit = false, int? idx}) {
    if (_formKey.currentState!.validate()) {
      final newRow = <String, dynamic>{};
      for (var col in _columns) {
        if (col.name == 'id_row') {
          newRow[col.name] = _rowData.length + 1;
          continue;
        }
        newRow[col.name] = switch (col.type) {
          DataType.string => _controllers[col.name]!.text,
          DataType.integer => int.tryParse(_controllers[col.name]!.text) ?? 0,
          DataType.float =>
            double.tryParse(_controllers[col.name]!.text) ?? 0.0,
          DataType.money =>
            double.tryParse(_controllers[col.name]!.text) ?? 0.0,
          DataType.date => _dateValues[col.name],
          DataType.year => int.tryParse(_controllers[col.name]!.text) ?? 0,
          DataType.month => _dateValues[col.name],
          DataType.datetime => _dateValues[col.name],
        };
      }

      setState(() {
        if (isEdit) {
          _rowData[idx!] = newRow;
        } else {
          _rowData.add(newRow);
        }

        _formKey.currentState!.reset();
        for (var controller in _controllers.values) {
          controller.clear();
        }
        for (var key in _dateValues.keys) {
          _dateValues[key] = null;
        }
        editing = false;
        idxEdited = null;

        for (int i = 0; i < _rowData.length; i++) {
          _rowData[i]['id_row'] = i + 1;
        }
      });
      _saveDraft();
    }
  }

  Future<void> _saveDraft() async {
    print(_rowData);
    print(_columns);
    List<Map<String, dynamic>> encodableData = _rowData.map((row) {
      return row.map((key, value) {
        if (value is DateTime) {
          return MapEntry(key, value.toIso8601String());
        }
        if (value is Timestamp) {
          return MapEntry(key, value.toDate().toIso8601String());
        }
        return MapEntry(key, value);
      });
    }).toList();

    final prefs = await SharedPreferences.getInstance();

    String atributString = jsonEncode(_atribut);
    String jsonString = jsonEncode(encodableData);
    await prefs.setString(_draftKey, jsonString);
    await prefs.setString(_atributKey, atributString);
    print('Draft saved: $jsonString');
  }

  Future<void> _deleteDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    await prefs.remove(_atributKey);
    print('Draft deleted');
  }

  Future<void> _loadDraft() async {
    print('loading draft...');
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_draftKey);
    String? atributString = prefs.getString(_atributKey);
    print('Draft loaded: $jsonString');

    if (atributString != null) {
      print('Ada draft yang di Load!');
      Map<String, dynamic> decodedMap = jsonDecode(atributString);
      setState(() {
        _atribut = decodedMap;
        _titleController.text = _atribut['title'];
        if (_atribut['category'] != null) {
          _kategoriData = _items[_atribut['category']];
        }
        var tempCol = _atribut['column'] as List<dynamic>? ?? [];
        _columns.clear();
        for (var col in tempCol) {
          _columns.add(
            ColumnDefinition(
              name: col.keys.first,
              type: DataType.values[col.values.first],
            ),
          );
        }
      });
      print(_atribut);
    }
    if (jsonString != null) {
      List<dynamic> decodedList = jsonDecode(jsonString);
      setState(() {
        _rowData = List<Map<String, dynamic>>.from(decodedList);
      });
      const Set<DataType> dateTypes = {
        DataType.month,
        DataType.date,
        DataType.datetime,
      };

      // Loop setiap definisi kolom dari _atribut
      for (var col in _atribut['column']) {
        // Ambil nama kolom dan tipe datanya
        // Asumsi: key dari map 'col' adalah nama kolomnya
        final String columnName = col.keys.first;
        final DataType currentType = DataType.values[col.values.first];

        // Cek apakah kolom ini adalah salah satu dari tipe tanggal
        if (dateTypes.contains(currentType)) {
          // Loop setiap baris data untuk melakukan konversi
          for (var row in _rowData) {
            final dynamic rawValue = row[columnName];
            if (rawValue is String && rawValue.isNotEmpty) {
              // Gunakan tryParse untuk keamanan, agar tidak error jika format salah
              final DateTime? parsedDate = DateTime.tryParse(rawValue);

              if (parsedDate != null) {
                // Ganti nilai String di map dengan objek DateTime yang sudah jadi
                row[columnName] = parsedDate;
              }
            }
          }
        }
      }
    }
    print('_rowData: $_rowData');
    print('_atribut: $_atribut');
    print('_columns: $_columns');
  }

  void _loadDataIn() {
    _atribut = Map.from(widget.dataIn!['atribut']);
    var tempCol = _atribut['column'] as List<dynamic>? ?? [];
    _columns.clear();
    for (var col in tempCol) {
      _columns.add(
        ColumnDefinition(
          name: col.keys.first,
          type: DataType.values[col.values.first],
        ),
      );
    }
    _rowData = List.from(widget.dataIn!['data']);
    // print(_rowData);

    if (widget.dataIn!['isEdited'] != null) {
      _titleController.text = widget.dataIn!['title'];
      _oriTitle = _titleController.text;
      final Category tempCat = Category.values[widget.dataIn!['category']];
      _kategoriData = tempCat.name.toUpperCase();
      _oriCategory = widget.dataIn!['category'];
      // print(tempCat);
      // print(widget.dataIn!['subcategory']);
      _subKategoriData =
          AppVar.subCategory[tempCat]![widget.dataIn!['subcategory']];
      _oriSubCategory = widget.dataIn!['subcategory'];
      _subItems = AppVar.subCategory[tempCat]!;
      _oriRowData = List.from(widget.dataIn!['data']);
      _oriAtribut = Map.from(widget.dataIn!['atribut']);
      _linkCollection = widget.dataIn!['link'];
      _selectedChartType = _chartTypeOptions[_atribut['chart'] ?? 0];
      _metaId = widget.dataIn!['id'];
    }
  }

  Future<void> updateDataBatch(
    String linkCollection, // Nama folder: "data_xxxx"
    List<Map<String, dynamic>> newDataList,
  ) async {
    final String link = linkCollection;
    final firestore = FirebaseFirestore.instance;
    final koleksiRef = firestore.collection(link);

    // Mulai Batch
    WriteBatch batch = firestore.batch();

    try {
      final oldDataSnapshot = await koleksiRef.get();

      for (var doc in oldDataSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (var dataMap in newDataList) {
        DocumentReference newDocRef = koleksiRef.doc(); // Buat ID baru
        batch.set(newDocRef, dataMap);
      }

      batch.set(koleksiRef.doc('atribut'), _atribut);
      await batch.commit();

      print('✅ Selesai! Data berhasil diperbarui (Wipe & Replace).');
    } catch (e) {
      print('❌ Terjadi error saat update batch: $e');
      throw e; // Lempar error agar ditangkap oleh try-catch di _updateAndSave
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
    try {
      for (var dataMap in dataList) {
        DocumentReference docRef = koleksiRef.doc();
        batch.set(docRef, dataMap);
      }
      batch.set(koleksiRef.doc('atribut'), _atribut);
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

  Future<void> _updateAndSave({
    required BuildContext context,
    required String existingLink,
    required String existingTitleId,
  }) async {
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

    if (_atribut['category'] == null && _atribut['subcategory'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category dan Subcategory harus diisi')),
      );
      return;
    }

    // if (!context.mounted) return;
    // _showLoadingDialog(context);

    bool isMetadataChanged =
        _titleController.text != _oriTitle ||
        _atribut['category'] != _oriCategory ||
        _atribut['subcategory'] != _oriSubCategory;

    bool isRowDataChanged = !const DeepCollectionEquality().equals(
      _rowData,
      _oriRowData,
    );

    bool isAtributChanged = !const DeepCollectionEquality().equals(
      _atribut,
      _oriAtribut,
    );

    print('NEW ATRIBUT : $_atribut');
    print('ORI ATRIBUT  $_oriAtribut');

    if (!isMetadataChanged && !isRowDataChanged && !isAtributChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada perubahan data.')),
      );
      return;
    }

    if (!context.mounted) return;
    _showLoadingDialog(context);

    try {
      if (isMetadataChanged) {
        await FirebaseFirestore.instance
            .collection('/data-umum/title/list_title')
            .doc(existingTitleId)
            .update({
              'judul': _titleController.text,
              'category': _atribut['category'],
              'subcategory': _atribut['subcategory'],
              'updated_at': FieldValue.serverTimestamp(),
            });
        // print('✅ Metadata updated');

        // print('METADATA ORI : ${[_oriTitle, _oriCategory, _oriSubCategory]}');
        // print(
        //   'METADATA BARU : ${[_titleController.text, _atribut['category'], _atribut['subcategory']]}',
        // );
      }

      if (isRowDataChanged) {
        await updateDataBatch(existingLink, _rowData); // Fungsi batch lama Anda
        // print('✅ Row Data updated (Full Batch)');
      }
      // C. Update Atribut Saja (Jika Row Data TETAP, tapi setting chart/atribut berubah)
      else if (isAtributChanged) {
        // Kita tidak perlu menghapus/tulis ulang ribuan data row. Cukup update 1 dokumen atribut.
        await FirebaseFirestore.instance
            .collection(existingLink)
            .doc('atribut')
            .set(_atribut); // Gunakan set atau update
        // print('✅ Attribute updated only');
      }

      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        _showStatusDialog(
          context,
          icon: Icons.check_circle_outline,
          color: Colors.green,
          message: 'Berhasil Diperbarui!',
        );
      }
      _deleteDraft();
      await Future.delayed(const Duration(seconds: 2));
      if (!context.mounted) return;

      Navigator.of(context).pop(true);

      // ... Tampilkan Dialog Sukses & Navigasi (sama seperti kode sebelumnya) ...
    } catch (e) {
      print(e);
      if (context.mounted) Navigator.of(context).pop(); // Tutup Loading
      // ... Handle Error ...
    }
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

    if (_atribut['category'] == null && _atribut['subcategory'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category dan Subcategory harus diisi')),
      );
      return;
    }

    if (!context.mounted) return;
    _showLoadingDialog(context);

    try {
      String idlink;
      bool idExists;

      do {
        idlink = generateRandomString(10);
        final docSnapshot = await FirebaseFirestore.instance
            .collection('data-umum/list_data/data_$idlink/')
            .limit(1)
            .get();
        idExists = docSnapshot.docs.isNotEmpty;
        print('NEW ID Generated');
      } while (idExists);
      final String link =
          await uploadDataBatch('data_$idlink', _rowData) as String;
      FirebaseFirestore.instance.collection('/data-umum/title/list_title').add({
        'judul': _titleController.text,
        'link': link,
        'category': _atribut['category'],
        'subcategory': _atribut['subcategory'],
      });
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        _showStatusDialog(
          context,
          icon: Icons.check_circle_outline,
          color: Colors.green,
          message: 'Berhasil Disimpan!',
        );
      }
      _deleteDraft();
      await Future.delayed(const Duration(seconds: 2));
      if (!context.mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      print(e);
      if (context.mounted) Navigator.of(context).pop();

      if (!context.mounted) return;
      _showStatusDialog(
        context,
        icon: Icons.highlight_off,
        color: Colors.red,
        message: 'Gagal Terkirim\nSilakan Coba Lagi',
      );
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      // Mencegah dialog ditutup saat user mengetuk area di luar dialog
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Menyimpan data..."),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Halaman?'),
        content: const Text(
          'Data yang belum disimpan akan hilang. Anda yakin ingin keluar?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _deleteDraft();
              return Navigator.of(context).pop(true);
            },
            child: const Text('Keluar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar dan Simpan Draft'),
          ),
        ],
      ),
    );
  }

  bool _isDraftAvailable() {
    return _titleController.text.isNotEmpty ||
        _columns.isNotEmpty ||
        _rowData.isNotEmpty;
  }

  Future<void> _handleExitAttempt() async {
    if (!_isDraftAvailable()) {
      Navigator.of(context).pop();
      return;
    }
    final shouldPop = await _showExitConfirmationDialog(context);
    if (shouldPop == true) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // 3. Logika saat user menekan tombol kembali bawaan HP
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleExitAttempt();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              if (_currentStep == 1) {
                final isClose = await _showExitConfirmationDialog(context);
                if (isClose == true) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              } else {
                setState(() {
                  _currentStep -= 1;
                });
              }
            },
          ),
          title: Text(
            _currentStep == 1
                ? 'Tentukan Nama Judul & Kolom'
                : 'Tambahkan Data',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: switch (_currentStep) {
            1 => _buildColumnDefinitionStep(),
            2 => _buildDataInputStep(),
            3 => _buildChartSelectionStep(),
            _ => Text('ERROR'),
          },
        ),
        persistentFooterButtons: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: switch (_currentStep) {
              1 => FilledButton(
                onPressed: _confirmColumns,
                child: const SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8.0),
                      Text('Konfirmasi & Lanjutkan Input'),
                    ],
                  ),
                ),
              ),
              2 => FilledButton(
                onPressed: _confirmData,
                child: const SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_outlined),
                      SizedBox(width: 8.0),
                      Text('Pilih Tampilan Chart'),
                    ],
                  ),
                ),
              ),
              3 => FilledButton(
                onPressed: () {
                  if (_linkCollection == null) {
                    _finishAndSave(context: context);
                  } else {
                    _updateAndSave(
                      context: context,
                      existingLink: _linkCollection!,
                      existingTitleId: _metaId!,
                    );
                  }
                },
                child: const SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_as_outlined),
                      SizedBox(width: 8.0),
                      Text('Selesai & Simpan'),
                    ],
                  ),
                ),
              ),
              _ => SizedBox(),
            },
          ),
        ],
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
          'Kategori Data',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        DropdownButton<String>(
          hint: const Text('Pilih Kategori Data'),
          value: _kategoriData,
          isExpanded: true,
          items: _items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _kategoriData = newValue;
              _subKategoriData = null;

              if (newValue != null) {
                final idxCat = _items.indexOf(newValue);
                _atribut['category'] = idxCat;
                _subItems = _subCategoryOptions[Category.values[idxCat]] ?? [];
              } else {
                _subItems = [];
              }
            });
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Subkategori Data',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        DropdownButton<String>(
          hint: const Text('Pilih Subkategori'),
          value: _subKategoriData,
          isExpanded: true,
          // Tampilkan hint "Pilih Kategori Dulu" jika disabled
          // Ini adalah trik UI yang bagus
          disabledHint: Text(
            _kategoriData == null
                ? 'Pilih Kategori Data terlebih dahulu'
                : 'Tidak ada subkategori',
            style: TextStyle(color: Colors.grey[500]),
          ),

          onChanged: _kategoriData == null
              ? null
              : (String? newValue) {
                  setState(() {
                    _subKategoriData = newValue;
                    if (newValue != null) {
                      // Asumsi Anda ingin menyimpan indeksnya juga
                      _atribut['subcategory'] = _subItems.indexOf(newValue);
                    }
                  });
                  print(_atribut);
                },

          items: _subItems.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Kolom yang Akan Dibuat:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _columns.isEmpty
            ? const Text('Belum ada kolom. Klik (+) untuk menambahkan.')
            // Bungkus dengan SizedBox untuk memberikan frame dengan tinggi tetap
            : SizedBox(
                height: 300,
                child: ListView.builder(
                  // Hapus shrinkWrap: true agar ListView bisa di-scroll
                  itemCount: _columns.first.name == 'id_row'
                      ? _columns.length - 1
                      : _columns.length,
                  itemBuilder: (context, index) {
                    int idx = index;
                    if (_columns.first.name == 'id_row') {
                      idx = idx + 1;
                    }
                    final col = _columns[idx];
                    return Card(
                      child: ListTile(
                        title: Text(col.name),
                        subtitle: Text('Tipe: ${col.type.name}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize
                              .min, // Penting! Agar Row tidak makan tempat
                          children: [
                            // --- Tombol Edit ---
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () {
                                _showAddColumnDialog(idx: idx);
                              },
                            ),
                            // --- Tombol Hapus ---
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  for (var dt in _rowData) {
                                    dt.remove(_columns[index].name);
                                  }
                                  _columns.removeAt(index);
                                });
                                print(_rowData);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Tambah Kolom'),
          onPressed: () {
            _showAddColumnDialog();
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildChartSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- HEADER JUDUL ---
        const Text(
          'Visualisasi Data',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pilih jenis grafik yang ingin ditampilkan:',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedChartType,
              isExpanded: true,
              icon: const Icon(Icons.bar_chart),
              items: _chartTypeOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      // Ikon dinamis sesuai teks
                      Icon(switch (value) {
                        'Bar Chart' => Icons.bar_chart_rounded,
                        'Line Chart' => Icons.show_chart_rounded,
                        _ => Icons.visibility_off_rounded,
                      }, color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedChartType = newValue;
                    _atribut['chart'] = _chartTypeOptions.indexOf(
                      _selectedChartType,
                    );
                  });
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 30),

        // --- AREA PREVIEW CHART ---
        const Text(
          'Pratinjau Grafik:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Container untuk Chart
        switch (_selectedChartType) {
          'Bar Chart' => DesignedBarChart(
            data: _rowData,
            atribute: _atribut, // Pastikan _atribut sudah terisi column
          ),
          'Line Chart' => DesignedLineChart(data: _rowData, atribute: _atribut),
          _ => const Center(child: Text("Chart Tidak Ditampilkan")),
        },

        const SizedBox(height: 30),
      ],
    );
  }

  void _delData({required int idx}) {
    setState(() {
      _rowData.removeAt(idx);
      for (int i = 0; i < _rowData.length; i++) {
        _rowData[i]['id_row'] = i + 1;
      }
    });
  }

  void _editData({required int idx}) {
    setState(() {
      for (var col in _columns) {
        if (col.name == 'id_row') {
          continue;
        }
        if (col.type == DataType.string ||
            col.type == DataType.integer ||
            col.type == DataType.float ||
            col.type == DataType.money ||
            col.type == DataType.year) {
          _controllers[col.name]!.text =
              _rowData[idx][col.name]?.toString() ?? '';
        } else {
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
          for (var col in _columns)
            if (col.name != 'id_row') _buildDynamicInputField(col),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: editing
                ? const Icon(Icons.thumb_up_alt_outlined)
                : const Icon(Icons.add),
            label: editing ? const Text('OKE') : const Text('Tambah ke Tabel'),
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
          DesignedTableData(
            atribute: _atribut,
            data: _rowData,
            isPreviewMode: true,
            functionList: {
              'edit': ({required int idx}) => _editData(idx: idx),
              'delete': ({required int idx}) => _delData(idx: idx),
            },
          ),
        ],
      ),
    );
  }
}
