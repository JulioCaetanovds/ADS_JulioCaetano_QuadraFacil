// lib/features/authentication/presentation/pages/profile_completion_page.dart

import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart'; // Importamos o tema

// Reutilizamos o mesmo enum da página de registro
enum UserRole { atleta, dono }

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  Set<UserRole> _selectedRole = {UserRole.atleta};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.person_pin_circle_outlined,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Só mais um passo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Para personalizar sua experiência, nos diga qual tipo de perfil você é.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.hintColor,
                ),
              ),
              const SizedBox(height: 48),

              // Reutilizamos o mesmo SegmentedButton da tela de cadastro
              SegmentedButton<UserRole>(
                segments: const <ButtonSegment<UserRole>>[
                  ButtonSegment<UserRole>(
                      value: UserRole.atleta,
                      label: Text('Atleta'),
                      icon: Icon(Icons.sports_soccer)),
                  ButtonSegment<UserRole>(
                      value: UserRole.dono,
                      label: Text('Dono de Quadra'),
                      icon: Icon(Icons.store)),
                ],
                selected: _selectedRole,
                onSelectionChanged: (Set<UserRole> newSelection) {
                  setState(() {
                    _selectedRole = newSelection;
                  });
                },
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Lógica para salvar o perfil e navegar para a home do app virá aqui
                  print('Perfil selecionado: $_selectedRole');
                },
                child: const Text('FINALIZAR CADASTRO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
