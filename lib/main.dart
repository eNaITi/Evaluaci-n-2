import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:flutter_firebase/screens/login_page.dart';
import 'package:flutter_firebase/screens/register_page.dart';
import 'package:flutter_firebase/screens/recuperar_contrasena.dart';
import 'package:flutter_firebase/screens/events_page.dart';
import 'package:flutter_firebase/screens/modelo_usuario.dart';
import 'package:flutter_firebase/screens/tema.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eventos App',
      
      // --- TEMA PRINCIPAL (MODO CLARO) ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      // --- TEMA OSCURO (TAMBIÉN AJUSTADO A MORADO) ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        // 1. Mantenemos la consistencia con el color morado.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        
      ),

      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(),
      
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/recuperar_pass': (context) => const RecuperarPassPage(),
      },
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return UserDataLoader(userId: snapshot.data!.uid);
        }
        return const LoginPage();
      },
    );
  }
}

class UserDataLoader extends StatelessWidget {
  final String userId;
  const UserDataLoader({super.key, required this.userId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          FirebaseAuth.instance.signOut();
          return const LoginPage();
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final appUser = AppUser(
          uid: userId,
          nombre: userData['nombre'] ?? 'Sin Nombre',
          email: userData['email'] ?? 'Sin Email',
          rol: userData['rol'] ?? 'usuario',
        );
        return EventosScreen(currentUser: appUser);
      },
    );
  }
}