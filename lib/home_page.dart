import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'layanan_masuk.dart';
import 'update_homepage.dart';
import 'update_infografis.dart';
import 'update_publikasi.dart';
import 'update_data.dart';
import 'review_user.dart';

import 'atoms/notification_service.dart';

// import 'excel_to_db.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<Map<String, dynamic>> _dashboardStream;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _setupDashboardStream();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        String notificationMessage =
            message.notification!.title ??
            message.notification!.body ??
            "Anda menerima pesan baru!";
        if (mounted) {
          NotificationService().showCustomSnackBar(
            context,
            notificationMessage,
          );
        }
      }
    });
  }

  void _setupDashboardStream() {
    final internStream = _firestore
        .collection('intern-req')
        .where('status', isEqualTo: 'pending')
        .snapshots();
    final consultStream = _firestore
        .collection('consult-req')
        .where('status', isEqualTo: 'pending')
        .snapshots();
    final complainStream = _firestore
        .collection('complain-req')
        .where('status', isEqualTo: 'pending')
        .snapshots();
    final dataStream = _firestore
        .collection('data-req')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    _dashboardStream = CombineLatestStream.combine4(
      internStream,
      consultStream,
      complainStream,
      dataStream,
      (QuerySnapshot s1, QuerySnapshot s2, QuerySnapshot s3, QuerySnapshot s4) {
        final allPendingDocs = <QueryDocumentSnapshot>[];
        allPendingDocs.addAll(s1.docs);
        allPendingDocs.addAll(s2.docs);
        allPendingDocs.addAll(s3.docs);
        allPendingDocs.addAll(s4.docs);

        final int requestCount = allPendingDocs.length;
        String popularService = 'Belum Ada';

        if (requestCount > 0) {
          var frequencyMap = <String, int>{};
          for (var doc in allPendingDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] as String? ?? 'Lainnya';
            frequencyMap[title] = (frequencyMap[title] ?? 0) + 1;
          }
          if (frequencyMap.isNotEmpty) {
            var sortedKeys = frequencyMap.keys.toList(
              growable: false,
            )..sort((k1, k2) => frequencyMap[k2]!.compareTo(frequencyMap[k1]!));
            popularService = sortedKeys.first;
          }
        }

        return {'count': requestCount, 'popular': popularService};
      },
    );
  }

  void _showServiceListView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const LayananPage();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _dashboardStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return DashboardAdmin(
              requestCount: 0,
              mostPopularService: 'Memuat...',
              onLihatDetailPressed: _showServiceListView,
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return DashboardAdmin(
              requestCount: 0,
              mostPopularService: 'Belum Ada',
              onLihatDetailPressed: _showServiceListView,
            );
          }

          final int requestCount = snapshot.data?['count'] ?? 0;
          final String mostPopularService = snapshot.data?['popular'] ?? 'N/A';

          return DashboardAdmin(
            requestCount: requestCount,
            mostPopularService: mostPopularService,
            onLihatDetailPressed: _showServiceListView,
          );
        },
      ),
    );
  }
}

class DashboardAdmin extends StatelessWidget {
  final VoidCallback onLihatDetailPressed;
  final int requestCount;
  final String mostPopularService;

  const DashboardAdmin({
    super.key,
    required this.onLihatDetailPressed,
    required this.requestCount,
    required this.mostPopularService,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                'lib/assets/backgroundd.jpg',
                fit: BoxFit.cover,
                height: screenHeight * 0.35,
                width: double.infinity,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'lib/assets/logo bps.png',
                            height: 50,
                            width: 50,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'BPS Kabupaten Madiun',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 4.0, color: Colors.black54),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "ADMIN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 4.0, color: Colors.black54),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selamat datang di halaman admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          shadows: [
                            Shadow(blurRadius: 2.0, color: Colors.black87),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            transform: Matrix4.translationValues(0.0, -50.0, 0.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SmallStatsCard(
                        count: requestCount,
                        label: 'Layanan Masuk',
                        icon: Icons.inbox_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SmallStatsCard(
                        label: 'Layanan Terpopuler',
                        value: mostPopularService,
                        icon: Icons.star_border_outlined,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onLihatDetailPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Lihat Semua Layanan'),
                ),
                const SizedBox(height: 20),
                // _MenuButton(
                //   icon: Icons.dashboard_outlined,
                //   label: 'Dashboard Performance',
                //   onTap: () {},
                // ),
                _MenuButton(
                  icon: Icons.update,
                  label: 'Update Data',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UpdateData()),
                    );
                  },
                ),
                _MenuButton(
                  icon: Icons.home_work_outlined,
                  label: 'Update Homepage',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UpdateHomepage(),
                      ),
                    );
                  },
                ),
                _MenuButton(
                  icon: Icons.add_chart_outlined,
                  label: 'Update Infografis',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UpdateInfografis(),
                      ),
                    );
                  },
                ),
                _MenuButton(
                  icon: Icons.book_online,
                  label: 'Update Publikasi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UpdatePublikasi(),
                      ),
                    );
                  },
                ),
                _MenuButton(
                  icon: Icons.star_rate_outlined,
                  label: 'Review Pengguna',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReviewUser(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStatsCard extends StatelessWidget {
  final int? count;
  final String label;
  final String? value;
  final IconData icon;
  final Color color;

  const _SmallStatsCard({
    this.count,
    required this.label,
    this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (count != null)
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (value != null)
                  Text(
                    value ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MenuButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.black54),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
