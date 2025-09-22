// lib/features/onboarding/presentation/pages/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/auth_check_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
            _currentPage = index;
          });
        },
        children: <Widget>[
          OnboardingSlide(
            titulo: 'O que é o Quadra Fácil?',
            loremIpsum:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus lacinia odio vitae vestibulum vestibulum. Cras venenatis euismod malesuada.',
            pageController: _pageController,
            isLastPage: false,
            onGetStarted: _navigateToAuth,
          ),
          OnboardingSlide(
            titulo: 'Features e Diferenciais',
            loremIpsum:
                'Praesent quis nisi et justo sodales scelerisque. Donec aliquam, massa quis elementum laoreet, magna dolor rhoncus est, et pulvinar lacus justo et elit.',
            pageController: _pageController,
            isLastPage: false,
            onGetStarted: _navigateToAuth,
          ),
          OnboardingSlide(
            titulo: 'Tudo Pronto para Começar!',
            loremIpsum:
                'Nunc efficitur, enim nec pellentesque commodo, arcu ex semper sem, vel commodo enim quam in sapien. Curabitur dapibus interdum elit.',
            pageController: _pageController,
            isLastPage: true, // Marcamos que esta é a última página
            onGetStarted: _navigateToAuth,
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  final String titulo;
  final String loremIpsum;
  final PageController? pageController;
  final bool isLastPage;
  final VoidCallback onGetStarted;

  const OnboardingSlide({
    super.key,
    required this.titulo,
    required this.loremIpsum,
    this.pageController,
    required this.isLastPage,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    // ... (O build do OnboardingSlide continua o mesmo, com uma pequena mudança no botão)
    const Color corPrimaria = Colors.green;
    const Color corTextoPrincipal = Colors.black87;
    const Color corTextoSecundario = Colors.black54;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sports_soccer, size: 80, color: corPrimaria),
                  const SizedBox(height: 24),
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
                    loremIpsum,
                    style: const TextStyle(
                      fontSize: 16,
                      color: corTextoSecundario,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton.icon(
                // Ação do botão agora é dinâmica
                onPressed: isLastPage
                    ? onGetStarted
                    : () {
                        pageController?.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                // O ícone e texto também mudam se for a última página
                icon: Icon(
                  isLastPage ? Icons.check_circle : Icons.arrow_forward,
                  color: Colors.white,
                ),
                label: Text(
                  isLastPage ? 'Começar' : 'Avançar',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: corPrimaria,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
