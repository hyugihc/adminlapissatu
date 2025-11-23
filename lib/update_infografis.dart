import 'package:admin_lapissatu/atoms/enum_var.dart';
import 'package:admin_lapissatu/atoms/func_utils.dart';
import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';

// import 'dart:convert';
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
    String idDoc = infografisList[index]['id'] as String;
    final bool? updatedData = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddInfografisPage(dataIn: infografisList[index]);
        },
      ),
    );
    if (updatedData == true) {
      Map<String, dynamic> newData = await FireBaseDB.loadDocument(
        collectionPath: 'infografis',
        docId: idDoc,
      );
      newData.remove('time_upload');
      setState(() {
        infografisList[index] = Map<String, String>.from(newData);
      });
    }
  }

  Future<void> _addItem() async {
    final String? newDataId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddInfografisPage();
        },
      ),
    );
    if (newDataId != null) {
      Map<String, dynamic> newData = await FireBaseDB.loadDocument(
        collectionPath: 'infografis',
        docId: newDataId,
      );
      newData.remove('time_upload');
      setState(() {
        infografisList.add(Map<String, String>.from(newData));
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
            // height: MediaQuery.of(context).size.height * 0.7,
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
                      style: TextStyle(color: Colors.black),
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

class AddInfografisPage extends StatefulWidget {
  final Map<String, dynamic>? dataIn;
  const AddInfografisPage({super.key, this.dataIn});

  @override
  State<AddInfografisPage> createState() => _AddInfografisPageState();
}

class _AddInfografisPageState extends State<AddInfografisPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _pickedImage;
  String? _imageURL;

  bool _isEdit = false;
  bool _isImageChanged = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.dataIn != null) {
      _isEdit = true;

      final Map<String, dynamic> dataOld = Map.from(widget.dataIn!);
      _titleController.text = dataOld['title'];
      _descriptionController.text = dataOld['description'];
      _imageURL = dataOld['image'];
    }
    super.initState();
  }

  void _saveNewInfografis(BuildContext context) async {
    LoadingHelper.showLoadingDialog(context);
    if (_titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _pickedImage != null) {
      _imageURL = await FireBaseDB.uploadImage(
        file: _pickedImage!,
        cloudPath: 'public_image/infografis',
      );
      await _pickedImage!.delete();

      final newData = {
        'title': _titleController.text,
        'image': _imageURL as String,
        'description': _descriptionController.text,
        'time_upload': FieldValue.serverTimestamp(),
      };
      try {
        final DocumentReference docRef = await FirebaseFirestore.instance
            .collection('infografis')
            .add(newData);
        if (context.mounted) {
          LoadingHelper.closeLoadingDialog(context);
          Navigator.pop(context, docRef.id);
        }
      } catch (e) {
        print("Error memperbarui data: $e");
        rethrow;
      }
    } else {
      if (context.mounted) {
        LoadingHelper.closeLoadingDialog(context);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua field harus diisi!')));
    }
  }

  void _saveUpdateInfografis(BuildContext context) async {
    LoadingHelper.showLoadingDialog(context);
    bool updated = false;
    if (_isImageChanged) {
      final String newImageURL =
          await FireBaseDB.uploadImage(
                file: _pickedImage!,
                cloudPath: 'public_image/infografis',
              )
              as String;
      await FireBaseDB.deleteImageByUrl(_imageURL!);
      _imageURL = newImageURL;
    }
    final bool isDataChanged;
    if (_titleController.text != widget.dataIn!['title'] ||
        _descriptionController.text != widget.dataIn!['description']) {
      isDataChanged = true;
    } else {
      isDataChanged = false;
    }
    if (_isImageChanged || isDataChanged) {
      final newData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'image': _imageURL,
        'time_upload': FieldValue.serverTimestamp(),
      };
      await FireBaseDB.updateDocument(
        collectionPath: 'infografis',
        docId: widget.dataIn!['id'],
        newData: newData,
      );
      updated = true;
    } else {
      if (context.mounted) {
        SnackbarHelper.show(
          context,
          message: 'Tidak ada data yang diperbarui',
          type: SnackbarType.info,
        );
      }
    }
    if (context.mounted) {
      LoadingHelper.closeLoadingDialog(context);
      Navigator.pop(context, updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEdit
            ? const Text('Update Infografis')
            : const Text('Tambah Infografis Baru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () {
              if (_isEdit) {
                _saveUpdateInfografis(context);
              } else {
                _saveNewInfografis(context);
              }
            },
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 50, right: 50),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: (_pickedImage != null || _isEdit)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            if (_pickedImage != null)
                              Image.file(_pickedImage!, fit: BoxFit.contain)
                            else
                              CachedNetworkImage(
                                imageUrl: _imageURL!,
                                fit: BoxFit.contain,
                              ),

                            TextButton.icon(
                              onPressed: () async {
                                final File? result = await copyPickImage();
                                if (result != null) {
                                  setState(() {
                                    _pickedImage = result;
                                    _isImageChanged = true;
                                  });
                                }
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Ganti Gambar'),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final File? result = await copyPickImage();
                            if (result != null) {
                              setState(() {
                                _pickedImage = result;
                                _isImageChanged = true;
                              });
                            }
                          },
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Pilih Gambar'),
                        ),
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
