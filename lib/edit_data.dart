import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditableDataPage extends StatefulWidget {
  final QuerySnapshot initialSnapshot;
  final String collectionPath;

  const EditableDataPage({
    super.key,
    required this.initialSnapshot,
    required this.collectionPath,
  });

  @override
  State<EditableDataPage> createState() => _EditableDataPageState();
}

class _EditableDataPageState extends State<EditableDataPage> {
  // Variabel untuk menyimpan data tabel secara lokal
  late List<Map<String, dynamic>> _dataRows;
  late List<String> _columnNames;

  // Menyimpan ID dokumen awal untuk perbandingan saat menyimpan
  late Set<String> _initialDocIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Inisialisasi list dari snapshot yang diterima
    _dataRows = [];
    _columnNames = [];
    _initialDocIds = {};

    if (widget.initialSnapshot.docs.isNotEmpty) {
      // Ambil nama kolom dari dokumen pertama
      final dtFirst =
          widget.initialSnapshot.docs.first.data()! as Map<String, dynamic>;
      _columnNames = dtFirst.keys.toList();

      // Pindahkan data dari QueryDocumentSnapshot ke List<Map> lokal
      for (var doc in widget.initialSnapshot.docs) {
        Map<String, dynamic> rowData = doc.data()! as Map<String, dynamic>;
        rowData['__docId__'] = doc.id;
        _dataRows.add(rowData);
        _initialDocIds.add(doc.id);
      }
    }
  }

  // Fungsi untuk menambah baris baru di tabel
  void _addRow() {
    setState(() {
      final newRow = <String, dynamic>{};
      for (var col in _columnNames) {
        newRow[col] = ''; // Inisialisasi dengan string kosong
      }
      _dataRows.add(newRow);
    });
  }

  // Fungsi untuk menghapus baris dari tabel
  void _deleteRow(int index) {
    setState(() {
      _dataRows.removeAt(index);
    });
  }

  // Fungsi untuk menyimpan semua perubahan ke Firestore
  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final collection = FirebaseFirestore.instance.collection(
        widget.collectionPath,
      );
      final batch = FirebaseFirestore.instance.batch();

      final currentDocIds = <String>{};

      // Proses update dan penambahan
      for (final row in _dataRows) {
        final docId = row['__docId__'];
        final dataToSave = Map<String, dynamic>.from(row)..remove('__docId__');

        if (docId != null) {
          // Ini adalah dokumen lama (UPDATE)
          currentDocIds.add(docId);
          batch.update(collection.doc(docId), dataToSave);
        } else {
          // Ini adalah dokumen baru (CREATE/SET)
          batch.set(collection.doc(), dataToSave);
        }
      }

      // Proses penghapusan
      final docsToDelete = _initialDocIds.difference(currentDocIds);
      for (final docId in docsToDelete) {
        batch.delete(collection.doc(docId));
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perubahan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Kirim sinyal bahwa data berubah
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menambahkan kolom 'Aksi' secara dinamis jika ada data
    final displayColumns = _columnNames.isNotEmpty
        ? [..._columnNames, 'Aksi']
        : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Data'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Simpan Perubahan',
            ),
        ],
      ),
      body: _columnNames.isEmpty
          ? const Center(child: Text('Tidak ada data untuk diedit.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      DataTable(
                        // ======== STYLING DARI ANDA ========
                        headingRowColor: WidgetStateProperty.all(
                          Colors.blue[700],
                        ),
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        border: TableBorder.all(
                          width: 1,
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        horizontalMargin: 0,
                        columnSpacing: 16,

                        // ======== KOLOM (HEADER) ========
                        columns: displayColumns.map((String columnName) {
                          return DataColumn(
                            label: Expanded(
                              child: Center(
                                child: Text(
                                  columnName,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }).toList(),

                        // ======== BARIS (DATA) ========
                        rows: _dataRows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final rowData = entry.value;

                          return DataRow(
                            cells: displayColumns.map((colName) {
                              if (colName == 'Aksi') {
                                return DataCell(
                                  Center(
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red[700],
                                      ),
                                      onPressed: () => _deleteRow(index),
                                    ),
                                  ),
                                );
                              }

                              return DataCell(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: TextFormField(
                                    initialValue:
                                        rowData[colName]?.toString() ?? '',
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      // Update data lokal secara langsung
                                      _dataRows[index][colName] = value;
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRow,
        tooltip: 'Tambah Baris',
        child: const Icon(Icons.add),
      ),
    );
  }
}
