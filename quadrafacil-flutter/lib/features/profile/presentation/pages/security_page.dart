// lib/features/profile/presentation/pages/security_page.dart
import 'package:flutter/material.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segurança'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Alterar Senha'),
            subtitle: const Text('Recomendamos alterar sua senha periodicamente.'),
            onTap: () {
              // Navegaria para uma tela específica de alteração de senha
            },
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Gerenciar Dispositivos'),
            subtitle: const Text('Verificar onde sua conta está ativa.'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}