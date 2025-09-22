// lib/features/authentication/presentation/pages/register_page.dart

import 'package:flutter/material.dart';

// Usamos um enum para deixar o código do perfil mais legível
enum UserRole { atleta, dono }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Variável de estado para controlar a seleção do Radio
  UserRole? _selectedRole = UserRole.atleta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crie sua conta'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Seleção de Perfil
              const Text(
                'Eu sou:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<UserRole>(
                      title: const Text('Atleta'),
                      value: UserRole.atleta,
                      groupValue: _selectedRole,
                      onChanged: (UserRole? value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<UserRole>(
                      title: const Text('Dono de Quadra'),
                      value: UserRole.dono,
                      groupValue: _selectedRole,
                      onChanged: (UserRole? value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  // Lógica de cadastro virá aqui
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('CADASTRAR', style: TextStyle(fontSize: 16)),
              ),

              // Link para Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Já tem uma conta?"),
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(); // Volta para a tela anterior (Login)
                    },
                    child: const Text('Faça login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
