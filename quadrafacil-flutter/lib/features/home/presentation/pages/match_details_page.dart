// lib/features/home/presentation/pages/match_details_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class MatchDetailsPage extends StatelessWidget {
  const MatchDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Partida'),
      ),
      // 1. Mudamos a estrutura para uma Column
      body: Column(
        children: [
          // 2. O conteúdo principal agora fica em um Expanded para ser rolável
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Seção de Informações Principais
                _buildInfoCard(),
                const SizedBox(height: 24),

                // Seção de Participantes
                const Text('Participantes (8/10)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildParticipantsList(),
                const SizedBox(height: 24),

                // Seção de Localização
                const Text('Localização', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero, // Remove padding extra do ListTile
                  leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
                  title: const Text('Quadra Central'),
                  subtitle: const Text('Centro, Passo Fundo - RS'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () { /* Abriria o mapa */ },
                ),
              ],
            ),
          ),
          // 3. O botão agora fica no final da Column, dentro de uma área segura
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_task_outlined), // Ícone mais adequado
                // 4. Texto do botão alterado
                label: const Text('SOLICITAR PARTICIPAÇÃO'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para o card de informações
  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.sports_soccer, 'Esporte', 'Futsal'),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today_outlined, 'Data', 'Hoje, 06/10/25'),
            const Divider(height: 24),
            _buildInfoRow(Icons.access_time_outlined, 'Horário', '20:00 - 21:00'),
            const Divider(height: 24),
            // 5. Valor por pessoa adicionado aqui
            _buildInfoRow(Icons.monetization_on_outlined, 'Valor por pessoa', 'R\$ 15,00'),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para as linhas de informação
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.hintColor, size: 20),
        const SizedBox(width: 16),
        Text(title, style: const TextStyle(color: AppTheme.hintColor)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // Widget auxiliar para a lista de participantes
  Widget _buildParticipantsList() {
    final participants = List.generate(8, (index) => 'Jogador ${index + 1}');

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: participants.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 70,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.person),
                ),
                const SizedBox(height: 4),
                Text(
                  participants[index],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}