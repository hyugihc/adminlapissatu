import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateHomepage extends StatefulWidget {
  const UpdateHomepage({super.key});

  @override
  State<UpdateHomepage> createState() => _UpdateHomepageState();
}

class _UpdateHomepageState extends State<UpdateHomepage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showStatsDialog({DocumentSnapshot? existingDoc}) {
    showDialog(
      context: context,
      builder: (context) {
        return _AddEditStatsDialog(
          firestore: _firestore,
          existingDoc: existingDoc,
        );
      },
    );
  }

  Future<void> _deleteStat(DocumentSnapshot doc) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Anda yakin ingin menghapus "${doc['label']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Statistik Homepage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showStatsDialog(),
            tooltip: 'Tambah Statistik Baru',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('home-display').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi error saat memuat data.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada statistik.\nTekan tombol + untuk menambahkan.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final statsDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: statsDocs.length,
            itemBuilder: (context, index) {
              final doc = statsDocs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    doc['value'],
                    style: const TextStyle(
                      color: Color(0xFF0D47A1),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    doc['label'],
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showStatsDialog(existingDoc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteStat(doc),
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

class _AddEditStatsDialog extends StatefulWidget {
  final FirebaseFirestore firestore;
  final DocumentSnapshot? existingDoc;

  const _AddEditStatsDialog({required this.firestore, this.existingDoc});

  @override
  State<_AddEditStatsDialog> createState() => _AddEditStatsDialogState();
}

class _AddEditStatsDialogState extends State<_AddEditStatsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _valueController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.existingDoc?.data() as Map<String, dynamic>?;
    _labelController = TextEditingController(text: data?['label'] ?? '');

    String initialValue = data?['value'] ?? '';
    _valueController = TextEditingController(text: initialValue);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String formattedValue = _valueController.text;

      final data = {'label': _labelController.text, 'value': formattedValue};

      if (widget.existingDoc == null) {
        await widget.firestore.collection('home-display').add(data);
      } else {
        await widget.existingDoc!.reference.update(data);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // print('Gagal menyimpan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal menyimpan data. Pastikan nilai adalah angka yang valid.',
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingDoc == null ? 'Tambah Statistik' : 'Edit Statistik',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Label'),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Label tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Nilai',
                  hintText: 'Contoh: 41.6%',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nilai tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: _isLoading
          ? [const Center(child: CircularProgressIndicator())]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
            ],
    );
  }
}
