// lib/user_model.dart

class AppUser {
  final String uid;
  final String nombre;
  final String email;
  final String rol;

  AppUser({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
  });
}