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
// ===== INICIO DE CAMBIOS =====
// 1. IMPORTAMOS LA PÁGINA DE VERIFICACIÓN QUE USAREMOS EN EL WRAPPER
import 'package:flutter_firebase/screens/verificar_email_page.dart';
// ===== FIN DE CAMBIOS =====
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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(), // El punto de entrada sigue siendo el AuthWrapper
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/recuperar_pass': (context) => const RecuperarPassPage(),
      },
    );
  }
}


// ===== INICIO DE CAMBIOS =====
// 2. CREACIÓN DE UN SERVICIO DE BASE DE DATOS
// Esta clase contendrá la lógica para crear el perfil del usuario si no existe.
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> checkAndCreateUserProfile(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      // Si el documento del usuario no existe, lo creamos.
      await docRef.set({
        'uid': user.uid,
        'nombre': user.displayName ?? 'Sin Nombre',
        'email': user.email,
        'rol': 'usuario',
        'creadoEn': FieldValue.serverTimestamp(),
      });
    }
  }
}

// 3. AUTHWRAPPER TOTALMENTE REESTRUCTURADO
// Ahora maneja todos los estados de autenticación y verificación.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Estado de carga mientras se obtiene el estado de autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Si no hay datos de usuario, significa que no ha iniciado sesión
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // Si hay datos, tenemos un usuario
        final user = snapshot.data!;

        // CASO 1: El usuario ha iniciado sesión PERO NO ha verificado su email
        if (!user.emailVerified) {
          return const VerificarEmailPage();
        }

        // CASO 2: El usuario ha iniciado sesión Y SÍ ha verificado su email
        // Usamos un FutureBuilder para asegurarnos de que su perfil exista en Firestore
        // antes de entrar a la app.
        return FutureBuilder<void>(
          future: dbService.checkAndCreateUserProfile(user),
          builder: (context, futureSnapshot) {
            // Mientras se comprueba/crea el perfil, mostramos un indicador de carga
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Una vez que el futuro se completa, el perfil está garantizado.
            // Ahora podemos cargar los datos del usuario y mostrar la app.
            return UserDataLoader(userId: user.uid);
          },
        );
      },
    );
  }
}

// 4. USERDATALOADER SE MANTIENE IGUAL
// Su lógica ahora es más sólida porque solo se llamará cuando el documento
// del usuario ya exista o se acabe de crear.
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
        // Este caso ahora representa un error real, ya que el AuthWrapper
        // debería haber garantizado la creación del documento.
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