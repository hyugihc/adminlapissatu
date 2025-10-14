import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:admin_lapissatu/home_page.dart';
import 'package:admin_lapissatu/auth_page.dart';
import 'package:admin_lapissatu/atoms/notification_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        print(snapshot.data);
        if (snapshot.hasData) {
          NotificationService().initNotifications();
          return const HomePage();
        } else {
          return const LoginPage(); // <-- Ini akan menampilkan halaman login
        }
      },
    );
  }
}
