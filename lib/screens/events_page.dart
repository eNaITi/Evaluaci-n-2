import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'modelo_usuario.dart';
import 'detalle_evento_page.dart';
import 'tema.dart';
import 'settings_page.dart';
import 'editar_evento_page.dart';
import 'login_page.dart';
import 'add_evento_page.dart';

// =======================================================================
// WIDGET PRINCIPAL QUE GESTIONA LA NAVEGACIÓN
// =======================================================================
class EventosScreen extends StatefulWidget {
  final AppUser currentUser;
  const EventosScreen({super.key, required this.currentUser});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      EventosPublicosList(currentUser: widget.currentUser),
      GestionEventosScreen(currentUser: widget.currentUser),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Eventos Públicos', widget.currentUser.rol == 'admin' ? 'Pendientes de Revisión' : 'Mis Envíos'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(titles[_selectedIndex], style: TextStyle(color: Colors.white),),
        
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.white,
              tooltip: 'Abrir menú',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: AppDrawer(currentUser: widget.currentUser),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Eventos'),
          BottomNavigationBarItem(
            icon: Icon(widget.currentUser.rol == 'admin' ? Icons.pending_actions : Icons.my_library_books),
            label: widget.currentUser.rol == 'admin' ? 'Pendientes' : 'Mis Envíos',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgregarEventoPage(currentUser: widget.currentUser),
            ),
          );
        },
        tooltip: 'Crear nuevo evento',
        child: const Icon(Icons.add),
      ),
    );
  }
}


class AppDrawer extends StatelessWidget {
  final AppUser currentUser;
  const AppDrawer({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        final headerColor = themeProvider.isDarkMode ? Colors.teal.shade800 : Colors.deepPurple;
        final headerTextColor = themeProvider.isDarkMode ? Colors.white : Colors.white;

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(currentUser.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: headerTextColor)),
                accountEmail: Text(currentUser.email, style: TextStyle(color: headerTextColor.withAlpha(230))),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  child: Text(
                    currentUser.nombre.isNotEmpty ? currentUser.nombre[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 40.0, color: headerColor),
                  ),
                ),
                decoration: BoxDecoration(color: headerColor),
              ),
              ListTile(
                leading: Icon(themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                title: const Text('Modo Oscuro'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.password_outlined),
                title: const Text('Cambiar Contraseña'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await FirebaseAuth.instance.signOut();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class EventosPublicosList extends StatefulWidget {
  final AppUser currentUser;
  const EventosPublicosList({super.key, required this.currentUser});
  @override
  State<EventosPublicosList> createState() => _EventosPublicosListState();
}

class _EventosPublicosListState extends State<EventosPublicosList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance.collection('eventos').where('estado', isEqualTo: 'aprobado').orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> _borrarEvento(String eventoId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: const Text('¿Estás seguro de que quieres eliminar este evento?'),
            actions: [
              TextButton(child: const Text('Cancelar'), onPressed: () => navigator.pop(false)),
              TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Eliminar'), onPressed: () => navigator.pop(true))
            ]));
    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance.collection('eventos').doc(eventoId).delete();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Evento eliminado')));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No hay eventos públicos aún.'));
        
        return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool puedeGestionar = widget.currentUser.rol == 'admin' || widget.currentUser.uid == data['creadoPor'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(data['nombre'] ?? ''),
                  subtitle: Text('Organiza: ${data['organizador'] ?? ''}'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleEventoScreen(evento: data, eventoId: doc.id, currentUser: widget.currentUser)));
                  },
                  trailing: puedeGestionar
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note_outlined, color: Colors.blueGrey),
                              tooltip: 'Editar Evento',
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditarEventoPage(eventoId: doc.id, eventoData: data, currentUser: widget.currentUser))),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Eliminar Evento',
                              onPressed: () => _borrarEvento(doc.id),
                            ),
                          ],
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            });
      },
    );
  }
}

