import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// import 'dart:convert' show utf8;

import 'edit_data.dart';
import 'input_manual_page.dart';

enum MenuOption { uploadExcel, inputManual }

class UpdateData extends StatefulWidget {
  const UpdateData({super.key});

  @override
  State<UpdateData> createState() => _UpdateDataState();
}

class _UpdateDataState extends State<UpdateData> {
  List<Map<String, String>> _dataList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _fetchData();

    setState(() {
      _dataList = data;
    });
  }

  Future<List<Map<String, String>>> _fetchData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('/data-umum/title/list_title/')
        .orderBy('judul')
        .get();

    final fetchedMap = [
      for (var doc in snapshot.docs)
        {
          'id': doc.id,
          'title': (doc['judul'] as String),
          'link': (doc['link'] as String),
        },
    ];

    return fetchedMap;
  }

  void _seeData({required Map<String, String> initialData}) async {
    bool isRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowData(initialData: initialData),
      ),
    );

    if (isRefresh) {
      final freshData = await _fetchData();
      setState(() {
        _dataList = freshData;
      });
    }
  }

  Future<void> _addManualInput() async {
    bool? isAdded = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManualInputPage()),
    );

    if (isAdded == null) return;
    if (isAdded) {
      final newData = await _fetchData();
      setState(() {
        _dataList = newData;
      });
    }
  }

  Future<void> showUnderDevelopmentDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      // Pengguna harus menekan tombol untuk menutup dialog
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          // Menambahkan ikon untuk membuatnya lebih menarik secara visual
          icon: const Icon(Icons.construction_outlined, size: 48),
          title: const Text(
            'Segera Hadir!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Fitur ini sedang dalam tahap pengembangan.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Terima kasih atas kesabaran Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // Tombol untuk menutup dialog
            TextButton(
              child: const Text('Mengerti'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Data Publik')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _dataList.length,
        itemBuilder: (context, index) {
          final data = _dataList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              title: Text(data['title']!),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _seeData(initialData: data),
                    tooltip: 'Lihat',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: PopupMenuButton<MenuOption>(
        // Callback saat salah satu item menu dipilih
        onSelected: (MenuOption item) {
          // Logika untuk menangani pilihan
          switch (item) {
            case MenuOption.uploadExcel:
              showUnderDevelopmentDialog(context);
              break;
            case MenuOption.inputManual:
              _addManualInput();
              break;
          }
        },

        itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
          const PopupMenuItem<MenuOption>(
            value: MenuOption.uploadExcel,
            child: ListTile(
              leading: Icon(Icons.file_upload),
              title: Text('Upload Data Excel'),
            ),
          ),
          const PopupMenuItem<MenuOption>(
            value: MenuOption.inputManual,
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('Input Manual'),
            ),
          ),
        ],

        // Bagian ini membuat PopupMenuButton terlihat seperti FAB
        tooltip: 'Tambah Data Baru',
        child: Container(
          width: 56.0,
          height: 56.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.secondary, // Warna FAB
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white, // Warna ikon
          ),
        ),
      ),
    );
  }
}

// class DataFormDialog extends StatefulWidget {
//   final Map<String, String>? initialData;
//   const DataFormDialog({this.initialData});

//   @override
//   State<DataFormDialog> createState() => _DataFormDialogState();
// }

// class _DataFormDialogState extends State<DataFormDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _titleController;

//   String? _pickedFileName;
//   String? _pickedFileContent;

//   @override
//   void initState() {
//     super.initState();
//     _titleController = TextEditingController(
//       text: widget.initialData?['title'] ?? '',
//     );
//     if (widget.initialData != null) {
//       _pickedFileContent = widget.initialData?['table_data'];
//       _pickedFileName = 'data_lama.csv';
//     }
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['csv', 'xlsx', 'xls'],
//       withData: true,
//     );

//     if (result != null) {
//       setState(() {
//         final file = result.files.first;
//         _pickedFileName = file.name;
//         _pickedFileContent = utf8.decode(file.bytes!);
//       });
//     }
//   }

