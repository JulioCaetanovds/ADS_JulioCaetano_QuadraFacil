// lib/features/home/presentation/pages/my_booking_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:quadrafacil/core/config.dart';
// 1. Importa as telas de destino (MatchDetailsPage e ChatDetailPage)
import 'package:quadrafacil/features/home/presentation/pages/match_details_page.dart';
import 'package:quadrafacil/features/chat/presentation/pages/chat_detail_page.dart'; 

class MyBookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const MyBookingDetailsPage({super.key, required this.booking});

  @override
  State<MyBookingDetailsPage> createState() => _MyBookingDetailsPageState();
}

class _MyBookingDetailsPageState extends State<MyBookingDetailsPage> {
  bool _isCancelling = false;
  bool _isOpeningMatch = false;
  bool _isAccessingChat = false; // Estado de loading para o chat
  
  String? _partidaAbertaId; 
  final _vagasController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _partidaAbertaId = widget.booking['partidaAbertaId'];
  }

  @override
  void dispose() {
    _vagasController.dispose();
    super.dispose();
  }

  // --- Lógica do Chat de Grupo (RF11) ---
  Future<void> _handleMatchChat() async {
    if (_isAccessingChat) return;
    setState(() => _isAccessingChat = true);

    try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Usuário não autenticado.');
        final idToken = await user.getIdToken(true);

        // A. Chama a API POST para criar ou buscar o Chat de Grupo
        final url = Uri.parse('${AppConfig.apiUrl}/chats/match/${_partidaAbertaId!}');
        final response = await http.post(
            url,
            headers: {
                'Authorization': 'Bearer $idToken',
                'Content-Type': 'application/json',
            },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
            final responseData = jsonDecode(response.body);
            final chatId = responseData['chatId'];
            final chatTitle = widget.booking['quadraNome'] ?? 'Chat da Partida';

            if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat pronto! Abrindo conversa...')),
                );
                // B. NAVEGAÇÃO PARA A TELA DE CHAT
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatDetailPage(chatId: chatId, title: chatTitle)
                ));
            }
        } else {
            final error = jsonDecode(response.body);
            throw Exception(error['message'] ?? 'Falha ao iniciar o chat de grupo.');
        }

    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
            );
        }
    } finally {
        if (mounted) setState(() => _isAccessingChat = false);
    }
}

