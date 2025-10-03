// lib/features/authentication/presentation/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

enum UserRole { atleta, dono }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  Set<UserRole> _selectedRole = {UserRole.atleta};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(), // AppBar para o botão de voltar
      body: SafeArea(
        // Adotamos a mesma estrutura robusta da tela de Login
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24), // Espaço no topo
                
                // Cabeçalho
                const Text(
                  'Crie sua Conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Preencha os dados para começar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.hintColor),
                ),
                const SizedBox(height: 32),

                // Formulário
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                // Seleção de Perfil
                const Text('Eu sou:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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
                
                // Botão principal
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('CADASTRAR'),
                ),
                const SizedBox(height: 24),

                // Rodapé
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Já tem uma conta?"),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Faça login'),
                    ),
                  ],
                ),
                const SizedBox(height: 24), // Espaço na base
              ],
            ),
          ),
        ),
      ),
    );
  }
}