// lib/features/home/presentation/pages/match_details_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:quadrafacil/core/config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchDetailsPage extends StatefulWidget {
  final String matchId;
  
  const MatchDetailsPage({super.key, required this.matchId});

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  bool _isLoading = true;
  bool _isJoining = false; 
  bool _isLeaving = false; // 1. Novo estado de loading para "Sair"
  Map<String, dynamic>? _matchData;
  String? _errorMessage;

  String? _currentUserId;
  bool _isCurrentUserParticipant = false;
  bool _isOrganizador = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchMatchDetails();
  }

  Future<void> _fetchMatchDetails() async {
    if (!mounted) return;
    // Não seta _isLoading = true aqui para o refresh ser mais suave
    // Apenas no initState
    if (_matchData == null) {
       setState(() {
         _isLoading = true;
         _errorMessage = null;
       });
    }

    try {
      final url = Uri.parse('${AppConfig.apiUrl}/matches/${widget.matchId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _matchData = jsonDecode(response.body);
            _isLoading = false;
            _checkUserStatus();
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
  
  void _checkUserStatus() {
    if (_matchData == null || _currentUserId == null) return;

    final organizadorId = _matchData!['organizadorId'];
    final participantes = _matchData!['participantesData'] as List? ?? [];

    setState(() {
      _isOrganizador = (_currentUserId == organizadorId);
      _isCurrentUserParticipant = participantes.any((p) => p['id'] == _currentUserId);
    });
  }


  // Função _joinMatch (Entrar na Partida) - (Sem alterações)
  Future<void> _joinMatch() async {
    if (_isJoining || _currentUserId == null) return;
    setState(() => _isJoining = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/matches/${widget.matchId}/join');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você entrou na partida!'), backgroundColor: Colors.green),
        );
        // Atualiza o estado local e busca os dados novos
        setState(() {
          _isCurrentUserParticipant = true;
        });
        _fetchMatchDetails(); // Re-busca os dados para atualizar a lista
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao entrar na partida.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  // --- 2. NOVAS FUNÇÕES PARA "SAIR DA PARTIDA" ---
  
  // Diálogo de confirmação
  Future<void> _showLeaveConfirmationDialog() async {
    if (_isLeaving) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da Partida?'),
        content: const Text('Tem certeza que deseja sair desta partida? Sua vaga será disponibilizada para outros jogadores.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performLeaveMatch(); // Chama a API
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, Sair'),
          ),
        ],
      ),
    );
  }

  // Função que chama a API DELETE
  Future<void> _performLeaveMatch() async {
    if (_isLeaving || _currentUserId == null) return;
    setState(() => _isLeaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/matches/${widget.matchId}/leave');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $idToken', // Envia o token
        },
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você saiu da partida.'), backgroundColor: Colors.blue),
        );
        // Atualiza o estado local e busca os dados novos
        setState(() {
          _isCurrentUserParticipant = false;
        });
        _fetchMatchDetails(); // Re-busca os dados para atualizar a lista
      } else {
        // Mostra o erro da API (ex: "O organizador não pode sair")
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao sair da partida.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLeaving = false);
      }
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

    final match = _matchData!;
    final quadra = match['quadraData'] ?? {};
    final organizador = match['organizadorData'] ?? {};
    final participantes = match['participantesData'] as List? ?? [];
    
    final int vagasDisponiveis = match['vagasDisponiveis'] ?? 0;
    final int totalParticipantes = participantes.length;
    final int vagasTotais = totalParticipantes + vagasDisponiveis;
    
    final num precoTotal = (match['priceTotal'] as num?) ?? 0; 
    final double precoPorPessoa = (precoTotal > 0 && vagasTotais > 0) ? (precoTotal / vagasTotais) : 0.0;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator( // 3. Adiciona RefreshIndicator
            onRefresh: _fetchMatchDetails,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildInfoCard(match, precoPorPessoa),
                const SizedBox(height: 24),
    
                Text('Participantes ($totalParticipantes/$vagasTotais)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildParticipantsList(participantes, organizador['nome']),
                const SizedBox(height: 24),
    
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
        ),
        SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildActionButton(vagasDisponiveis),
          ),
        ),
      ],
    );
  }

  // 4. Lógica do Botão ATUALIZADA
  Widget _buildActionButton(int vagasDisponiveis) {
    if (_isOrganizador) {
      return ElevatedButton(
        onPressed: null, 
        style: ElevatedButton.styleFrom(disabledBackgroundColor: Colors.grey[300]),
        child: const Text('VOCÊ É O ORGANIZADOR', style: TextStyle(color: Colors.black54)),
      );
    }

    if (_isCurrentUserParticipant) {
      return OutlinedButton.icon(
        // 5. Conecta o botão de Sair
        onPressed: _isLeaving ? null : _showLeaveConfirmationDialog, 
        icon: _isLeaving
          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
          : const Icon(Icons.remove_circle_outline),
        label: const Text('SAIR DA PARTIDA'),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
      );
    }
    
    if (vagasDisponiveis <= 0) {
      return const ElevatedButton(
        onPressed: null, 
        child: Text('VAGAS ESGOTADAS'),
      );
    }

    // Caso padrão: pode entrar
    return ElevatedButton.icon(
      onPressed: _isJoining ? null : _joinMatch, 
      icon: _isJoining 
        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : const Icon(Icons.add_task_outlined),
      label: const Text('SOLICITAR PARTICIPAÇÃO'),
    );
  }


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
          final bool isOrganizador = participant['id'] == _matchData!['organizadorId'];

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