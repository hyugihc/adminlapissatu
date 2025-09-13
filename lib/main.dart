import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'loading_screen.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- 1. TAMBAHKAN IMPORT INI


void main() async {
  // 1. Ensure that the Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);

  // 3. Run the app ONCE after initialization is complete
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoadingScreen(),
    );
  }
}
