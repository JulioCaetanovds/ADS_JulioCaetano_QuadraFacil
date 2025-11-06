// lib/features/home/presentation/pages/match_details_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:quadrafacil/core/config.dart';

// 1. Convertido para StatefulWidget
class MatchDetailsPage extends StatefulWidget {
  // 2. Recebe o ID da partida
  final String matchId;
  
  const MatchDetailsPage({super.key, required this.matchId});

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  bool _isLoading = true;
  bool _isJoining = false; // Loading do botão de participar
  Map<String, dynamic>? _matchData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMatchDetails();
  }

  // 3. Função para buscar os dados da API
  Future<void> _fetchMatchDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('${AppConfig.apiUrl}/matches/${widget.matchId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _matchData = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Falha ao carregar detalhes da partida: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }
  
  // 4. TODO: Função para entrar na partida (RF09)
  Future<void> _joinMatch() async {
    if (_isJoining) return;
    setState(() => _isJoining = true);
    
    // Simula uma chamada de API
    await Future.delayed(const Duration(seconds: 1));
    print('TODO: Chamar API POST /matches/${widget.matchId}/join');

    // Por enquanto, apenas exibe um SnackBar
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('TODO: Implementar API para entrar na partida!'), backgroundColor: Colors.blue),
       );
       setState(() => _isJoining = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Partida'),
      ),
      body: _buildBody(),
    );
  }

  // 5. Lógica de construção do corpo (loading, erro, sucesso)
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchMatchDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            )
          ],
        ),
      );
    }

    if (_matchData == null) {
      return const Center(child: Text('Partida não encontrada.'));
    }

    // 6. Extrai os dados reais da API
    final match = _matchData!;
    final quadra = match['quadraData'] ?? {};
    final organizador = match['organizadorData'] ?? {};
    final participantes = match['participantesData'] as List? ?? [];
    
    final int vagasDisponiveis = match['vagasDisponiveis'] ?? 0;
    final int totalParticipantes = participantes.length;
    // O total de vagas é o número de participantes + vagas disponíveis
    final int vagasTotais = totalParticipantes + vagasDisponiveis;
    
    final precoTotal = match['priceTotal'] ?? 0;
    final precoPorPessoa = (precoTotal > 0 && vagasTotais > 0) ? (precoTotal / vagasTotais) : 0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Card de Informações
              _buildInfoCard(match, precoPorPessoa),
              const SizedBox(height: 24),

              // Seção de Participantes
              Text('Participantes ($totalParticipantes/$vagasTotais)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildParticipantsList(participantes, organizador['nome']),
              const SizedBox(height: 24),

              // Seção de Localização
              const Text('Localização',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined,
                    color: AppTheme.primaryColor),
                title: Text(quadra['nome'] ?? 'Quadra N/A'),
                subtitle: Text(quadra['endereco'] ?? 'Endereço N/A'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () { /* TODO: Abrir mapa com o endereço */ },
              ),
            ],
          ),
        ),
        // Botão de Ação
        SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isJoining ? null : _joinMatch, // 7. Chama a função
              icon: _isJoining 
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.add_task_outlined),
              label: const Text('SOLICITAR PARTICIPAÇÃO'),
            ),
          ),
        ),
      ],
    );
  }

  // 8. Helper atualizado para dados reais
  Widget _buildInfoCard(Map<String, dynamic> match, double precoPorPessoa) {
     final String esporte = match['quadraData']?['esporte'] ?? 'N/D';
     final String data = _formatTimestamp(match['startTime'], 'dd/MM/yy (EEEE)');
     final String horario = '${_formatTimestamp(match['startTime'], 'HH:mm')} - ${_formatTimestamp(match['endTime'], 'HH:mm')}';
     final String preco = 'R\$ ${precoPorPessoa.toStringAsFixed(2).replaceAll('.', ',')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.sports_soccer, 'Esporte', esporte),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today_outlined, 'Data', data),
            const Divider(height: 24),
            _buildInfoRow(Icons.access_time_outlined, 'Horário', horario),
            const Divider(height: 24),
            _buildInfoRow(Icons.monetization_on_outlined, 'Valor por pessoa', preco),
          ],
        ),
      ),
    );
  }

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

  // 9. Helper atualizado para dados reais
  Widget _buildParticipantsList(List<dynamic> participants, String organizadorNome) {
    if (participants.isEmpty) {
      return const Text('Ainda não há participantes.', style: TextStyle(color: AppTheme.hintColor));
    }
    
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final participant = participants[index];
          // TODO: Usar 'participant['fotoUrl']' quando a API buscar
          final bool isOrganizador = participant['nome'] == organizadorNome;

          return SizedBox(
            width: 70,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: isOrganizador ? AppTheme.primaryColor.withOpacity(0.2) : Colors.grey[200],
                  child: Icon(
                    isOrganizador ? Icons.star : Icons.person,
                    color: isOrganizador ? AppTheme.primaryColor : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  participant['nome'],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: isOrganizador ? FontWeight.bold : FontWeight.normal),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // 10. Helper de formatação de data
  String _formatTimestamp(dynamic timestamp, String format) {
    DateTime? time;
    if (timestamp is Map && timestamp['_seconds'] != null) {
      time = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      time = DateTime.tryParse(timestamp);
    }

    if (time != null) {
      return DateFormat(format, 'pt_BR').format(time);
    }
    return 'N/A';
  }
}