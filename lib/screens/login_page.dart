// Importación de librerías necesarias
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'events_page.dart'; 
import 'modelo_usuario.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función que maneja el inicio de sesión
  Future<void> _handleLogin() async {
    // Validación de formulario
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;

    setState(() { _isLoading = true; });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Intenta iniciar sesión con Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final user = credential.user;

      if (user != null) {
        // Obtiene los datos del usuario desde Firestore
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userData.exists) {
          // Crea una instancia del modelo de usuario
          final appUser = AppUser(
            uid: user.uid,
            nombre: userData.data()?['nombre'] ?? 'Sin nombre',
            email: user.email!,
            rol: userData.data()?['rol'] ?? 'usuario',
          );

          // Navega a la pantalla principal pasándole el usuario
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => EventosScreen(currentUser: appUser),
            ),
          );
        } else {
          // Si el documento no existe, cierra sesión por seguridad
          await FirebaseAuth.instance.signOut();
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text("Error: No se encontraron los datos de tu perfil.")),
          );
        }
      }

    // Manejo de errores de Firebase Auth
    } on FirebaseAuthException catch (e) {
      String message = 'El correo o la contraseña son incorrectos.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'El correo o la contraseña son incorrectos.';
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

    // Manejo de errores inesperados
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Un error inesperado ocurrió: $e'), 
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    // Al finalizar, desactiva el indicador de carga si el widget sigue montado
    if (mounted) setState(() { _isLoading = false; });
  }

  // Construcción de la interfaz del login
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de candado
                  Icon(Icons.lock_open_rounded, size: 80, color: theme.colorScheme.primary),
                  const SizedBox(height: 24),

                  // Título y subtítulo
                  Text("Bienvenido de Vuelta", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Inicia sesión para continuar", style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),

                  const SizedBox(height: 40),

                  // Campo para el correo electrónico
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => (v == null || !RegExp(r'\S+@\S+\.\S+').hasMatch(v)) 
                      ? 'Ingresa un correo válido.' 
                      : null,
                    decoration: const InputDecoration(
                      labelText: "Correo electrónico", 
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo para la contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => (v == null || v.isEmpty) 
                      ? 'Ingresa tu contraseña.' 
                      : null,
                    decoration: const InputDecoration(
                      labelText: "Contraseña", 
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),

                  // Enlace para recuperar contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/recuperar_pass'),
                      child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: theme.colorScheme.primary)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón para iniciar sesión
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _handleLogin,
                      icon: _isLoading 
                        ? Container() 
                        : const Icon(Icons.login_rounded),
                      label: _isLoading 
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Text("Iniciar sesión"),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Enlace a la pantalla de registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿No tienes una cuenta?"),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: Text("Regístrate aquí", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
