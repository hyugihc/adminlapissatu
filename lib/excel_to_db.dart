import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

// Enum untuk mengelola status UI dengan lebih rapi
enum UploadState { idle, preview, uploading, success, error }

class ExcelUploaderWidget extends StatefulWidget {
  const ExcelUploaderWidget({super.key});

  @override
  State<ExcelUploaderWidget> createState() => _ExcelUploaderWidgetState();
}

class _ExcelUploaderWidgetState extends State<ExcelUploaderWidget> {
  UploadState _state = UploadState.idle;
  String _statusMessage = 'Silakan pilih file Excel untuk diunggah.';
  int _processedRows = 0;
  int _totalRows = 0;

  // Variabel untuk menyimpan data sementara saat pratinjau
  List<String>? _previewHeaders;
  Map<String, dynamic>? _previewDataRow;
  List<Map<String, dynamic>>? _fullDataToUpload;

  void _resetState() {
    setState(() {
      _state = UploadState.idle;
      _statusMessage = 'Silakan pilih file Excel untuk diunggah.';
      _previewHeaders = null;
      _previewDataRow = null;
      _fullDataToUpload = null;
    });
  }

  Future<void> _pickAndPreviewFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) return;

    setState(() {
      _state = UploadState.uploading;
      _statusMessage = 'Membaca dan memvalidasi file...';
    });

    try {
      final String? filePath = result.files.first.path;

      if (filePath == null) {
        setState(() {
          _state = UploadState.error;
          _statusMessage = 'Gagal mendapatkan lokasi file. Coba lagi.';
        });
        return;
      }

      final file = File(filePath);
      final fileBytes = await file.readAsBytes();

      var excel = Excel.decodeBytes(fileBytes);
      var sheet = excel.tables[excel.tables.keys.first]!;

      // Validasi: Pastikan ada header dan setidaknya satu baris data
      if (sheet.maxRows < 2) {
        setState(() {
          _state = UploadState.error;
          _statusMessage =
              'Error: File Excel harus memiliki header dan setidaknya satu baris data.';
        });
        return;
      }

      // --- KODE YANG HILANG SEBELUMNYA ADA DI SINI ---

      // 1. Ambil header (baris pertama)
      List<String> headers = sheet.rows.first
          .map((cell) => cell?.value?.toString().trim() ?? '')
          .toList();

      // 2. Ambil data baris pertama untuk pratinjau
      Map<String, dynamic> firstDataRow = {};
      var firstRowValues = sheet.rows[1]; // Baris data pertama ada di indeks 1
      for (int j = 0; j < headers.length; j++) {
        if (headers[j].isNotEmpty) {
          firstDataRow[headers[j]] = firstRowValues.length > j
              ? firstRowValues[j]?.value
              : null;
        }
      }

      // 3. Siapkan semua data untuk diunggah nanti jika dikonfirmasi
      List<Map<String, dynamic>> allData = [];
      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        Map<String, dynamic> rowData = {};
        for (int j = 0; j < headers.length; j++) {
          if (headers[j].isNotEmpty) {
            rowData[headers[j]] = row.length > j ? row[j]?.value : null;
          }
        }
        allData.add(rowData);
      }

      // 4. Update UI ke mode pratinjau setelah semua data siap
      setState(() {
        _state = UploadState.preview;
        _previewHeaders = headers.where((h) => h.isNotEmpty).toList();
        _previewDataRow = firstDataRow;
        _fullDataToUpload = allData;
        _totalRows = allData.length;
        _statusMessage = 'Silakan periksa pratinjau data sebelum mengunggah.';
      });
      // --- AKHIR DARI BAGIAN YANG DILENGKAPI ---
    } catch (e) {
      setState(() {
        _state = UploadState.error;
        _statusMessage = 'Gagal memproses file: $e';
      });
    }
  }

  Future<void> _confirmAndUpload() async {
    if (_fullDataToUpload == null || _fullDataToUpload!.isEmpty) return;

    setState(() {
      _state = UploadState.uploading;
      _processedRows = 0;
      _statusMessage = 'Mengunggah data ke Firestore...';
    });

    try {
      // 3. LOAD - Mengirim data setelah konfirmasi
      await _uploadDataInBatches(_fullDataToUpload!);
      setState(() {
        _state = UploadState.success;
        _statusMessage = 'Sukses! $_totalRows baris data berhasil diimpor.';
      });
    } catch (e) {
      setState(() {
        _state = UploadState.error;
        _statusMessage = 'Gagal mengunggah data: $e';
      });
    }
  }

  Future<void> _uploadDataInBatches(List<Map<String, dynamic>> data) async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection(
      'produk_excel',
    ); // Ganti nama koleksi
    const batchSize = 499;
    var batch = firestore.batch();

    for (int i = 0; i < data.length; i++) {
      batch.set(collection.doc(), data[i]);
      if ((i + 1) % batchSize == 0 || i == data.length - 1) {
        await batch.commit();
        if (i != data.length - 1) batch = firestore.batch();
      }
      // Update UI secara berkala agar tidak terasa macet
      if (i % 20 == 0) {
        // Update setiap 20 baris
        setState(() {
          _processedRows = i + 1;
          _statusMessage =
              'Memproses baris $_processedRows dari $_totalRows...';
        });
      }
    }
    setState(() => _processedRows = data.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excel Uploader')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tampilan Awal dan Tombol Pilih File
              if (_state == UploadState.idle ||
                  _state == UploadState.success ||
                  _state == UploadState.error)
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Pilih File Excel'),
                  onPressed: _pickAndPreviewFile,
                ),

              const SizedBox(height: 20),

              // Tampilan Status/Loading
              if (_state == UploadState.uploading)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_statusMessage, textAlign: TextAlign.center),
                    if (_totalRows > 0) Text('$_processedRows / $_totalRows'),
                  ],
                ),

              // Tampilan Pratinjau dan Konfirmasi
              if (_state == UploadState.preview && _previewHeaders != null)
                _buildPreviewWidget(),

              // Pesan Status Akhir
              if (_state != UploadState.preview &&
                  _state != UploadState.uploading)
                Text(_statusMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // Widget khusus untuk menampilkan pratinjau
  Widget _buildPreviewWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _statusMessage,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Menampilkan Nama Kolom
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kolom Terdeteksi:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _previewHeaders!
                      .map((h) => Chip(label: Text(h)))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Menampilkan Pratinjau Data Baris Pertama
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pratinjau Data (Baris Pertama):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DataTable(
                  columns: _previewHeaders!
                      .map((h) => DataColumn(label: Text(h)))
                      .toList(),
                  rows: [
                    DataRow(
                      cells: _previewHeaders!
                          .map(
                            (h) => DataCell(
                              Text(_previewDataRow![h]?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Tombol Aksi (Konfirmasi atau Batal)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _resetState,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _confirmAndUpload,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Konfirmasi & Upload'),
            ),
          ],
        ),
      ],
    );
  }
}
