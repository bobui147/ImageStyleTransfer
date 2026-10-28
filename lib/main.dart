import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_auth_page.dart';
import 'firebase_config.dart';
import 'firebase_messaging_service.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var ready = false;
  String? setupError;
  if (FirebaseConfig.isConfigured) {
    try {
      await Firebase.initializeApp(options: FirebaseConfig.options);
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      }
      ready = true;
    } catch (e) {
      setupError = 'Không khởi tạo được Firebase: $e';
    }
  }
  runApp(LoginApiApp(firebaseReady: ready, setupError: setupError));
}

class LoginApiApp extends StatelessWidget {
  const LoginApiApp({super.key, this.firebaseReady = false, this.setupError});

  final bool firebaseReady;
  final String? setupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đăng nhập API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      home: _AppShell(firebaseReady: firebaseReady, setupError: setupError),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell({required this.firebaseReady, this.setupError});

  final bool firebaseReady;
  final String? setupError;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_selected == 0 ? 'Firebase Profile' : 'Đăng nhập API bonus'),
    ),
    body: IndexedStack(
      index: _selected,
      children: [
        FirebaseAuthGate(
          ready: widget.firebaseReady,
          setupError: widget.setupError,
        ),
        const LoginPage(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selected,
      onDestinationSelected: (index) => setState(() => _selected = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.cloud_outlined),
          label: 'Firebase',
        ),
        NavigationDestination(icon: Icon(Icons.login), label: 'API bonus'),
      ],
    ),
  );
}