Future<void> _handleOwnerChat() async {
    if (_isAccessingChat) return;
    setState(() => _isAccessingChat = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);
      final bookingId = widget.booking['id']; // Pega o ID da reserva

      // A. Chama a API POST correta para chat de Reserva
      final url = Uri.parse('${AppConfig.apiUrl}/chats/booking/$bookingId');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final chatId = responseData['chatId'];
        // Nome da tela será o nome da Quadra
        final chatTitle = widget.booking['quadraNome'] ?? 'Falar com o Dono';

        if (mounted) {
           // B. NAVEGAÇÃO PARA A TELA DE CHAT
           Navigator.of(context).push(MaterialPageRoute(
             builder: (context) => ChatDetailPage(chatId: chatId, title: chatTitle)
           ));
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao iniciar chat com o dono.');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAccessingChat = false);
    }
  }

  Future<void> _showCancelConfirmationDialog(String bookingId) async {
    if (_isCancelling) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar Reserva?'),
        content: const Text('Tem certeza que deseja cancelar esta reserva? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performCancelBooking(bookingId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancelBooking(String bookingId) async {
    if (!mounted) return;
    setState(() => _isCancelling = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/bookings/$bookingId');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao cancelar reserva.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }
  
  Future<void> _showOpenMatchDialog(String bookingId) async {
    if (_isOpeningMatch) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abrir Partida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quantas vagas (jogadores) você quer disponibilizar para a comunidade?'),
            const SizedBox(height: 16),
            TextField(
              controller: _vagasController,
              decoration: const InputDecoration(
                labelText: 'Número de vagas',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              final vagas = int.tryParse(_vagasController.text);
              if (vagas != null && vagas > 0) {
                Navigator.of(dialogContext).pop();
                _performOpenMatch(bookingId, vagas); 
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, insira um número de vagas válido.'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Abrir Partida'),
          ),
        ],
      ),
    );
  }

  Future<void> _performOpenMatch(String bookingId, int vagasAbertas) async {
    if (!mounted) return;
    setState(() => _isOpeningMatch = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/matches/open');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'bookingId': bookingId,
          'vagasAbertas': vagasAbertas,
        }),
      );

      if (response.statusCode == 201 && mounted) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _partidaAbertaId = responseData['matchId']; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partida aberta com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao abrir partida.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningMatch = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quadraNome = widget.booking['quadraNome'] ?? 'Quadra N/A';
    final endereco = widget.booking['quadraEndereco'] ?? 'Endereço não disponível';
    final preco = widget.booking['priceTotal'] != null
        ? 'R\$ ${widget.booking['priceTotal'].toStringAsFixed(2).replaceAll('.', ',')}'
        : 'Valor N/D';
    final status = widget.booking['status'] ?? 'N/A';
    final bookingId = widget.booking['id'];

    final DateTime? startTime = widget.booking['parsedStartTime'] as DateTime?;
    final dataFormatada = startTime != null
        ? DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR').format(startTime)
        : 'Data N/D';
    final horaFormatada = startTime != null
        ? DateFormat('HH:mm', 'pt_BR').format(startTime)
        : 'Hora N/D';

    final bool isBookingConfirmed = status.toLowerCase() == 'confirmada';
    final bool isBookingInFuture = startTime != null && startTime.isAfter(DateTime.now());
    final bool isMatchAlreadyOpen = _partidaAbertaId != null;
    final bool canCancel = status.toLowerCase() != 'finalizada' && status.toLowerCase() != 'cancelada';
    
    final bool canOpenMatch = isBookingConfirmed && isBookingInFuture && !isMatchAlreadyOpen;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Reserva'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quadraNome,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      endereco,
                      style: const TextStyle(color: AppTheme.hintColor)),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  _buildDetailRow(icon: Icons.calendar_today_outlined, title: 'Data', value: dataFormatada),
                  _buildDetailRow(icon: Icons.access_time_outlined, title: 'Horário', value: horaFormatada),
                  _buildDetailRow(
                      icon: Icons.receipt_long_outlined,
                      title: 'Valor',
                      value: preco),
                  _buildDetailRow(icon: Icons.info_outline, title: 'Status', value: status.toUpperCase()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // --- Lógica de Botões ATUALIZADA ---
          
          // 1. Botão para ABRIR (Criar) Partida
          if (canOpenMatch)
            ElevatedButton.icon(
              onPressed: _isOpeningMatch 
                ? null 
                : () => _showOpenMatchDialog(bookingId!),
              icon: _isOpeningMatch
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.group_add_outlined),
              label: const Text('Procurar Jogadores (Abrir Partida)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white
              ),
            ),
          const SizedBox(height: 12), // Espaçamento

          // 2. Botão de CHAT (Visível se a reserva estiver confirmada - Chat Dono/Atleta)
          if (isBookingConfirmed)
             ElevatedButton.icon(
               onPressed: _isAccessingChat ? null : _handleOwnerChat, 
               icon: _isAccessingChat
                   ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                   : const Icon(Icons.chat_bubble_outline),
               label: const Text('CHAT COM O DONO DA QUADRA'),
               style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
             ),
          
          const SizedBox(height: 12), // Espaçamento

          // 3. Botão para GERENCIAR Partida (Se já foi aberta)
          if (isMatchAlreadyOpen)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green)
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Esta partida está aberta!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // --- CORREÇÃO: Usamos o Botão para ir para a tela de Partida ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                       // Navega para a MatchDetailsPage usando o ID da partida
                       Navigator.of(context).push(MaterialPageRoute(
                         builder: (context) => MatchDetailsPage(matchId: _partidaAbertaId!)
                       ));
                    },
                    icon: const Icon(Icons.settings, color: AppTheme.primaryColor),
                    label: const Text('GERENCIAR PARTIDA / VER SOLICITAÇÕES'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor
                    ),
                  ),
                ),
              ],
            ),

          if (canOpenMatch || isMatchAlreadyOpen || canCancel)
            const SizedBox(height: 12),

          if (canCancel)
            OutlinedButton.icon(
              onPressed: _isCancelling || _isOpeningMatch 
                  ? null
                  : () => _showCancelConfirmationDialog(bookingId!),
              icon: const Icon(Icons.cancel_outlined),
              label: _isCancelling
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    )
                  : const Text('Cancelar Reserva'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  disabledForegroundColor: Colors.red.withOpacity(0.5)
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.hintColor, size: 20),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: AppTheme.hintColor)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        ],
      ),
    );
  }
}