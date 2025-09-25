// lib/features/authentication/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // A função de login que já tínhamos
  void _handleLogin() {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email == 'atleta' && password == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AthleteHomePage()),
      );
    } else if (email == 'dono' && password == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OwnerHomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Credenciais inválidas! Use atleta/admin ou dono/admin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    const Text('Bem-vindo de volta!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor)),
                    const SizedBox(height: 8),
                    const Text('Faça login para continuar',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 16, color: AppTheme.hintColor)),
                    SizedBox(height: screenHeight * 0.05),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                      // Adicionamos aqui. O `(value)` é obrigatório, mas não precisamos usá-lo.
                      onFieldSubmitted: (value) => _handleLogin(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock_outline)),
                      obscureText: true,
                      // Adicionamos aqui também.
                      onFieldSubmitted: (value) => _handleLogin(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text('ENTRAR'),
                    ),
                    // ... resto do código da página ...
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
                    const Spacer(),
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
