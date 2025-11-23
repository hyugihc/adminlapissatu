import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:path_provider/path_provider.dart';
import 'dart:io';

class UpdateInfografis extends StatefulWidget {
  const UpdateInfografis({super.key});

  @override
  State<UpdateInfografis> createState() => _UpdateInfografisState();
}

class _UpdateInfografisState extends State<UpdateInfografis> {
  List<Map<String, String>> infografisList = [];

  Future<List<Map<String, String>>> fetchInfografisFromFirestore() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('infografis')
          .orderBy('time_upload', descending: true)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final List<Map<String, String>> infografisList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title']?.toString() ?? 'Tanpa Judul',
          'image': data['image']?.toString() ?? '',
          'description':
              data['description']?.toString() ?? 'Tidak ada deskripsi.',
        };
      }).toList();
      print(infografisList);
      return infografisList;
    } catch (e) {
      print("Error saat mengambil data infografis: $e");
      return [];
    }
  }

  void _deleteItem(int index) async {
    try {
      DocumentReference documentReference = FirebaseFirestore.instance
          .collection('infografis')
          .doc(infografisList[index]['id']);
      await documentReference.delete();
    } catch (e) {
      print("Error saat menghapus dokumen: $e");
      rethrow;
    }
    setState(() {
      infografisList.removeAt(index);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Infografis berhasil dihapus.')),
      );
    }
  }

  Future<void> _editItem(int index) async {
    final updatedData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) {
          // return Scaffold();
          return EditInfografisPage(initialData: infografisList[index]);
        },
      ),
    );
    if (updatedData != null) {
      setState(() {
        infografisList[index] = updatedData as Map<String, String>;
      });
    }
  }

  Future<void> _addItem() async {
    final newData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddInfografisPage();
        },
      ),
    );
    if (newData != null) {
      setState(() {
        infografisList.add(newData as Map<String, String>);
      });
    }
  }

  void _showImageDialog(BuildContext context, Map<String, dynamic> info) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(12),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Text(
                  info['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: info['image']!,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Text(
                      info['description']!,
                      textAlign: TextAlign.justify,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Infografis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () {
              _addItem();
            },
            tooltip: 'Tambah Infografis Baru',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: fetchInfografisFromFirestore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Jika terjadi error
          if (snapshot.hasError) {
            return const Center(
              child: Text('Gagal memuat data. Silakan coba lagi.'),
            );
          }

          // Jika tidak ada data
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada infografis tersedia.'));
          }

          // Jika data berhasil dimuat, bangun MasonryGridView
          infografisList = snapshot.data!;

          return MasonryGridView.count(
            padding: const EdgeInsets.all(16.0),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            itemCount: infografisList.length,
            itemBuilder: (context, index) {
              final info = infografisList[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _showImageDialog(context, info),
                      child: CachedNetworkImage(
                        imageUrl: info['image'] as String,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
                      child: Text(
                        info['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.blue,
                              size: 20,
                            ),
                            onPressed: () {
                              _editItem(index);
                            },
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () => _deleteItem(index),
                            tooltip: 'Hapus',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EditInfografisPage extends StatefulWidget {
  final Map<String, String> initialData;
  const EditInfografisPage({super.key, required this.initialData});

  @override
  State<EditInfografisPage> createState() => _EditInfografisPageState();
}

class _EditInfografisPageState extends State<EditInfografisPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _currentImage;
  late String _docID;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData['title']);
    _descriptionController = TextEditingController(
      text: widget.initialData['description'],
    );
    _currentImage = widget.initialData['image'] as String;
    _docID = widget.initialData['id'] as String;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(File imageFile) async {
  try {
    // Nama file unik
    String fileName = "infografis_${DateTime.now().millisecondsSinceEpoch}.jpg";

    // Path lokasi upload
    final storageRef = FirebaseStorage.instance
        .ref()
        .child("public_image/infografis/$fileName");

    // Upload file
    UploadTask uploadTask = storageRef.putFile(imageFile);

    // Tunggu upload selesai
    TaskSnapshot snapshot = await uploadTask;

    // Ambil URL download
    String downloadURL = await snapshot.ref.getDownloadURL();

    print("UPLOAD BERHASIL: $downloadURL");
    return downloadURL;

  } catch (e) {
    print("ERROR upload Firebase Storage: $e");
    return null;
  }
}


// GANTI SELURUH FUNGSI _saveChanges DENGAN INI:

void _saveChanges(BuildContext context) async {
  // Tampilkan indikator loading (opsional, tapi disarankan)
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // 1. Cek apakah user mengganti gambar
    if (_imageFile != null) {
      String? uploadedUrl = await _uploadImage(_imageFile!);

      // 2. Jika upload gagal (return null), hentikan proses
      if (uploadedUrl == null) {
        if (context.mounted) {
          Navigator.pop(context); // Tutup loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal upload gambar. Cek koneksi internet.')),
          );
        }
        return; // BERHENTI DI SINI
      }

      _currentImage = uploadedUrl; // Tidak perlu 'as String'
    }

    final Map<String, String> updatedData = {
      'title': _titleController.text,
      'image': _currentImage,
      'description': _descriptionController.text,
    };

    // 3. Update ke Firestore
    DocumentReference documentReference = FirebaseFirestore.instance
        .collection('infografis')
        .doc(_docID);
        
    await documentReference.update(updatedData);
    print("Data berhasil diperbarui!");

    final Map<String, String> result = {
      'id': _docID,
      'title': _titleController.text,
      'description': _descriptionController.text,
      'image': _currentImage,
    };

    if (context.mounted) {
      Navigator.pop(context); // Tutup loading
      Navigator.pop(context, result); // Kembali ke halaman list
    }

  } catch (e) {
    print("Error memperbarui data: $e");
    if (context.mounted) {
      Navigator.pop(context); // Tutup loading jika error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
  
  // Tambahkan fungsi ini di dalam _EditInfografisPageState
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Infografis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _saveChanges(context);
            },
            tooltip: 'Simpan Perubahan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: _imageFile != null
                        ? Image.file(
                            _imageFile as File,
                            height: 200,
                            fit: BoxFit.contain,
                          )
                        : CachedNetworkImage(
                            imageUrl: _currentImage,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_search),
                    label: const Text('Ganti Gambar dari Galeri'),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
}

class AddInfografisPage extends StatefulWidget {
  const AddInfografisPage({super.key});

  @override
  State<AddInfografisPage> createState() => _AddInfografisPageState();
}

class _AddInfografisPageState extends State<AddInfografisPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _pickedImage;
  String? _imageURL;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveNewItem(BuildContext context) async {
    if (_titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _pickedImage != null) {
      
      // Tampilkan loading indicator jika perlu, atau pastikan user tahu proses sedang berjalan
      
      // 1. Cek hasil upload dulu
      String? uploadedUrl = await _uploadImage(_pickedImage!); // Gunakan ! karena sudah dicek null di if atas

      // 2. Jika upload GAGAL (return null), hentikan proses agar tidak crash
      if (uploadedUrl == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengupload gambar. Periksa koneksi internet.')),
          );
        }
        return; 
      }

      _imageURL = uploadedUrl;

      final newData = {
        'title': _titleController.text,
        'image': _imageURL, // Tidak perlu as String karena sudah pasti String
        'description': _descriptionController.text,
        'time_upload': FieldValue.serverTimestamp(),
      };

      try {
        await FirebaseFirestore.instance.collection('infografis').add(newData);
        
        // Data untuk dikirim balik ke halaman sebelumnya
        final Map<String, String> result = {
          'title': _titleController.text,
          'image': _imageURL!,
          'description': _descriptionController.text,
        };

        if (context.mounted) {
          Navigator.pop(context, result);
        }
      } catch (e) {
        print("Error Firestore: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error database: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi!')),
      );
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _pickedImage = File(result.files.single.path!);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
  try {
    // Nama file unik
    String fileName = "infografis_${DateTime.now().millisecondsSinceEpoch}.jpg";

    // Path lokasi upload
    final storageRef = FirebaseStorage.instance
        .ref()
        .child("public_image/infografis/$fileName");

    // Upload file
    UploadTask uploadTask = storageRef.putFile(imageFile);

    // Tunggu upload selesai
    TaskSnapshot snapshot = await uploadTask;

    // Ambil URL download
    String downloadURL = await snapshot.ref.getDownloadURL();

    print("UPLOAD BERHASIL: $downloadURL");
    return downloadURL;

  } catch (e) {
    print("ERROR upload Firebase Storage: $e");
    return null;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Infografis Baru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () {
              _saveNewItem(context);
            },
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_pickedImage!, fit: BoxFit.contain),
                    )
                  : Center(
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Pilih Gambar'),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
}
