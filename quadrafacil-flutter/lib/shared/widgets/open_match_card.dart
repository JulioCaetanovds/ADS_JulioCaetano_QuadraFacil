import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/home/presentation/pages/match_details_page.dart'; // Importa a página de detalhes

// Widget reutilizável para exibir um card de Partida Aberta
class OpenMatchCard extends StatelessWidget {
  final int vagas;
  final String esporte;
  final String horario;
  final String quadra;

  const OpenMatchCard({
    super.key,
    required this.vagas,
    required this.esporte,
    required this.horario,
    required this.quadra
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250, // Largura fixa para scroll horizontal
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      child: InkWell( // Permite o clique
        onTap: () {
          // Navega para a tela de detalhes da partida
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MatchDetailsPage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink( // Necessário para o efeito visual do InkWell em containers com decoração
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: const AssetImage('assets/images/placeholder_quadra.png'), // Imagem local
              fit: BoxFit.cover,
              // Filtro escuro para melhor legibilidade do texto
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end, // Alinha o texto na base
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de vagas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.accentColor, // Usa a cor de destaque do tema
                    borderRadius: BorderRadius.circular(8)),
                child: Text('$vagas vagas',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              // Informações da partida
              Text('$esporte • $horario',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(quadra, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
