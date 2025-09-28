import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Minta izin dari pengguna (iOS & Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      getToken();
      setupMessageListeners();
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> getToken() async {
    final String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
  }

  void setupMessageListeners() {
    // 1. Handler untuk notifikasi saat aplikasi di FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Jika Anda ingin menampilkan notifikasi custom saat di foreground,
        // Anda bisa menggunakan package seperti flutter_local_notifications.
      }
    });

    // 2. Handler saat pengguna MENGETUK notifikasi saat aplikasi di BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
    });

    // 3. Handler untuk notifikasi yang membuka aplikasi dari kondisi TERMINATED
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        print('App opened from terminated state by a notification!');
        // Navigasi ke halaman tertentu
      }
    });
  }

  void showCustomSnackBar(BuildContext context, String message) {
    // Hapus SnackBar yang mungkin sedang aktif
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Buat dan tampilkan SnackBar baru
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // 1. KONTEN UTAMA (IKON + TEKS)
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // 2. WARNA LATAR BELAKANG
        backgroundColor: Colors.lightBlue.shade400,

        // 3. PERILAKU (Mengambang di atas konten)
        behavior: SnackBarBehavior.floating,

        // 4. BENTUK DAN SUDUT
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),

        // 5. MARGIN (Hanya berfungsi jika behavior-nya floating)
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),

        // 6. EFEK BAYANGAN (ELEVATION)
        elevation: 8.0,

        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            // Aksi saat tombol ditekan (misal: tutup snackbar)
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
