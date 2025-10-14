// lib/features/authentication/presentation/pages/auth_check_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/login_page.dart';

class AuthCheckPage extends StatelessWidget {
  const AuthCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Por enquanto, esta página sempre levará ao Login.
    // No futuro, ela verificará se o usuário já está logado.
    return const LoginPage();
  }
}
