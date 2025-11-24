// lib/features/onboarding/presentation/pages/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/auth_check_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Se tiver o AppTheme, pode importar aqui. Caso contrário, mantive as cores locais.
import 'package:quadrafacil/core/theme/app_theme.dart'; 

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Função para navegar para a tela de autenticação e salvar a flag
  void _navigateToAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      'showOnboarding',
      false,
    ); // Marcamos que o onboarding já foi visto

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthCheckPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            // O setState aqui serve apenas para reconstruir se tivermos indicadores de página (bolinhas)
          });
        },
        children: <Widget>[
          // SLIDE 1: AGILIDADE (Reserva)
          OnboardingSlide(
            titulo: 'Agilidade na Reserva',
            texto:
                'Encontre as melhores quadras da cidade e garanta seu horário em segundos. Sem ligações, sem complicação e com confirmação rápida.',
            icon: Icons.calendar_month_outlined, // Ícone de calendário
            pageController: _pageController,
            isLastPage: false,
            onGetStarted: _navigateToAuth,
          ),
          // SLIDE 2: COMUNIDADE (Partidas Abertas - Seu Diferencial)
          OnboardingSlide(
            titulo: 'Complete seu Time',
            texto:
                'Faltou um goleiro? Crie uma "Partida Aberta", defina as vagas e encontre jogadores na comunidade para fechar o jogo.',
            icon: Icons.groups_outlined, // Ícone de grupo
            pageController: _pageController,
            isLastPage: false,
            onGetStarted: _navigateToAuth,
          ),
          // SLIDE 3: GESTÃO (Dono e Atleta)
          OnboardingSlide(
            titulo: 'Gestão Descomplicada',
            texto:
                'Para donos e atletas: controle pagamentos, confirme reservas e gerencie sua agenda em um só lugar. Tudo pronto para começar?',
            icon: Icons.verified_outlined, // Ícone de verificado/gestão
            pageController: _pageController,
            isLastPage: true, // Última página
            onGetStarted: _navigateToAuth,
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  final String titulo;
  final String texto;
  final IconData icon; // Adicionado para permitir ícones diferentes
  final PageController? pageController;
  final bool isLastPage;
  final VoidCallback onGetStarted;

  const OnboardingSlide({
    super.key,
    required this.titulo,
    required this.texto,
    required this.icon, // Obrigatório agora
    this.pageController,
    required this.isLastPage,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    // Usando AppTheme se disponível, senão fallback para verde
    const Color corPrimaria = AppTheme.primaryColor; 
    const Color corTextoPrincipal = AppTheme.textColor;
    const Color corTextoSecundario = AppTheme.hintColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // Centraliza verticalmente
                children: [
                  // Círculo decorativo atrás do ícone
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: corPrimaria.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 80, color: corPrimaria),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 28,
                      color: corTextoPrincipal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 18, // Aumentei um pouco para leitura melhor
                      color: corTextoSecundario,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 80), // Espaço para o botão não cobrir o texto
                ],
              ),
            ),
            Positioned(
              bottom: 30,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: isLastPage
                    ? onGetStarted
                    : () {
                        pageController?.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                icon: Icon(
                  isLastPage ? Icons.check : Icons.arrow_forward,
                  color: Colors.white,
                ),
                label: Text(
                  isLastPage ? 'COMEÇAR' : 'AVANÇAR',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: corPrimaria,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            // Botão "Pular" (Opcional, mas boa prática de UX)
            if (!isLastPage)
              Positioned(
                bottom: 30,
                left: 20,
                child: TextButton(
                  onPressed: onGetStarted,
                  child: const Text(
                    'Pular',
                    style: TextStyle(color: corTextoSecundario, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}