// lib/features/home/presentation/pages/match_details_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:quadrafacil/core/config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quadrafacil/features/chat/presentation/pages/chat_detail_page.dart'; 

class MatchDetailsPage extends StatefulWidget {
  final String matchId;
  
  const MatchDetailsPage({super.key, required this.matchId});

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  bool _isLoading = true;
  bool _isJoining = false; 
  bool _isLeaving = false;
  bool _isProcessingRequest = false; 

  Map<String, dynamic>? _matchData;
  String? _errorMessage;

  String? _currentUserId;
  bool _isCurrentUserParticipant = false;
  bool _isCurrentUserPending = false;
  bool _isOrganizador = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchMatchDetails();
  }

  Future<void> _fetchMatchDetails() async {
    if (!mounted) return;
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
        throw Exception('Falha ao carregar partida.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro de conexão.';
          _isLoading = false;
        });
      }
    }
  }
  
  void _checkUserStatus() {
    if (_matchData == null || _currentUserId == null) return;

    final organizadorId = _matchData!['organizadorId'];
    final participantes = _matchData!['participantesData'] as List? ?? [];
    final pendentes = _matchData!['pendentesData'] as List? ?? []; 

    _isOrganizador = (_currentUserId == organizadorId);
    _isCurrentUserParticipant = participantes.any((p) => p['id'] == _currentUserId);
    _isCurrentUserPending = pendentes.any((p) => p['id'] == _currentUserId);
  }

  Future<void> _handleRequest(String userId, bool approve) async {
    if (_isProcessingRequest) return;
    setState(() => _isProcessingRequest = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final action = approve ? 'approve' : 'reject';
      final url = Uri.parse('${AppConfig.apiUrl}/matches/${widget.matchId}/$action');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'userIdTo${approve ? 'Approve' : 'Reject'}': userId
        }),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Solicitação aprovada!' : 'Solicitação recusada.'), 
            backgroundColor: approve ? Colors.green : Colors.orange
          ),
        );
        _fetchMatchDetails(); 
      } else {
        throw Exception('Erro na solicitação.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao processar.'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessingRequest = false);
    }
  }

  Future<void> _joinMatch() async {
    if (_isJoining || _currentUserId == null) return;
    setState(() => _isJoining = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user!.getIdToken(true);
      final url = Uri.parse('${AppConfig.apiUrl}/matches/${widget.matchId}/join');
      final response = await http.post(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'});

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitação enviada!'), backgroundColor: Colors.green));
        _fetchMatchDetails(); 
      } else {
        throw Exception('Erro ao entrar.');
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao solicitar entrada.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _performLeaveMatch() async {
    if (_isLeaving || _currentUserId == null) return;
    setState(() => _isLeaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user!.getIdToken(true);
      final url = Uri.parse('${AppConfig.apiUrl}/matches/${widget.matchId}/leave');
      final response = await http.delete(url, headers: {'Authorization': 'Bearer $idToken'});

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você saiu da partida.'), backgroundColor: Colors.blue));
        _fetchMatchDetails(); 
      }
    } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao sair.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  Future<void> _handleMatchChat() async {
    if (_isProcessingRequest) return;
    setState(() => _isProcessingRequest = true);

    try {
        final user = FirebaseAuth.instance.currentUser;
        final idToken = await user!.getIdToken(true);
        final url = Uri.parse('${AppConfig.apiUrl}/chats/match/${widget.matchId}');
        final response = await http.post(url, headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'});

        if (response.statusCode == 200 || response.statusCode == 201) {
            final responseData = jsonDecode(response.body);
            final chatId = responseData['chatId'];
            final chatTitle = _matchData!['quadraData']?['nome'] ?? 'Chat da Partida';

            if (mounted) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatDetailPage(chatId: chatId, title: chatTitle)
                ));
            }
        }
    } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao abrir chat.'), backgroundColor: Colors.red));
    } finally {
        if (mounted) setState(() => _isProcessingRequest = false);
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detalhes da Partida', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));
    if (_matchData == null) return const Center(child: Text('Partida não encontrada.'));

    final match = _matchData!;
    final quadra = match['quadraData'] ?? {};
    final organizador = match['organizadorData'] ?? {};
    final participantes = match['participantesData'] as List? ?? [];
    final pendentes = match['pendentesData'] as List? ?? []; 
    
    final int vagasDisponiveis = match['vagasDisponiveis'] ?? 0;
    final int totalParticipantes = participantes.length;
    final int vagasTotais = totalParticipantes + vagasDisponiveis;
    
    // --- CORREÇÃO AQUI: Pegamos o valor total direto ---
    // Se o campo 'priceTotal' não existir, usamos 0.0 como fallback
    final double precoQuadra = (match['priceTotal'] as num?)?.toDouble() ?? 0.0; 

    final bool canAccessChat = _isOrganizador || _isCurrentUserParticipant; 

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchMatchDetails,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Card Principal (Agora passa o preço total da quadra)
                _buildInfoCard(match, precoQuadra),
                const SizedBox(height: 24),

                // 2. Área de Aprovação (Só para Organizador)
                if (_isOrganizador && pendentes.isNotEmpty) ...[
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.orange[50],
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: Colors.orange[200]!)
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(children: [
                           const Icon(Icons.notifications_active, color: Colors.orange),
                           const SizedBox(width: 8),
                           Text('Solicitações (${pendentes.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                         ]),
                         const SizedBox(height: 12),
                         _buildRequestsList(pendentes),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                ],
    
                // 3. Participantes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Participantes ($totalParticipantes/$vagasTotais)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                    if (canAccessChat)
                      TextButton.icon(
                        onPressed: _isProcessingRequest ? null : _handleMatchChat,
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Chat'),
                      )
                  ],
                ),
                const SizedBox(height: 12),
                _buildParticipantsList(participantes),
                const SizedBox(height: 24),
                
                // 4. Localização
                const Text('Local', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  color: Colors.white,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                    ),
                    title: Text(quadra['nome'] ?? 'Quadra N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(quadra['endereco'] ?? 'Endereço N/A'),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 5. Botão de Ação Fixo no rodapé
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
          child: SafeArea(child: _buildActionButton(vagasDisponiveis)),
        ),
      ],
    );
  }

  Widget _buildActionButton(int vagasDisponiveis) {
    if (_isOrganizador) {
      return ElevatedButton(onPressed: null, style: ElevatedButton.styleFrom(disabledBackgroundColor: Colors.grey[200]), child: const Text('VOCÊ ORGANIZA ESTA PARTIDA', style: TextStyle(color: Colors.grey)));
    }
    if (_isCurrentUserParticipant) {
      return OutlinedButton(
        onPressed: _isLeaving ? null : _performLeaveMatch, 
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 16)),
        child: _isLeaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) : const Text('SAIR DA PARTIDA', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    if (_isCurrentUserPending) {
       return ElevatedButton(onPressed: null, style: ElevatedButton.styleFrom(disabledBackgroundColor: Colors.orange[100]), child: Text('AGUARDANDO APROVAÇÃO', style: TextStyle(color: Colors.orange[800])));
    }
    if (vagasDisponiveis <= 0) {
      return const ElevatedButton(onPressed: null, child: Text('VAGAS ESGOTADAS'));
    }
    return ElevatedButton(
      onPressed: _isJoining ? null : _joinMatch, 
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: _isJoining ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('QUERO JOGAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  // --- CORREÇÃO AQUI: Recebe 'precoTotal' em vez de 'precoPorPessoa' ---
  Widget _buildInfoCard(Map<String, dynamic> match, double precoTotal) {
     final esporte = match['quadraData']?['esporte'] ?? 'N/D';
     final data = _formatTimestamp(match['startTime'], 'dd/MM (EEE)');
     final hora = '${_formatTimestamp(match['startTime'], 'HH:mm')} - ${_formatTimestamp(match['endTime'], 'HH:mm')}';
     // Formata o valor total
     final String preco = 'R\$ ${precoTotal.toStringAsFixed(2).replaceAll('.', ',')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailColumn(Icons.sports_soccer, 'Esporte', esporte),
          Container(height: 40, width: 1, color: Colors.grey[200]),
          _buildDetailColumn(Icons.calendar_month, data, hora),
          Container(height: 40, width: 1, color: Colors.grey[200]),
          // Atualizei o rótulo para 'Valor Total'
          _buildDetailColumn(Icons.attach_money, 'Valor Total', preco, isBold: true),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(IconData icon, String label, String value, {bool isBold = false}) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: isBold ? Colors.green[700] : Colors.black87)),
      ],
    );
  }

  Widget _buildParticipantsList(List<dynamic> participants) {
    if (participants.isEmpty) return const Text('Seja o primeiro a entrar!', style: TextStyle(color: Colors.grey));
    
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: participants.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final p = participants[index];
          final bool isOrg = p['id'] == _matchData!['organizadorId'];
          return Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: isOrg ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[200], child: Icon(Icons.person, color: isOrg ? AppTheme.primaryColor : Colors.grey)),
                  if (isOrg) Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.star, color: Colors.orange, size: 16))),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(width: 60, child: Text(p['nome'], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildRequestsList(List<dynamic> pendentes) {
    return Column(
      children: pendentes.map((user) => Card(
        elevation: 0, color: Colors.white,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: CircleAvatar(backgroundColor: Colors.grey[100], child: const Icon(Icons.person, color: Colors.grey)),
          title: Text(user['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _handleRequest(user['id'], true)),
              IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _handleRequest(user['id'], false)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  String _formatTimestamp(dynamic timestamp, String format) {
    DateTime? time;
    if (timestamp is Map && timestamp['_seconds'] != null) {
      time = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      time = DateTime.tryParse(timestamp);
    }
    return time != null ? DateFormat(format, 'pt_BR').format(time) : 'N/A';
  }
}