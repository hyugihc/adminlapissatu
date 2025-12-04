import 'package:admin_lapissatu/atoms/func_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'dart:io';

class UpdatePublikasi extends StatefulWidget {
  const UpdatePublikasi({super.key});

  @override
  State<UpdatePublikasi> createState() => _UpdatePublikasiState();
}

class _UpdatePublikasiState extends State<UpdatePublikasi> {
  List<Map<String, String>> publicationList = [];

  Future<List<Map<String, String>>> fetchPublikasiFromFirestore() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('publikasi')
          .orderBy('release_time', descending: true)
          .limit(20)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final List<Map<String, String>> publications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // 2. Ambil dan format timestamp
        String formattedDate = 'Tanggal tidak tersedia';
        if (data['release_time'] != null && data['release_time'] is Timestamp) {
          DateTime date = (data['release_time'] as Timestamp).toDate();
          formattedDate = DateFormat('d MMMM yyyy').format(date);
        }

        return {
          'id': doc.id,
          'title': data['title']?.toString() ?? '',
          'cover': data['cover']?.toString() ?? '',
          'release_time': formattedDate,
          'abstraction': data['abstraction']?.toString() ?? '',
          'catalog_num': data['catalog_num']?.toString() ?? '',
          'publication_num': data['publication_num']?.toString() ?? '',
          'issn': data['issn']?.toString() ?? '',
          'freq': data['freq']?.toString() ?? '',
          'pub_link': data['pub_link']?.toString() ?? '',
        };
      }).toList();
      return publications;
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          message: 'Terjadi Error saat memuat data',
        );
      }
      print(e);
      return [];
    }
  }

  void _deleteItem(int index) async {
    try {
      DocumentReference documentReference = FirebaseFirestore.instance
          .collection('publikasi')
          .doc(publicationList[index]['id']);
      await documentReference.delete();
    } catch (e) {
      rethrow;
    }
    setState(() {
      publicationList.removeAt(index);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publikasi berhasil dihapus.')),
      );
    }
  }

  Future<void> _editItem(int index) async {
    final String? idData = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditPublikasiPage(initialData: publicationList[index]),
      ),
    );
    if (idData != null) {
      Map<String, dynamic> docData = await FireBaseDB.loadDocument(
        collectionPath: 'publikasi',
        docId: idData,
      );
      DateTime date = (docData['release_time'] as Timestamp).toDate();
      String formattedDate = DateFormat('d MMMM yyyy').format(date);
      docData['release_time'] = formattedDate;
      setState(() {
        publicationList[index] = Map<String, String>.from(docData);
      });
    }
  }

  Future<void> _addItem() async {
    final String? idData = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (context) => EditPublikasiPage()),
    );
    if (idData != null) {
      Map<String, dynamic> docData = await FireBaseDB.loadDocument(
        collectionPath: 'publikasi',
        docId: idData,
      );
      DateTime date = (docData['release_time'] as Timestamp).toDate();
      String formattedDate = DateFormat('d MMMM yyyy').format(date);
      docData['release_time'] = formattedDate;
      Map<String, String> newData = Map<String, String>.from(docData);
      setState(() {
        publicationList.add(newData);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Publikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: _addItem,
            tooltip: 'Tambah Publikasi Baru',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: fetchPublikasiFromFirestore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Gagal memuat data. Silakan coba lagi.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada publikasi tersedia.'));
          }
          publicationList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: publicationList.length,
            itemBuilder: (context, index) {
              final pub = publicationList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: pub['cover']!,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                          width: 100,
                          height: 140,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pub['release_time'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pub['title'] ?? 'Tidak Ada Judul',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pub['abstraction'] ?? 'Tidak ada abstraksi',
                              style: TextStyle(color: Colors.grey[700]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  onPressed: () => _editItem(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _deleteItem(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EditPublikasiPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const EditPublikasiPage({super.key, this.initialData});

  @override
  State<EditPublikasiPage> createState() => _EditPublikasiPageState();
}

class _EditPublikasiPageState extends State<EditPublikasiPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _abstractionController;
  late TextEditingController _catalogNumController;
  late TextEditingController _publicationNumController;
  late TextEditingController _issnController;
  late TextEditingController _freqController;
  late TextEditingController _pubLinkController;
  late TextEditingController _dateController;

  bool _isEdit = false;

  late String? _imageURL;
  File? _imageFile;

  final format = DateFormat('d MMMM yyyy');

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      _isEdit = true;
    }
    _titleController = TextEditingController(text: data?['title'] ?? '');
    _abstractionController = TextEditingController(
      text: data?['abstraction'] ?? '',
    );
    _catalogNumController = TextEditingController(
      text: data?['catalog_num'] ?? '',
    );
    _publicationNumController = TextEditingController(
      text: data?['publication_num'] ?? '',
    );
    _issnController = TextEditingController(text: data?['issn'] ?? '');
    _freqController = TextEditingController(text: data?['freq'] ?? '');
    _pubLinkController = TextEditingController(text: data?['pub_link'] ?? '');
    _dateController = TextEditingController(text: data?['release_time'] ?? '');

    _imageURL = data?['cover'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _abstractionController.dispose();
    _catalogNumController.dispose();
    _publicationNumController.dispose();
    _issnController.dispose();
    _freqController.dispose();
    _pubLinkController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    LoadingHelper.showLoadingDialog(context);
    String? idTemp;

    if (_formKey.currentState!.validate()) {
      if (_imageFile != null) {
        String newImageURL =
            await FireBaseDB.uploadImage(
                  file: _imageFile!,
                  cloudPath: 'public_image/publikasi',
                )
                as String;
        if (_isEdit) {
          await FireBaseDB.deleteImageByUrl(_imageURL!);
          _imageURL = newImageURL;
        } else {
          _imageURL = newImageURL;
        }
      }
      if (_imageURL != null) {
        Timestamp tgl = Timestamp.fromDate(format.parse(_dateController.text));
        final dataFirestore = {
          'title': _titleController.text,
          'cover': _imageURL,
          'abstraction': _abstractionController.text,
          'catalog_num': _catalogNumController.text,
          'publication_num': _publicationNumController.text,
          'issn': _issnController.text,
          'freq': _freqController.text,
          'pub_link': _pubLinkController.text,
          'release_time': tgl,
        };

        if (_isEdit) {
          bool dataChange = false;
          if (widget.initialData!['title'] != _titleController.text ||
              widget.initialData!['cover'] != _imageURL ||
              widget.initialData!['abstraction'] !=
                  _abstractionController.text ||
              widget.initialData!['catalog_num'] !=
                  _catalogNumController.text ||
              widget.initialData!['publication_num'] !=
                  _publicationNumController.text ||
              widget.initialData!['issn'] != _issnController.text ||
              widget.initialData!['freq'] != _freqController.text ||
              widget.initialData!['pub_link'] != _pubLinkController.text ||
              widget.initialData!['release_time'] != _dateController.text) {
            dataChange = true;
          }
          if (dataChange) {
            try {
              idTemp = widget.initialData?['id'];
              await FireBaseDB.updateDocument(
                collectionPath: 'publikasi',
                docId: idTemp!,
                newData: dataFirestore,
              );
            } catch (e) {
              rethrow;
            }
          }
        } else {
          try {
            DocumentReference docRef = await FirebaseFirestore.instance
                .collection('publikasi')
                .add(dataFirestore);
            idTemp = docRef.id;
          } catch (e) {
            rethrow;
          }
        }
        if (mounted) {
          LoadingHelper.closeLoadingDialog(context);
          Navigator.pop(context, idTemp);
        }
      } else {
        if (mounted) {
          showErrorDialog(
            context: context,
            message: 'Terjadi ERROR saat upload gambar',
          );
          LoadingHelper.closeLoadingDialog(context);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap lengkapi semua field dan pilih gambar cover.'),
          ),
        );
        LoadingHelper.closeLoadingDialog(context);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('d MMMM yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialData != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Publikasi' : 'Tambah Publikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
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
                        child: (_imageFile != null || _isEdit)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  children: [
                                    if (_imageFile != null)
                                      Image.file(
                                        _imageFile!,
                                        fit: BoxFit.contain,
                                      )
                                    else
                                      CachedNetworkImage(
                                        imageUrl: _imageURL!,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                        fit: BoxFit.contain,
                                      ),

                                    TextButton.icon(
                                      onPressed: () async {
                                        final File? result =
                                            await copyPickImage();
                                        if (result != null) {
                                          setState(() {
                                            _imageFile = result;
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
                                        _imageFile = result;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add_a_photo_outlined),
                                  label: const Text('Pilih Gambar'),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _abstractionController,
                decoration: const InputDecoration(labelText: 'Abstraction'),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _catalogNumController,
                decoration: const InputDecoration(labelText: 'Katalog Number'),
              ),
              TextFormField(
                controller: _publicationNumController,
                decoration: const InputDecoration(
                  labelText: 'Publication Number',
                ),
                validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _issnController,
                decoration: const InputDecoration(labelText: 'ISSN'),
              ),
              TextFormField(
                controller: _freqController,
                decoration: const InputDecoration(
                  labelText: 'Frekuensi Terbit',
                ),
                validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _pubLinkController,
                decoration: const InputDecoration(
                  labelText: 'Publication Link',
                ),
                validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  hintText: 'dd/mm/yyyy',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
