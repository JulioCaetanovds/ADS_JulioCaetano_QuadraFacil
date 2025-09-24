// lib/main.dart

import 'package:flutter/material.dart'; // Note os dois pontos
import 'package:quadrafacil/features/authentication/presentation/pages/auth_check_page.dart';
import 'package:quadrafacil/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

// A função main agora é async para podermos esperar o shared_preferences
Future<void> main() async {
  // Garante que os widgets do Flutter estejam prontos antes de mais nada
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega a instância do SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Checa se a flag 'showOnboarding' é nula ou true (padrão para a primeira vez)
  final showOnboarding = prefs.getBool('showOnboarding') ?? true;

  runApp(QuadraFacilApp(showOnboarding: showOnboarding));
}

class QuadraFacilApp extends StatelessWidget {
  final bool showOnboarding;
  const QuadraFacilApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quadra Fácil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // A tela inicial agora é decidida pela variável showOnboarding
      home: showOnboarding ? const OnboardingPage() : const AuthCheckPage(),
    );
  }
}
