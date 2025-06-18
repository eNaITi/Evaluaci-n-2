import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificarEmailPage extends StatefulWidget {
  const VerificarEmailPage({super.key});

  @override
  State<VerificarEmailPage> createState() => _VerificarEmailPageState();
}

class _VerificarEmailPageState extends State<VerificarEmailPage> {
  bool _isEmailVerified = false;
  bool _canResendEmail = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    
    if (!_isEmailVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendVerificationEmail();
      });

      _timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    if (!mounted) return;
    
    await FirebaseAuth.instance.currentUser!.reload();
    
    if (!mounted) return;

    setState(() {
      _isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });
    
    if (_isEmailVerified) {
      _timer?.cancel();
    }
  }

  Future<void> _sendVerificationEmail() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      
      setState(() => _canResendEmail = false);
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) setState(() => _canResendEmail = true);

    } on FirebaseAuthException catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error al enviar correo: ${e.message}'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Un error inesperado ocurrió: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifica tu Correo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.email_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Se ha enviado un enlace de verificación a tu correo electrónico.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                FirebaseAuth.instance.currentUser?.email ?? 'Cargando correo...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _canResendEmail ? _sendVerificationEmail : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.send_outlined),
                label: const Text('Reenviar Correo'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  _timer?.cancel();
                  await FirebaseAuth.instance.signOut();
                  
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
