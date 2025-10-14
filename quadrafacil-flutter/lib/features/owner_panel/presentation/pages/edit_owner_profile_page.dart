// lib/features/owner_panel/presentation/pages/edit_owner_profile_page.dart
import 'package:flutter/material.dart';

class EditOwnerProfilePage extends StatelessWidget {
  const EditOwnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil do Dono')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          TextFormField(
            initialValue: 'Júlio Caetano (Dono)',
            decoration: const InputDecoration(labelText: 'Nome do Responsável'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: 'Quadra Central & Cia',
            decoration: const InputDecoration(labelText: 'Nome do Estabelecimento'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: '(54) 99999-8888',
            decoration: const InputDecoration(labelText: 'Telefone para Contato'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('SALVAR ALTERAÇÕES'),
          ),
        ],
      ),
    );
  }
}