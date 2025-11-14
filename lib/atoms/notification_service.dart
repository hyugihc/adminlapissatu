import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
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
      getTokenAndSaveToFirestore();
      setupMessageListeners();
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> getTokenAndSaveToFirestore() async {
    try {
      final String? token = await _firebaseMessaging.getToken();

      if (token == null) {
        print("Gagal mendapatkan FCM token.");
        return;
      }

      print("FCM Token: $token");
      final CollectionReference tokensCollection = FirebaseFirestore.instance
          .collection('/acc-admin/creddentials_notification/fcms_list');

      final QuerySnapshot querySnapshot = await tokensCollection
          .where('token', isEqualTo: token)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Token belum ada di Firestore. Menambahkan...");
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? user = auth.currentUser;
        String email = '';
        if (user != null) {
          email = user.email as String;
        }
        await tokensCollection.add({
          'email': email,
          'token': token,
          'time_add': FieldValue.serverTimestamp(),
        });

        print("Token berhasil ditambahkan ke Firestore.");
      } else {
        print("Token sudah ada di Firestore.");
      }
    } catch (e) {
      print("Terjadi error saat menyimpan token: $e");
    }
  }

  void setupMessageListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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

        backgroundColor: Colors.lightBlue.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 8.0,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
