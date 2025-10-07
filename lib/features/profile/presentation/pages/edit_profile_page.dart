// lib/features/profile/presentation/pages/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Avatar e botão para alterar foto
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.person, size: 70, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.accentColor,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                        onPressed: () { /* Lógica para alterar a foto */ },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Formulário
          TextFormField(
            initialValue: 'Júlio Caetano', // Dado de exemplo
            decoration: const InputDecoration(labelText: 'Nome completo'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: 'atleta@email.com', // Dado de exemplo
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 48),

          // Botão Salvar
          ElevatedButton(
            onPressed: () {
              // Lógica para salvar as alterações
              Navigator.of(context).pop(); // Volta para a tela anterior
            },
            child: const Text('SALVAR ALTERAÇÕES'),
          ),
        ],
      ),
    );
  }
}