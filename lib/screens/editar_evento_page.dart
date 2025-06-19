// Importación de paquetes necesarios
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'tema.dart';
import 'modelo_usuario.dart';

// Página que permite editar los detalles de un evento
class EditarEventoPage extends StatefulWidget {
  final String eventoId;
  final Map<String, dynamic> eventoData;
  final AppUser currentUser;

  const EditarEventoPage({
    super.key,
    required this.eventoId,
    required this.eventoData,
    required this.currentUser,
  });

  @override
  State<EditarEventoPage> createState() => _EditarEventoPageState();
}

class _EditarEventoPageState extends State<EditarEventoPage> {
  final _formKey = GlobalKey<FormState>(); 
  late Map<String, TextEditingController> _controllers;
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    // Inicializa los controladores con los datos actuales del evento
    _controllers = {
      'nombre': TextEditingController(text: widget.eventoData['nombre']),
      'organizador': TextEditingController(text: widget.eventoData['organizador']),
      'contacto': TextEditingController(text: widget.eventoData['contacto']),
      'precio': TextEditingController(text: widget.eventoData['precio']),
      'descripcion': TextEditingController(text: widget.eventoData['descripcion']),
      'ubicacion': TextEditingController(text: widget.eventoData['ubicacion']),
      'fecha': TextEditingController(text: widget.eventoData['fecha']),
    };
  }

  @override
  void dispose() {
    // Libera los recursos de los controladores cuando se destruye el widget
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Maneja la actualización del evento en Firestore
  Future<void> _handleUpdate() async {
    // Validación del formulario
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Determina el nuevo estado del evento según el rol del usuario
    final String nuevoEstado = (widget.currentUser.rol == 'admin' && widget.eventoData['estado'] == 'aprobado')
        ? 'aprobado'
        : 'pendiente';

    try {
      // Actualiza los datos del evento en Firestore
      await FirebaseFirestore.instance.collection('eventos').doc(widget.eventoId).update({
        'nombre': _controllers['nombre']!.text,
        'organizador': _controllers['organizador']!.text,
        'contacto': _controllers['contacto']!.text,
        'precio': _controllers['precio']!.text,
        'descripcion': _controllers['descripcion']!.text,
        'ubicacion': _controllers['ubicacion']!.text,
        'fecha': _controllers['fecha']!.text,
        'estado': nuevoEstado,
      });

      if (!mounted) return;

      // Muestra mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nuevoEstado == 'pendiente'
              ? 'Evento actualizado y enviado a revisión.'
              : 'Evento actualizado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Cierra la pantalla de edición

    } catch (e) {
      // Muestra mensaje de error si la actualización falla
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) setState(() => _isLoading = false); // Finaliza estado de carga
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Editar Evento'),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campos del formulario
              _campoTexto(context, _controllers['nombre']!, 'Nombre Evento'),
              const SizedBox(height: 16),
              _campoTexto(context, _controllers['organizador']!, '¿Quién organiza?'),
              const SizedBox(height: 16),
              _campoTexto(context, _controllers['contacto']!, 'Número de contacto'),
              const SizedBox(height: 16),
              _campoTexto(context, _controllers['precio']!, 'Precio'),
              const SizedBox(height: 16),
              _campoTexto(context, _controllers['descripcion']!, 'Descripción'),
              const SizedBox(height: 16),
              _campoTexto(context, _controllers['ubicacion']!, 'Ubicación'),
              const SizedBox(height: 16),
              _campoTexto(context, _controllers['fecha']!, 'Fecha'),
              const SizedBox(height: 32),

              // Botón para actualizar evento
              FilledButton(
                onPressed: _isLoading ? null : _handleUpdate,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Actualizar Evento', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget reutilizable para los campos de texto
  Widget _campoTexto(BuildContext context, TextEditingController controller, String hint) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return TextFormField(
      controller: controller,
      validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
      decoration: InputDecoration(
        labelText: hint,
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[250],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
