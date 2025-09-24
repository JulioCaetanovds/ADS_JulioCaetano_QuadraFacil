// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Cores Base do Projeto
  static const Color primaryColor =
      Color(0xFF2E7D32); // Um verde mais escuro e elegante
  static const Color accentColor =
      Color(0xFF4CAF50); // Um verde mais vibrante para destaques
  static const Color textColor =
      Color(0xFF1B1B1B); // Preto não tão intenso para conforto visual
  static const Color backgroundColor = Color(0xFFFFFFFF); // Fundo branco
  static const Color hintColor = Colors.grey;

  // Nosso Tema Principal
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,

      // Esquema de cores
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        onPrimary: Colors.white, // Cor do texto sobre a cor primária
        onSecondary: Colors.white,
      ),

      // Tema do AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
            color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
      ),

      // Tema dos Campos de Texto (TextFormField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(color: hintColor),
        prefixIconColor: hintColor,
      ),

      // Tema dos Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Tema do TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
    );
  }
}
