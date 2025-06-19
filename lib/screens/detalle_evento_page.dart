import 'package:flutter/material.dart';
import 'package:flutter_firebase/screens/editar_evento_page.dart';
import 'package:flutter_firebase/screens/modelo_usuario.dart';

class DetalleEventoScreen extends StatelessWidget {
  // Recibe los datos completos del evento, su ID y el usuario actual.
  final Map<String, dynamic> evento;
  final String eventoId;
  final AppUser currentUser;

  const DetalleEventoScreen({
    super.key,
    required this.evento,
    required this.eventoId,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    // Extraemos los datos del mapa con seguridad.
    final nombre = evento['nombre'] ?? 'Sin nombre';
    final organizador = evento['organizador'] ?? 'No especificado';
    final descripcion = evento['descripcion'] ?? 'No hay descripción disponible.';
    final fecha = evento['fecha'] ?? 'No especificada';
    final contacto = evento['contacto'] ?? 'No especificado';
    final precio = evento['precio'] ?? 'Gratis';
    final ubicacion = evento['ubicacion'] ?? 'No especificada';

    // Lógica de permisos: decide si el botón de editar debe ser visible.
    final bool puedeEditar =
        currentUser.rol == 'admin' || currentUser.uid == evento['creadoPor'];

    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de cabecera decorativa
            Container(
              height: 200,
              width: double.infinity,
              color: Theme.of(context).primaryColor.withAlpha(150),
              child: const Center(
                child: Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 90,
                  shadows: [Shadow(blurRadius: 10.0, color: Colors.black26)],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organizado por: $organizador',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Acerca del Evento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildDetailRow(context, Icons.calendar_today_outlined, 'Fecha', fecha),
                  _buildDetailRow(context, Icons.location_on_outlined, 'Ubicación', ubicacion),
                  _buildDetailRow(context, Icons.phone_outlined, 'Contacto', contacto),
                  _buildDetailRow(context, Icons.sell_outlined, 'Precio', precio),
                ],
              ),
            ),
          ],
        ),
      ),
      // Botón flotante que solo aparece si el usuario tiene permiso.
      floatingActionButton: puedeEditar
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditarEventoPage(
                      eventoId: eventoId,
                      eventoData: evento,
                      currentUser: currentUser, // Pasamos el usuario a la pág. de edición
                    ),
                  ),
                );
              },
              label: const Text('Editar'),
              icon: const Icon(Icons.edit_outlined),
            )
          : null,
    );
  }


  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}