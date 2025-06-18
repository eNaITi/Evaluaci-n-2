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

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;
    setState(() { _isLoading = true; });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final user = credential.user;
      if (user != null) {
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userData.exists) {
          final appUser = AppUser(
            uid: user.uid,
            nombre: userData.data()?['nombre'] ?? 'Sin nombre',
            email: user.email!,
            rol: userData.data()?['rol'] ?? 'usuario',
          );
          
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => EventosScreen(currentUser: appUser),
            ),
          );
        } else {
          await FirebaseAuth.instance.signOut();
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text("Error: No se encontraron los datos de tu perfil.")),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'El correo o la contraseña son incorrectos.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'El correo o la contraseña son incorrectos.';
      }
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Un error inesperado ocurrió: $e'), backgroundColor: Theme.of(context).colorScheme.error));
    }

    if (mounted) setState(() { _isLoading = false; });
  }

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
                  Icon(Icons.lock_open_rounded, size: 80, color: theme.colorScheme.primary),
                  const SizedBox(height: 24),
                  Text("Bienvenido de Vuelta", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Inicia sesión para continuar", style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => (v == null || !RegExp(r'\S+@\S+\.\S+').hasMatch(v)) ? 'Ingresa un correo válido.' : null,
                    decoration: const InputDecoration(labelText: "Correo electrónico", prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña.' : null,
                    decoration: const InputDecoration(labelText: "Contraseña", prefixIcon: Icon(Icons.lock_outline)),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/recuperar_pass'),
                      child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: theme.colorScheme.primary)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _handleLogin,
                      icon: _isLoading ? Container() : const Icon(Icons.login_rounded),
                      label: _isLoading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Iniciar sesión"),
                    ),
                  ),
                  const SizedBox(height: 24),
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