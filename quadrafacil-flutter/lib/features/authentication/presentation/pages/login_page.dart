// lib/features/authentication/presentation/pages/login_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/register_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/athlete_home_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/owner_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Função de login com Firebase
  Future<void> _handleLogin() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Logins temporários para desenvolvimento
    if (_emailController.text == 'atleta' && _passwordController.text == 'admin') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AthleteHomePage()));
      return;
    }
    if (_emailController.text == 'dono' && _passwordController.text == 'admin') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const OwnerHomePage()));
      return;
    }

    try {
      // 1. Login com Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Usuário não encontrado.');
      }

      // 2. Pega o ID Token
      final idToken = await user.getIdToken();
      
      // 3. Verificação de nulidade (A CORREÇÃO)
      if (idToken == null) {
        throw Exception('Não foi possível obter o token de autenticação.');
      }
      
      print('Firebase ID Token obtido com sucesso!');

      // 4. Testa a rota protegida da API, agora com a certeza de que o token não é nulo
      await _testApiProtectedRoute(idToken);

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Ocorreu um erro de autenticação.'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Função para testar a API
  Future<void> _testApiProtectedRoute(String idToken) async {
    // IMPORTANTE: Use o IP da sua máquina aqui! (ex: 192.168.1.5)
    final url = Uri.parse('http://192.168.10.196:3000/auth/me');

    try {
      final response = await http.get(
        url,
        headers: { 'Authorization': 'Bearer $idToken' },
      );

      if (response.statusCode == 200 && mounted) {
        final responseBody = jsonDecode(response.body);
        print('Resposta da API: ${responseBody['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API: ${responseBody['message']}'), backgroundColor: Colors.green),
        );
      } else {
        print('Erro da API: ${response.body}');
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro na API: ${response.body}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
       print('Erro de conexão com a API: $e');
       if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível conectar à API. Verifique o IP e se o servidor está rodando.'), backgroundColor: Colors.red),
          );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                
                // Cabeçalho
                const Text('Bem-vindo de volta!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor)),
                const SizedBox(height: 8),
                const Text('Faça login para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppTheme.hintColor)),
                const SizedBox(height: 48),

                // Formulário
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                  onFieldSubmitted: (value) => _handleLogin(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                  onFieldSubmitted: (value) => _handleLogin(),
                ),
                const SizedBox(height: 24),

                // Botão de Entrar
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('ENTRAR'),
                ),
                const SizedBox(height: 24),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('OU')),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Image.asset('assets/images/google_logo.png',
                      height: 20.0),
                  label: const Text('Entrar com o Google',
                      style: TextStyle(color: AppTheme.textColor)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 48),

                // Rodapé
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Não tem uma conta?"),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const RegisterPage()));
                      },
                      child: const Text('Cadastre-se'),
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