import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';


class UpdatePublikasi extends StatefulWidget {
  const UpdatePublikasi({super.key});

  @override
  State<UpdatePublikasi> createState() => _UpdatePublikasiState();
}

class _UpdatePublikasiState extends State<UpdatePublikasi> {
  List<Map<String, dynamic>> publicationList = [
    {
      'title': 'Produk Domestik Regional Bruto Kabupaten Madiun Menurut Pengeluaran 2020–2024',
      'cover': 'lib/assets/TPTmadiun.jpg',
      'release_time': '30 April 2025',
      'abstraction': 'Publikasi ini menyajikan gambaran PDRB yang dirinci menurut Pengeluaran...',
      'catalog_num': '9302021.3519', 'publication_num': '35190.25002', 'issn': '-', 'freq': 'Tahunan', 'pub_link': 'https://madiunkab.bps.go.id/...', 'type': 'asset',
    },
    {
      'title': 'Produk Domestik Regional Bruto Kabupaten Madiun Menurut Lapangan Usaha 2020–2024',
      'cover': 'lib/assets/upahburuh.jpg',
      'release_time': '11 April 2025',
      'abstraction': 'Produk Domestik Regional Bruto (PDRB) merupakan salah satu indikator penting...',
      'catalog_num': '9302021.3519', 'publication_num': '35190.25002', 'issn': '-', 'freq': 'Tahunan', 'pub_link': 'https://madiunkab.bps.go.id/...', 'type': 'asset',
    },
  ];

  void _deleteItem(int index) {
    setState(() {
      publicationList.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publikasi berhasil dihapus.')),
    );
  }

  Future<void> _editItem(int index) async {
    final updatedData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPublikasiPage(initialData: publicationList[index]),
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
      MaterialPageRoute(
        builder: (context) => const AddPublikasiPage(),
      ),
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: publicationList.length,
        itemBuilder: (context, index) {
          final pub = publicationList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: pub['type'] == 'asset'
                        ? Image.asset(pub['cover'], width: 100, height: 140, fit: BoxFit.cover)
                        : Image.memory(pub['cover'], width: 100, height: 140, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pub['release_time'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text(pub['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(pub['abstraction'], style: TextStyle(color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), onPressed: () => _editItem(index)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteItem(index)),
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
  
  dynamic _currentImage;
  late String _currentImageType;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _titleController = TextEditingController(text: data?['title'] ?? '');
    _abstractionController = TextEditingController(text: data?['abstraction'] ?? '');
    _catalogNumController = TextEditingController(text: data?['catalog_num'] ?? '');
    _publicationNumController = TextEditingController(text: data?['publication_num'] ?? '');
    _issnController = TextEditingController(text: data?['issn'] ?? '');
    _freqController = TextEditingController(text: data?['freq'] ?? '');
    _pubLinkController = TextEditingController(text: data?['pub_link'] ?? '');
    
    if (data != null) {
      _currentImage = data['cover'];
      _currentImageType = data['type'];
    } else {
      _currentImageType = 'none';
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
    super.dispose();
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _currentImage = result.files.single.bytes;
        _currentImageType = 'memory';
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate() && _currentImage != null) {
      final data = {
        'title': _titleController.text,
        'cover': _currentImage,
        'abstraction': _abstractionController.text,
        'catalog_num': _catalogNumController.text,
        'publication_num': _publicationNumController.text,
        'issn': _issnController.text,
        'freq': _freqController.text,
        'pub_link': _pubLinkController.text,
        'type': _currentImageType,
        'release_time': 'Baru Saja',
      };
      Navigator.pop(context, data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua field dan pilih gambar cover.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialData != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Publikasi' : 'Tambah Publikasi'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm, tooltip: 'Simpan'),
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
                      child: _currentImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _currentImageType == 'asset'
                                  ? Image.asset(_currentImage, fit: BoxFit.contain)
                                  : Image.memory(_currentImage, fit: BoxFit.contain),
                            )
                          : const Center(child: Text('Tidak ada gambar dipilih')),
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
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null),
              TextFormField(controller: _abstractionController, decoration: const InputDecoration(labelText: 'Abstraction'), maxLines: 5, validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null),
              TextFormField(controller: _catalogNumController, decoration: const InputDecoration(labelText: 'Katalog Number'), validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null),
              TextFormField(controller: _publicationNumController, decoration: const InputDecoration(labelText: 'Publication Number'), validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null),
              TextFormField(controller: _issnController, decoration: const InputDecoration(labelText: 'ISSN')),
              TextFormField(controller: _freqController, decoration: const InputDecoration(labelText: 'Frekuensi Terbit'), validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null),
              TextFormField(controller: _pubLinkController, decoration: const InputDecoration(labelText: 'Publication Link'), validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null),
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