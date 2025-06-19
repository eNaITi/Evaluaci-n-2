import 'verificar_email_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Página de registro como un widget con estado
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Limpia los controladores al destruir el widget
  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función para manejar el registro
  Future<void> _handleRegister() async {
    // Verifica que el formulario sea válido
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Evita múltiples envíos si ya está cargando
    if (_isLoading) return;

    // Activa el indicador de carga
    setState(() { _isLoading = true; });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Intenta crear un nuevo usuario con email y contraseña
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = credential.user;

      if (user != null) {
        // Actualiza el nombre de usuario y guarda datos en Firestore
        await Future.wait([
          user.updateDisplayName(_nombreController.text.trim()),
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'nombre': _nombreController.text.trim(),
            'email': _emailController.text.trim(),
            'rol': 'usuario',
            'creadoEn': FieldValue.serverTimestamp(),
          })
        ]);

        // Redirige a la página de verificación de correo si el widget sigue montado
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const VerificarEmailPage()),
          );
        }
      }

    // Manejo de errores específicos de Firebase
    } on FirebaseAuthException catch (e) {
      String message = 'Ocurrió un error durante el registro.';
      if (e.code == 'weak-password') {
        message = 'La contraseña es muy débil (mínimo 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        message = 'Ya existe una cuenta con este correo electrónico.';
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } catch (e) {
      // Manejo de cualquier otro error
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Un error inesperado ocurrió: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }

    // Desactiva el indicador de carga si aún está montado
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono representativo de registro
                  Icon(Icons.person_add_alt_1_rounded, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 24),
                  
                  // Campo: Nombre
                  TextFormField(
                    controller: _nombreController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre.' : null,
                    decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo: Correo electrónico
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => (v == null || !RegExp(r'\S+@\S+\.\S+').hasMatch(v)) ? 'Ingresa un correo válido.' : null,
                    decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo: Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => (v == null || v.length < 6) ? 'La contraseña debe tener al menos 6 caracteres.' : null,
                    decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón para crear la cuenta
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _handleRegister,
                      icon: _isLoading
                        ? Container()
                        : const Icon(Icons.person_add),
                      label: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Crear Cuenta"),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón para volver al inicio de sesión
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "¿Ya tienes una cuenta? Iniciar sesión",
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
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
