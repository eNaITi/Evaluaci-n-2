import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'modelo_usuario.dart'; // Asegúrate de que la ruta a tu modelo de usuario sea correcta

class AgregarEventoPage extends StatefulWidget {
  final AppUser currentUser;
  const AgregarEventoPage({super.key, required this.currentUser});

  @override
  State<AgregarEventoPage> createState() => _AgregarEventoPageState();
}

class _AgregarEventoPageState extends State<AgregarEventoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _organizadorController = TextEditingController();
  final _contactoController = TextEditingController();
  final _precioController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _fechaController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _organizadorController.dispose();
    _contactoController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _guardarEvento() async {
    // Si el formulario no es válido, no hacer nada.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Guardar los datos en Firestore
      await FirebaseFirestore.instance.collection('eventos').add({
        'nombre': _nombreController.text,
        'organizador': _organizadorController.text,
        'contacto': _contactoController.text,
        'precio': _precioController.text,
        'descripcion': _descripcionController.text,
        'ubicacion': _ubicacionController.text,
        'fecha': _fechaController.text,
        'creadoPor': widget.currentUser.uid,
        'estado': 'pendiente',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Mostrar mensaje de éxito y volver a la pantalla anterior
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento enviado para revisión.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el evento: $e')),
        );
      }
    } finally {
      // Asegurarse de que el estado de guardado se reinicie
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Crear Nuevo Evento'),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _campoTexto(_nombreController, 'Nombre del Evento'),
              const SizedBox(height: 12),
              _campoTexto(_organizadorController, '¿Quién organiza?'),
              const SizedBox(height: 12),
              _campoTexto(_contactoController, 'Número de contacto'),
              const SizedBox(height: 12),
              _campoTexto(_precioController, 'Precio (ej: \$5000 o Gratis)'),
              const SizedBox(height: 12),
              _campoTexto(_descripcionController, 'Descripción', maxLines: 4),
              const SizedBox(height: 12),
              _campoTexto(_ubicacionController, 'Ubicación'),
              const SizedBox(height: 12),
              _campoTexto(_fechaController, 'Fecha y Hora'),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.deepPurpleAccent,
                
                ),
                // Deshabilitar el botón mientras se guarda
                onPressed: _isSaving ? null : _guardarEvento,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('Enviar para Revisión', style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget de ayuda para crear los campos de texto
  Widget _campoTexto(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }
}