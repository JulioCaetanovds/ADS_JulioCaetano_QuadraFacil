// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/auth_check_page.dart';
import 'package:quadrafacil/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

// A função main agora é async para podermos esperar o Firebase
Future<void> main() async {
  // Garante que o Flutter esteja pronto
  WidgetsFlutterBinding.ensureInitialized();
  
  // Linha principal: Inicializa o Firebase usando o arquivo de opções
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('pt_BR', null);

  // O resto do código que já tínhamos
  final prefs = await SharedPreferences.getInstance();
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
      // A tela inicial agora é decidida pela variável showOnboarding
      home: showOnboarding ? const OnboardingPage() : const AuthCheckPage(),
    );
  }
}
