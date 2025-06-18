import 'package:flutter/material.dart';

// 1. Creamos un 'ChangeNotifier'. Es una clase simple que puede notificar a los oyentes sobre los cambios.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    // 2. Esta es la función clave. Notifica a todos los widgets que están escuchando
    //    que el estado ha cambiado y que deben reconstruirse.
    notifyListeners();
  }
}