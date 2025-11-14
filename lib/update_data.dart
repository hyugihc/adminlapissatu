import 'package:admin_lapissatu/atoms/widgets_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_lapissatu/excel_to_db.dart';
import 'input_manual_page.dart';

enum MenuOption { uploadExcel, inputManual }

class UpdateData extends StatefulWidget {
  const UpdateData({super.key});

  @override
  State<UpdateData> createState() => _UpdateDataState();
}

class _UpdateDataState extends State<UpdateData> {
  List<Map<String, dynamic>> _dataList = [];

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

  Future<List<Map<String, dynamic>>> _fetchData() async {
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
          'category': doc['category'] as int,
          'subcategory': doc['subcategory'] as int,
        },
    ];

    return fetchedMap;
  }

  void _seeData({required Map<String, dynamic> initialData}) async {
    final isRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowData(initialData: initialData),
      ),
    );

    if (isRefresh == true) {
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

  Future<void> _addExcelInput() async {
    final excelHelper = ExcelToDB(context: context);
    bool? isAdded = await excelHelper.pickAndProcessFile();

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
                    onPressed: () {
                      print(data);
                      _seeData(initialData: data);
                    },
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
              _addExcelInput();
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

class ShowData extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const ShowData({super.key, required this.initialData});

  @override
  State<ShowData> createState() => _ShowData();
}

class _ShowData extends State<ShowData> {
  late final String linkData;
  late Future<QuerySnapshot> _kontakFuture;
  QuerySnapshot? _cachedSnapshots;
  bool isChanged = false;
  Map<String, dynamic> _atribute = {};
  List<Map<String, dynamic>> data = [];
  late final int _subCatIdx;
  late final int _catIdx;

  @override
  void initState() {
    super.initState();
    linkData = widget.initialData['link']!;
    _subCatIdx = widget.initialData['subcategory']!;
    _catIdx = widget.initialData['category']!;
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
          for (var doc in _cachedSnapshots!.docs) {
            if (doc.id == 'atribut') {
              _atribute = doc.data() as Map<String, dynamic>;
            } else {
              data.add(doc.data() as Map<String, dynamic>);
            }
          }

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
                  // #########
                  if (_atribute.isEmpty || data.isEmpty)
                    const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('KOSONG'),
                        ),
                      ),
                    )
                  else
                    DesignedTableData(atribute: _atribute, data: data),
                  const SizedBox(height: 16),

                  // Card(
                  //   elevation: 4,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   // Mencegah konten di dalam Card keluar dari sudut yang melengkung
                  //   clipBehavior: Clip.antiAlias,
                  //   child: DesignedTableData(atribute: _atribute, data: data),
                  // ),
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
                                builder: (context) => ManualInputPage(
                                  dataIn: {
                                    'atribut': _atribute,
                                    'data': data,
                                    'title': widget.initialData['title'],
                                    'category': _catIdx,
                                    'subcategory': _subCatIdx,
                                    'isEdited': true,
                                  },
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Hapus'),
                          onPressed: () {
                            _showConfirmationDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
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
