import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

class LayananPage extends StatefulWidget {
  const LayananPage({super.key});

  @override
  State<LayananPage> createState() => _LayananPageState();
}

class _LayananPageState extends State<LayananPage> {
  Map<String, dynamic>? _selectedRequest;
  // Mengganti Future menjadi Stream untuk data real-time
  late Stream<List<Map<String, dynamic>>> _requestsStream;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _setupRequestsStream();
  }

  /// Menyiapkan dan menggabungkan stream dari semua koleksi layanan
  void _setupRequestsStream() {
    final internStream = _firestore.collection('intern-req').snapshots();
    final consultStream = _firestore.collection('consult-req').snapshots();
    final complainStream = _firestore.collection('complain-req').snapshots();
    final dataStream = _firestore.collection('data-req').snapshots();

    _requestsStream = CombineLatestStream.combine4(
      internStream,
      consultStream,
      complainStream,
      dataStream,
      (QuerySnapshot s1, QuerySnapshot s2, QuerySnapshot s3, QuerySnapshot s4) {
        final allDocs = <QueryDocumentSnapshot>[];
        allDocs.addAll(s1.docs);
        allDocs.addAll(s2.docs);
        allDocs.addAll(s3.docs);
        allDocs.addAll(s4.docs);

        List<Map<String, dynamic>> requests = allDocs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
            DateTime dt = (data['timestamp'] as Timestamp).toDate();
            data['formatted_date'] = DateFormat(
              'dd MMM yyyy, HH:mm',
            ).format(dt);
          } else {
            data['formatted_date'] = '';
          }
          return data;
        }).toList();

        requests.sort((a, b) {
          Timestamp tsA =
              a['timestamp'] ?? Timestamp.fromMillisecondsSinceEpoch(0);
          Timestamp tsB =
              b['timestamp'] ?? Timestamp.fromMillisecondsSinceEpoch(0);
          return tsB.compareTo(tsA);
        });
        return requests;
      },
    );
  }

  /// Fungsi untuk mengubah status request menjadi 'selesai'
  Future<void> _completeRequest(Map<String, dynamic> requestData) async {
    String collectionName;
    final String title = requestData['title'] ?? '';
    if (title == 'Pengajuan Magang') {
      collectionName = 'intern-req';
    } else if (title == 'Konsultasi') {
      collectionName = 'consult-req';
    } else if (title == 'Pengaduan') {
      collectionName = 'complain-req';
    } else if (title == 'Permintaan Data') {
      collectionName = 'data-req';
    } else {
      print('Error: Tipe layanan tidak dikenal: "$title"');
      return;
    }
    try {
      await _firestore.collection(collectionName).doc(requestData['id']).update(
        {'status': 'selesai'},
      );
      // Tidak perlu setState karena StreamBuilder akan update otomatis
    } catch (e) {
      print("Error updating data: $e");
    }
  }

  void _showRequestDetail(Map<String, dynamic> requestData) {
    setState(() {
      _selectedRequest = requestData;
    });
  }

  void _hideRequestDetail() {
    setState(() {
      _selectedRequest = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mengganti FutureBuilder menjadi StreamBuilder
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada layanan masuk.'));
          }

          final allRequests = snapshot.data!;
          final pendingRequests = allRequests
              .where((req) => req['status'] == 'pending')
              .toList();
          final completedRequests = allRequests
              .where((req) => req['status'] == 'selesai')
              .toList();

          return Stack(
            children: [
              PermintaanMasuk(
                pendingRequests: pendingRequests,
                completedRequests: completedRequests,
                onShowDetail: _showRequestDetail,
                onBackPressed: () => Navigator.pop(context, true),
              ),
              if (_selectedRequest != null)
                DetailPermintaanLayanan(
                  requestData: _selectedRequest!,
                  onBackPressed: _hideRequestDetail,
                  onCompleted: () {
                    _completeRequest(_selectedRequest!);
                    _hideRequestDetail();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

//==================================================================
// KELAS-KELAS UI (TAMPILAN)
//==================================================================

class PermintaanMasuk extends StatelessWidget {
  // ... (Tidak ada perubahan di sini)
  final Function(Map<String, dynamic>) onShowDetail;
  final VoidCallback onBackPressed;
  final List<Map<String, dynamic>> pendingRequests;
  final List<Map<String, dynamic>> completedRequests;

  const PermintaanMasuk({
    super.key,
    required this.onShowDetail,
    required this.onBackPressed,
    required this.pendingRequests,
    required this.completedRequests,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan Masuk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Text(
                  pendingRequests.length.toString(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Permintaan Layanan yang belum selesai'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final item = pendingRequests[index];
              return _CardPermintaanLayanan(
                item: item,
                onDetailPressed: () => onShowDetail(item),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        completedRequests.length.toString(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text("Layanan yang sudah selesai")),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LayananSelesaiPage(
                          completedRequests: completedRequests,
                        ),
                      ),
                    );
                  },
                  child: const Text('Lihat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LayananSelesaiPage extends StatelessWidget {
  // ... (Tidak ada perubahan di sini)
  final List<Map<String, dynamic>> completedRequests;
  const LayananSelesaiPage({super.key, required this.completedRequests});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Layanan Selesai')),
      body: completedRequests.isEmpty
          ? const Center(child: Text('Belum ada layanan yang selesai.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: completedRequests.length,
              itemBuilder: (context, index) {
                final item = completedRequests[index];
                return _CardPermintaanLayanan(
                  item: item,
                  onDetailPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPermintaanLayanan(
                          requestData: item,
                          onBackPressed: () => Navigator.pop(context),
                          isCompletedView: true,
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

class _CardPermintaanLayanan extends StatelessWidget {
  // ... (Tidak ada perubahan di sini)
  final Map<String, dynamic> item;
  final VoidCallback onDetailPressed;
  const _CardPermintaanLayanan({
    required this.item,
    required this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String title = item['title'] ?? 'Tanpa Judul';
    final String name = item['name'] ?? 'Tanpa Nama';
    final String displayDate = item['formatted_date'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  displayDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(color: Colors.black54)),
                TextButton(
                  onPressed: onDetailPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  child: const Text('Detail'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPermintaanLayanan extends StatelessWidget {
  // ... (Tidak ada perubahan di sini)
  final Map<String, dynamic> requestData;
  final VoidCallback onBackPressed;
  final VoidCallback? onCompleted;
  final bool isCompletedView;

  const DetailPermintaanLayanan({
    super.key,
    required this.requestData,
    required this.onBackPressed,
    this.onCompleted,
    this.isCompletedView = false,
  });

  void openEmail({
    required BuildContext context,
    required String toEmail,
    String? subject,
    String? body,
  }) async {
    // Membuat map untuk query parameters
    final Map<String, String> queryParameters = {
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
    };

    // Membuat URI dengan skema mailto
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: toEmail,
      query: queryParameters.isNotEmpty
          ? Uri.encodeQueryComponent(
              queryParameters.entries
                  .map((e) => '${e.key}=${e.value}')
                  .join('&'),
            )
          : null,
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat menemukan aplikasi email.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  void openWhatsApp({
    required BuildContext context,
    required String phoneNumber,
    String? message,
  }) async {
    String formattedPhoneNumber = formatNomorWhatsapp(phoneNumber);
    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$formattedPhoneNumber?text=${Uri.encodeComponent(message ?? '')}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    }
  }

  String formatNomorWhatsapp(String nomor) {
    String nomorBersih = nomor.replaceAll(RegExp(r'\D'), '');
    if (nomorBersih.startsWith('0')) {
      return '62${nomorBersih.substring(1)}';
    }
    return nomorBersih;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(requestData['title'] ?? 'Detail Layanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildDetailContent(requestData),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hubungi Melalui',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    openEmail(context: context, toEmail: requestData['email']);
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[100],
                    foregroundColor: Colors.black87,
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    openWhatsApp(
                      context: context,
                      phoneNumber: requestData['phone_num'],
                      message: 'Layanan Sudah Diproses. Terimakasih.',
                    );
                  },
                  icon: const Icon(Icons.wechat),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[100],
                    foregroundColor: Colors.black87,
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            if (!isCompletedView)
              ElevatedButton(
                onPressed: onCompleted,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Sudah Selesai'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(Map<String, dynamic> data) {
    switch (data['title']) {
      case 'Permintaan Data':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Nama Lengkap', data['name'] ?? '-'),
            _buildDetailRow('Nama Instansi', data['instansi'] ?? '-'),
            _buildDetailRow('No WA Aktif', data['phone_num'] ?? '-'),
            _buildDetailRow('Email Aktif', data['email'] ?? '-'),
            _buildDetailRow('Data yang Diminta', data['data_req'] ?? '-'),
            _BuildDetailFileRow(
              label: 'Surat Permintaan Data',
              filePath: data['path_file'] ?? '',
            ),
          ],
        );

      case 'Konsultasi':
        String scheduledDate = '-';
        final dynamic consultDate = data['date'];
        if (consultDate != null && consultDate is Timestamp) {
          DateTime dt = consultDate.toDate();
          scheduledDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dt);
        } else if (consultDate is String) {
          scheduledDate = consultDate;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Nama Lengkap', data['name'] ?? '-'),
            _buildDetailRow('Asal Instansi', data['instansi'] ?? '-'),
            _buildDetailRow('No WA Aktif', data['phone_num'] ?? '-'),
            _buildDetailRow('Email Aktif', data['email'] ?? '-'),
            _buildDetailRow('Topik Konsultasi', data['topik'] ?? '-'),
            _buildDetailRow('Jadwal Konsultasi', scheduledDate),
          ],
        );

      case 'Pengaduan':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Jenis Pengaduan', data['complain_type'] ?? '-'),
            _buildDetailRow('Nama Lengkap', data['name'] ?? '-'),
            _buildDetailRow('No WA Aktif', data['phone_num'] ?? '-'),
            _buildDetailRow('Email Aktif', data['email'] ?? '-'),
            _buildDetailRow('Pengaduan', data['complain_text'] ?? '-'),
          ],
        );

      case 'Pengajuan Magang':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Nama Lengkap', data['name'] ?? '-'),
            _buildDetailRow(
              'NIK/Nomor Kartu Pelajar',
              data['identity_num'] ?? '-',
            ),
            _buildDetailRow('No WA Aktif', data['phone_num'] ?? '-'),
            _buildDetailRow('Email Aktif', data['email'] ?? '-'),
            _buildDetailRow('Keperluan', data['keperluan'] ?? '-'),
          ],
        );

      default:
        return Text('Tidak ada detail untuk layanan "${data['title']}"');
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

//==================================================================
// WIDGET BARU UNTUK MENANGANI FILE
//==================================================================

class _BuildDetailFileRow extends StatefulWidget {
  final String label;
  final String filePath;

  const _BuildDetailFileRow({required this.label, required this.filePath});

  @override
  State<_BuildDetailFileRow> createState() => __BuildDetailFileRowState();
}

class __BuildDetailFileRowState extends State<_BuildDetailFileRow> {
  String? _downloadURL;
  String _fileName = 'Membuka file...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getFileData();
  }

  Future<void> _getFileData() async {
    if (widget.filePath.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.filePath);
      final fileName = ref.name;

      setState(() {
        _downloadURL = widget.filePath;
        _fileName = fileName;
        _isLoading = false;
      });
    } catch (e) {
      print("Gagal mendapatkan data file: $e");
      setState(() {
        _fileName = 'File tidak ditemukan';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchURL() async {
    if (_downloadURL != null) {
      final uri = Uri.parse(_downloadURL!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak bisa membuka file: $_fileName')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (widget.filePath.isEmpty)
            const Text(
              'Tidak ada file dilampirkan.',
              style: TextStyle(fontStyle: FontStyle.italic),
            )
          else if (_isLoading)
            const Center(child: LinearProgressIndicator())
          else
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.blue),
              title: Text(
                'File Terlampir',
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
              subtitle: const Text('Klik untuk membuka'),
              onTap: _downloadURL != null ? _launchURL : null,
              contentPadding: EdgeInsets.zero,
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}
