// lib/features/authentication/presentation/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/core/config.dart';

enum UserRole { atleta, dono }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 1. Controllers para pegar os dados dos campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Set<UserRole> _selectedRole = {UserRole.atleta};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. Lógica de cadastro que chama a nossa API
  Future<void> _handleRegister() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final url = Uri.parse('${AppConfig.apiUrl}/auth/register');

    try {
      final response = await http.post(
        url,
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': _selectedRole.first == UserRole.atleta ? 'atleta' : 'dono',
        }),
      );

      if (response.statusCode == 201 && mounted) {
        // Sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário cadastrado com sucesso! Faça o login.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Volta para a tela de login
      } else {
        // Erro vindo da API
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Ocorreu um erro.');
      }
    } catch (e) {
      // Erro de conexão ou da API
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text('Crie sua Conta', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                const SizedBox(height: 8),
                const Text('Preencha os dados para começar', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppTheme.hintColor)),
                const SizedBox(height: 32),

                // Formulário com controllers
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                const Text('Eu sou:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<UserRole>(
                  segments: const <ButtonSegment<UserRole>>[
                    ButtonSegment<UserRole>(value: UserRole.atleta, label: Text('Atleta'), icon: Icon(Icons.sports_soccer)),
                    ButtonSegment<UserRole>(value: UserRole.dono, label: Text('Dono de Quadra'), icon: Icon(Icons.store)),
                  ],
                  selected: _selectedRole,
                  onSelectionChanged: (Set<UserRole> newSelection) {
                    setState(() { _selectedRole = newSelection; });
                  },
                  style: SegmentedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
                const SizedBox(height: 32),
                
                // Botão de Cadastrar com loading
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('CADASTRAR'),
                ),
                const SizedBox(height: 24),

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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}