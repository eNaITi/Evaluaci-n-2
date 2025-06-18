import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecuperarPassPage extends StatefulWidget {
  const RecuperarPassPage({super.key});

  @override
  State<RecuperarPassPage> createState() => _RecuperarPassPageState();
}

class _RecuperarPassPageState extends State<RecuperarPassPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;

    setState(() { _isLoading = true; });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Se ha enviado un enlace para restablecer tu contraseña a tu correo.'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(); // Vuelve a la pantalla de login
    } on FirebaseAuthException catch (e) {
      String message = 'Ocurrió un error. Inténtalo de nuevo.';
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        message = 'No se encontró un usuario con ese correo electrónico.';
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Un error inesperado ocurrió: $e'), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ingresa tu correo electrónico para recibir un enlace de recuperación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => (v == null || !RegExp(r'\S+@\S+\.\S+').hasMatch(v)) ? 'Ingresa un correo válido.' : null,
                  decoration: InputDecoration(
                    labelText: "Correo electrónico",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handlePasswordReset,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Enviar Enlace'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}