// lib/features/authentication/presentation/pages/auth_check_page.dart
import 'package:flutter/material.dart';

class AuthCheckPage extends StatelessWidget {
  const AuthCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Aqui será a página de Login/Cadastro',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
