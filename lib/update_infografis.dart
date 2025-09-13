import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:typed_data';

class UpdateInfografis extends StatefulWidget {
  const UpdateInfografis({super.key});

  @override
  State<UpdateInfografis> createState() => _UpdateInfografisState();
}

class _UpdateInfografisState extends State<UpdateInfografis> {
  List<Map<String, dynamic>> infografisList = [
    {
      'title': 'Infografis Tingkat Pengangguran Terbuka Madiun 2025',
      'image': 'lib/assets/TPTmadiun.jpg',
      'description': 'Ini adalah deskripsi untuk infografis tingkat pengangguran terbuka.',
      'type': 'asset',
    },
    {
      'title': 'Infografis Upah Buruh di Madiun 2025',
      'image': 'lib/assets/upahburuh.jpg',
      'description': 'Ini adalah deskripsi untuk infografis upah buruh.',
      'type': 'asset',
    },
  ];

  void _deleteItem(int index) {
    setState(() {
      infografisList.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Infografis berhasil dihapus.')),
    );
  }

  Future<void> _editItem(int index) async {
    final updatedData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditInfografisPage(initialData: infografisList[index]),
      ),
    );
    if (updatedData != null) {
      setState(() {
        infografisList[index] = updatedData;
      });
    }
  }

  Future<void> _addItem() async {
    final newData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddInfografisPage(),
      ),
    );
    if (newData != null) {
      setState(() {
        infografisList.add(newData);
      });
    }
  }

  void _showImageDialog(BuildContext context, Map<String, dynamic> info) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(12),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Text(info['title']!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: info['type'] == 'asset'
                        ? Image.asset(info['image'], fit: BoxFit.contain, width: double.infinity)
                        : Image.memory(info['image'], fit: BoxFit.contain, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Text(info['description']!, textAlign: TextAlign.justify, style: TextStyle(color: Colors.grey[700])),
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
            onPressed: _addItem,
            tooltip: 'Tambah Infografis Baru',
          ),
        ],
      ),
      body: MasonryGridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemCount: infografisList.length,
        itemBuilder: (context, index) {
          final info = infografisList[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showImageDialog(context, info),
                  child: info['type'] == 'asset'
                      ? Image.asset(info['image'])
                      : Image.memory(info['image']),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
                  child: Text(info['title']!, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), onPressed: () => _editItem(index), tooltip: 'Edit'),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteItem(index), tooltip: 'Hapus'),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class EditInfografisPage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditInfografisPage({super.key, required this.initialData});

  @override
  State<EditInfografisPage> createState() => _EditInfografisPageState();
}

class _EditInfografisPageState extends State<EditInfografisPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  dynamic _currentImage;
  late String _currentImageType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData['title']);
    _descriptionController = TextEditingController(text: widget.initialData['description']);
    _currentImage = widget.initialData['image'];
    _currentImageType = widget.initialData['type'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedData = {
      'title': _titleController.text,
      'image': _currentImage,
      'description': _descriptionController.text,
      'type': _currentImageType,
    };
    Navigator.pop(context, updatedData);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Infografis'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges, tooltip: 'Simpan Perubahan')],
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
                    child: _currentImageType == 'asset'
                        ? Image.asset(_currentImage, height: 200, fit: BoxFit.contain)
                        : Image.memory(_currentImage, height: 200, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_search),
                    label: const Text('Ganti Gambar dari Galeri')
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 5),
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
  Uint8List? _pickedImageBytes;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveNewItem() {
    if (_titleController.text.isNotEmpty && _descriptionController.text.isNotEmpty && _pickedImageBytes != null) {
      final newData = {
        'title': _titleController.text,
        'image': _pickedImageBytes,
        'description': _descriptionController.text,
        'type': 'memory',
      };
      Navigator.pop(context, newData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua field harus diisi!')));
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _pickedImageBytes = result.files.single.bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Infografis Baru'),
        actions: [IconButton(icon: const Icon(Icons.save_outlined), onPressed: _saveNewItem, tooltip: 'Simpan')],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
              child: _pickedImageBytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_pickedImageBytes!, fit: BoxFit.contain))
                  : Center(child: TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Pilih Gambar'))),
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 5),
          ],
        ),
      ),
    );
  }
}