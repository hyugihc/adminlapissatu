import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class UpdatePublikasi extends StatefulWidget {
  const UpdatePublikasi({super.key});

  @override
  State<UpdatePublikasi> createState() => _UpdatePublikasiState();
}

class _UpdatePublikasiState extends State<UpdatePublikasi> {
  List<Map<String, dynamic>> publicationList = [];

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
          // Ubah Timestamp menjadi objek DateTime
          DateTime date = (data['release_time'] as Timestamp).toDate();
          formattedDate = DateFormat('d MMMM yyyy').format(date);
        }

        return {
          'id': doc.id,
          'title': data['title']?.toString() ?? 'Tanpa Judul',
          'cover': data['cover']?.toString() ?? '',
          'release_time': formattedDate,
          'abstraction':
              data['abstraction']?.toString() ?? 'Tidak ada deskripsi.',
          'catalog_num': data['katalog_num']?.toString() ?? '-',
          'publication_num': data['publication_num']?.toString() ?? '-',
          'issn': data['issn']?.toString() ?? '-',
          'freq': data['freq']?.toString() ?? '-',
          'pub_link': data['pub_link']?.toString() ?? '-',
        };
      }).toList();
      return publications;
    } catch (e) {
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
    final updatedData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            // Scaffold(),
            EditPublikasiPage(initialData: publicationList[index]),
      ),
    );
    if (updatedData != null) {
      setState(() {
        publicationList[index] = updatedData;
      });
    }
  }

  Future<void> _addItem() async {
    final newData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => EditPublikasiPage()),
    );
    if (newData != null) {
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
                          imageUrl: pub['cover'],
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
                              pub['release_time'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pub['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pub['abstraction'],
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
  late String _currentImage;

  File? _imageFile;
  final format = DateFormat('d MMMM yyyy');

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
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

    if (data != null) {
      _currentImage = data['cover'];
    } else {
      _currentImage = '';
    }
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

  Future<String?> _uploadImage(File imageFile) async {
    const String cloudName = "dxkxrbteg";
    const String uploadPreset = "LapisSatu-Publikasi";

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        // Ambil URL gambar yang aman (https)
        final imageUrl = jsonData['secure_url'];
        print('Upload berhasil! URL: $imageUrl');
        return imageUrl;
      } else {
        print('Error: ${response.statusCode}');
        print(await response.stream.bytesToString());
        return null;
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
      return null;
    }
  }

  void _saveForm() async {
    String? idTemp;
    if (_imageFile != null) {
      _currentImage = await _uploadImage(_imageFile!) as String;
    }

    if (_formKey.currentState!.validate() && _currentImage.isNotEmpty) {
      Timestamp tgl = Timestamp.fromDate(format.parse(_dateController.text));
      final dataFirestore = {
        'title': _titleController.text,
        'cover': _currentImage,
        'abstraction': _abstractionController.text,
        'catalog_num': _catalogNumController.text,
        'publication_num': _publicationNumController.text,
        'issn': _issnController.text,
        'freq': _freqController.text,
        'pub_link': _pubLinkController.text,
        'release_time': tgl,
      };

      if (widget.initialData != null) {
        try {
          idTemp = widget.initialData?['id'];
          DocumentReference documentReference = FirebaseFirestore.instance
              .collection('publikasi')
              .doc(idTemp!);
          await documentReference.update(dataFirestore);
        } catch (e) {
          rethrow;
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

      final Map<String, String> data = {
        'id': idTemp,
        'title': _titleController.text,
        'cover': _currentImage,
        'abstraction': _abstractionController.text,
        'catalog_num': _catalogNumController.text,
        'publication_num': _publicationNumController.text,
        'issn': _issnController.text,
        'freq': _freqController.text,
        'pub_link': _pubLinkController.text,
        'release_time': _dateController.text,
      };
      if (mounted) {
        Navigator.pop(context, data);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap lengkapi semua field dan pilih gambar cover.'),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
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
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _currentImage.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _imageFile != null
                                  ? Image.file(_imageFile!, fit: BoxFit.contain)
                                  : CachedNetworkImage(
                                      imageUrl: _currentImage,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                      fit: BoxFit.contain,
                                    ),
                            )
                          : _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.contain)
                          : const Center(
                              child: Text('Belum ada gambar dipilih'),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_search),
                      label: const Text('Ganti Gambar Cover'),
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
                validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
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

class AddPublikasiPage extends StatelessWidget {
  const AddPublikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditPublikasiPage();
  }
}