class GestionEventosScreen extends StatelessWidget {
  final AppUser currentUser;
  const GestionEventosScreen({super.key, required this.currentUser});
  @override
  Widget build(BuildContext context) {
    return currentUser.rol == 'admin' ? AdminPendientesList(currentUser: currentUser) : UserSubmissionsList(currentUser: currentUser);
  }
}

class AdminPendientesList extends StatefulWidget {
  final AppUser currentUser;
  const AdminPendientesList({super.key, required this.currentUser});
  @override
  State<AdminPendientesList> createState() => _AdminPendientesListState();
}

class _AdminPendientesListState extends State<AdminPendientesList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance.collection('eventos').where('estado', isEqualTo: 'pendiente').orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> _actualizarEstado(String eventoId, String nuevoEstado) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection('eventos').doc(eventoId).update({'estado': nuevoEstado});
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Evento ${nuevoEstado == 'aprobado' ? 'Aprobado' : 'Rechazado'}')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No hay eventos pendientes de revisión.'));
        return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
          final doc = snapshot.data!.docs[index];
          final data = doc.data() as Map<String, dynamic>;
          return Card(
              color: Colors.amber[100],
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                  title: Text(data['nombre'] ?? ''),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleEventoScreen(evento: data, eventoId: doc.id, currentUser: widget.currentUser))),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(tooltip: 'Aprobar', icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _actualizarEstado(doc.id, 'aprobado')),
                    IconButton(tooltip: 'Rechazar', icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _actualizarEstado(doc.id, 'rechazado'))
                  ])));
        });
      },
    );
  }
}

class UserSubmissionsList extends StatefulWidget {
  final AppUser currentUser;
  const UserSubmissionsList({super.key, required this.currentUser});
  @override
  State<UserSubmissionsList> createState() => _UserSubmissionsListState();
}

class _UserSubmissionsListState extends State<UserSubmissionsList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance.collection('eventos').where('creadoPor', 
    isEqualTo: widget.currentUser.uid).orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> _borrarEvento(String eventoId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmar = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Cancelación'), 
    content: const Text('¿Estás seguro?'), 
    actions: [TextButton(child: const Text('No'), 
    onPressed: () => navigator.pop(false)), 
    TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), 
    child: const Text('Sí, Cancelar'), onPressed: () => navigator.pop(true))]
    ));
    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance.collection('eventos').doc(eventoId).delete();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Envío cancelado')));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error al cancelar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No has enviado eventos.'));
        return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
          final doc = snapshot.data!.docs[index];
          final data = doc.data() as Map<String, dynamic>;
          final estado = data['estado'] ?? 'desconocido';
          Icon estadoIcon;
          Color estadoColor;
          switch (estado) {
            case 'aprobado': estadoIcon = const Icon(Icons.check_circle, color: Colors.green); estadoColor = Colors.green.shade100; break;
            case 'rechazado': estadoIcon = const Icon(Icons.cancel, color: Colors.red); estadoColor = Colors.red.shade100; break;
            default: estadoIcon = const Icon(Icons.pending, color: Colors.orange); estadoColor = Colors.orange.shade100;
          }
          return Card(
              color: estadoColor,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                  leading: estadoIcon,
                  title: Text(data['nombre'] ?? ''),
                  subtitle: Text('Estado: ${estado[0].toUpperCase()}${estado.substring(1)}'),
                  onTap: () => Navigator.push(context, 
                  MaterialPageRoute(builder: (_) => DetalleEventoScreen(
                    evento: data, 
                    eventoId: doc.id, currentUser: widget.currentUser))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined,
                      color: Colors.blueGrey),
                      onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => EditarEventoPage(eventoId: doc.id, eventoData: data,
                      currentUser: widget.currentUser)
                      )
                      )
                      ),
                      if (estado == 'pendiente') IconButton(tooltip: 'Cancelar envío',
                      icon: const Icon(Icons.delete_forever, 
                      color: Colors.grey), onPressed: () => _borrarEvento(doc.id)
                      ),
                    ],
                  )));
        });
      },
    );
  }
}