//   void _submit() {
//     if (_formKey.currentState!.validate()) {
//       if (_pickedFileContent == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Harap pilih file tabel terlebih dahulu'),
//           ),
//         );
//         return;
//       }
//       final result = {
//         'title': _titleController.text,
//         'table_data': _pickedFileContent!,
//       };
//       Navigator.pop(context, result);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(
//         widget.initialData == null ? 'Tambah Data Baru' : 'Edit Data',
//       ),
//       content: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextFormField(
//                 controller: _titleController,
//                 decoration: const InputDecoration(labelText: 'Judul Data'),
//                 validator: (v) =>
//                     v!.isEmpty ? 'Judul tidak boleh kosong' : null,
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 'Isi Tabel',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade400),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         _pickedFileName ?? 'Tidak ada file dipilih',
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     OutlinedButton(
//                       onPressed: _pickFile,
//                       child: const Text('Pilih File'),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Batal'),
//         ),
//         ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
//       ],
//     );
//   }
// }

class ShowData extends StatefulWidget {
  final Map<String, String> initialData;
  const ShowData({super.key, required this.initialData});

  @override
  State<ShowData> createState() => _ShowData();
}

class _ShowData extends State<ShowData> {
  late final String linkData;
  late Future<QuerySnapshot> _kontakFuture;
  List<String> _namaKolom = [];
  QuerySnapshot? _cachedSnapshots;
  bool isChanged = false;

  @override
  void initState() {
    super.initState();
    linkData = widget.initialData['link']!;
    _kontakFuture = FirebaseFirestore.instance.collection(linkData).get();
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

  Future<void> _deleteData() async {
    try {
      final snapshot = _cachedSnapshots!;

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      FirebaseFirestore.instance
          .collection('/data-umum/title/list_title/')
          .doc(widget.initialData['id'])
          .delete();

      isChanged = true;
      if (mounted) {
        _showStatusDialog(
          context,
          icon: Icons.check_circle_outline,
          color: Colors.green,
          message: 'Berhasil Dihapus!',
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pop(context, isChanged);
    } catch (e) {
      print(e);

      if (!mounted) return;
      _showStatusDialog(
        context,
        icon: Icons.highlight_off,
        color: Colors.red,
        message: 'Gagal Menghapus Data\nSilakan Coba Lagi',
      );
    }
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Konfirmasi'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Data yang sudah dihapus tidak bisa dikembalikan.'),
                SizedBox(height: 8),
                Text('Apakah Anda yakin?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('YA, HAPUS'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _deleteData(); // Lanjutkan ke proses hapus
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('lib/assets/backgroundd.jpg', fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: 0.3)),
          ],
        ),
        title: const Text(
          'Tabel Data',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, isChanged);
          },
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _kontakFuture,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan!'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Belum ada data / Atau Kemungkinan ada kesalahan!'),
            );
          }

          _cachedSnapshots = snapshot.data!;

          Map<String, dynamic> dataColumns =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;
          _namaKolom = dataColumns.keys.toList();

          List<DataRow> dataRows = snapshot.data!.docs.asMap().entries.map((
            entry,
          ) {
            int index = entry.key;
            DocumentSnapshot document = entry.value;
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>((states) {
                if (index.isEven) {
                  return Colors.grey.withValues(alpha: .1);
                }
                return null;
              }),
              cells: _namaKolom.map((kolom) {
                final value = data[kolom];
                String displayValue = '';
                if (value is Timestamp) {
                  displayValue = DateFormat(
                    'dd/MM/yyyy',
                  ).format(value.toDate());
                } else {
                  displayValue = value?.toString() ?? '';
                }
                return DataCell(Center(child: Text(displayValue)));
              }).toList(),
            );
          }).toList();
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    widget.initialData['title']!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        Expanded(
                          child: DataTable(
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
                              borderRadius: BorderRadius.circular(
                                11,
                              ), // Sesuaikan dengan radius Card
                            ),
                            horizontalMargin:
                                0, // Hapus margin bawaan di kiri dan kanan
                            columnSpacing: 16,

                            // ======== KOLOM (HEADER) ========
                            columns: _namaKolom.map((String columnName) {
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

                            rows: dataRows,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Tombol Edit Data
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditableDataPage(
                                  initialSnapshot: _cachedSnapshots!,
                                  collectionPath: linkData,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // Jarak antar tombol
                      // Tombol Ganti Data
                      // Expanded(
                      //   child: ElevatedButton.icon(
                      //     icon: const Icon(Icons.sync_alt),
                      //     label: const Text('Ganti Baru'),
                      //     onPressed: () {},
                      //     style: ElevatedButton.styleFrom(
                      //       padding: const EdgeInsets.symmetric(vertical: 12),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Hapus'),
                          onPressed: () {
                            _showConfirmationDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.red[700], // Warna merah untuk aksi hapus
                            foregroundColor:
                                Colors.white, // Warna teks dan ikon
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
