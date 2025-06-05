import 'package:flutter/material.dart';
import 'package:flutter_firebase/screens/login_page.dart';
import 'package:flutter_firebase/screens/register_page.dart';
import 'package:flutter_firebase/screens/feed_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  runApp(const AppInit());
}

class AppInit extends StatelessWidget {
  const AppInit({super.key});

  Future<FirebaseApp> _initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      return Firebase.app(); // Ya está inicializado
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        } else if (snapshot.hasError) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: Text('Error al iniciar Firebase'))),
          );
        } else {
          return const MyApp(); // Solo corre MyApp si Firebase está listo
        }
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/feed': (context) => const FeedPage(),
      },
    );
  }
}
