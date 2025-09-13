import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert' show utf8;

class UpdateData extends StatefulWidget {
  const UpdateData({super.key});

  @override
  State<UpdateData> createState() => _UpdateDataState();
}

class _UpdateDataState extends State<UpdateData> {
  final List<Map<String, String>> _dataList = [
    {'title': 'Data Tingkat Pengangguran Terbuka 2025', 'table_data': 'Kolom1,Kolom2\nNilai1,Nilai2'},
    {'title': 'Data PDRB per Kapita Kabupaten Madiun', 'table_data': 'Tahun,PDRB\n2023,100jt\n2024,110jt'},
    {'title': 'Indeks Pembangunan Manusia (IPM) 2025', 'table_data': 'Indikator,Nilai\nAHH,75.2'},
  ];

  void _showFormDialog({Map<String, String>? initialData, int? index}) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return _DataFormDialog(initialData: initialData);
      },
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _dataList[index] = result;
        } else {
          _dataList.add(result);
        }
      });
    }
  }

  void _deleteItem(int index) {
    setState(() {
      _dataList.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item data berhasil dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Data Publik'),
      ),
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
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _showFormDialog(initialData: data, index: index),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteItem(index),
                    tooltip: 'Hapus',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Tambah Data Baru',
      ),
    );
  }
}

class _DataFormDialog extends StatefulWidget {
  final Map<String, String>? initialData;
  const _DataFormDialog({this.initialData});

  @override
  State<_DataFormDialog> createState() => __DataFormDialogState();
}

class __DataFormDialogState extends State<_DataFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  
  String? _pickedFileName;
  String? _pickedFileContent;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData?['title'] ?? '');
    if (widget.initialData != null) {
      _pickedFileContent = widget.initialData?['table_data'];
      _pickedFileName = 'data_lama.csv';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        final file = result.files.first;
        _pickedFileName = file.name;
        _pickedFileContent = utf8.decode(file.bytes!);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_pickedFileContent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap pilih file tabel terlebih dahulu')),
        );
        return;
      }
      final result = {
        'title': _titleController.text,
        'table_data': _pickedFileContent!,
      };
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialData == null ? 'Tambah Data Baru' : 'Edit Data'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Data'),
                validator: (v) => v!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              const Text('Isi Tabel', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _pickedFileName ?? 'Tidak ada file dipilih',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _pickFile,
                      child: const Text('Pilih File'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}