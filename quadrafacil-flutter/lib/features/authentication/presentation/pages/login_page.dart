// lib/features/authentication/presentation/pages/login_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/register_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/athlete_home_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/owner_home_page.dart';
import 'package:quadrafacil/core/config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // Controle para mostrar/ocultar senha

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Backdoor para Dev (Facilita seus testes)
    if (_emailController.text == 'atleta' && _passwordController.text == 'admin') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AthleteHomePage()));
      return;
    }
    if (_emailController.text == 'dono' && _passwordController.text == 'admin') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const OwnerHomePage()));
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception('Usuário não encontrado.');

      final idToken = await user.getIdToken(true);
      if (idToken == null) throw Exception('Token de autenticação inválido.');

      await _testApiProtectedRoute(idToken);

    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(e.message ?? 'Erro de autenticação.');
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testApiProtectedRoute(String idToken) async {
    final url = Uri.parse('${AppConfig.apiUrl}/auth/me');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200 && mounted) {
        final responseBody = jsonDecode(response.body);
        final role = responseBody['user']['role'];

        if (role == 'atleta') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AthleteHomePage()));
        } else if (role == 'dono') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const OwnerHomePage()));
        } else {
          throw Exception('Perfil desconhecido.');
        }
      } else {
        throw Exception('Erro ao obter perfil: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha na conexão: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo ou Ícone
                const Icon(Icons.sports_soccer, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                
                const Text(
                  'Bem-vindo de volta!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acesse sua conta para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),

                // Campo Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onFieldSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 20),

                // Campo Senha
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onFieldSubmitted: (_) => _handleLogin(),
                ),
                
                /* const SizedBox(height: 12),
                // Link "Esqueceu a senha?" (Decorativo por enquanto)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, 
                    child: const Text('Esqueceu a senha?', style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                ), */
                const SizedBox(height: 24),

                // Botão Entrar
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 40),

                // Rodapé
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Não tem uma conta?", style: TextStyle(color: Colors.grey[600])),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterPage()));
                      },
                      child: const Text('Cadastre-se', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}