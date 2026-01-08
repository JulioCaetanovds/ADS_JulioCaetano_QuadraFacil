// lib/features/owner_panel/presentation/pages/booking_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/chat/presentation/pages/chat_detail_page.dart'; 

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  late String _currentStatus;
  bool _isLoading = false; 
  bool _isAccessingChat = false; 

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking['status'] ?? 'N/A';
  }

  Future<void> _handleClientChat() async {
    if (_isAccessingChat) return;
    setState(() => _isAccessingChat = true);
    
    try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Dono não autenticado.');
        final idToken = await user.getIdToken(true);
        
        final bookingId = widget.booking['id']; 
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
            final chatTitle = widget.booking['userName'] ?? widget.booking['clienteNome'] ?? 'Cliente';

            if (mounted) {
                 Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatDetailPage(chatId: chatId, title: chatTitle)
                 ));
            }
        } else {
            final error = jsonDecode(response.body);
            throw Exception(error['message'] ?? 'Falha ao iniciar o chat.');
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

  Future<void> _updateBookingStatus(String action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final bookingId = widget.booking['id'];
    final newStatus = (action == 'confirm') ? 'confirmada' : 'cancelada';

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Dono não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/bookings/$bookingId/$action');
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _currentStatus = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reserva $newStatus com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao atualizar status.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatBookingTimestamp(dynamic timestamp) {
    DateTime? startTime;
    if (timestamp is Map && timestamp['_seconds'] != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      startTime = DateTime.tryParse(timestamp);
    }

    if (startTime != null) {
      return DateFormat('dd/MM/yy • HH:mm', 'pt_BR').format(startTime);
    }
    return 'N/A';
  }
  
  void _popWithResult() {
    final bool statusHasChanged = _currentStatus != widget.booking['status'];
    Navigator.of(context).pop(statusHasChanged);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada': return Colors.green[700]!;
      case 'pendente': return Colors.orange[800]!;
      case 'cancelada': return Colors.red[700]!;
      default: return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada': return Colors.green[50]!;
      case 'pendente': return Colors.orange[50]!;
      case 'cancelada': return Colors.red[50]!;
      default: return Colors.grey[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clienteNome = widget.booking['userName'] ?? 'Cliente N/A';
    final quadraNome = widget.booking['quadraNome'] ?? 'Quadra N/A';
    final horario = _formatBookingTimestamp(widget.booking['startTime']);
    final preco = widget.booking['priceTotal'] != null
        ? 'R\$ ${widget.booking['priceTotal'].toStringAsFixed(2).replaceAll('.', ',')}'
        : 'Valor N/D';
    final isConfirmed = _currentStatus.toLowerCase() == 'confirmada';
    final statusColor = _getStatusColor(_currentStatus);
    final statusBg = _getStatusBgColor(_currentStatus);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detalhes da Reserva', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _popWithResult, 
        ),
      ),
      body: PopScope( 
         canPop: false,
         onPopInvoked: (didPop) {
           if (!didPop) _popWithResult();
         },
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // 1. Card Principal com Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(_currentStatus.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  Text(clienteNome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                  const SizedBox(height: 4),
                  Text('Cliente', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const Divider(height: 32),
                  _buildDetailRow(icon: Icons.sports_soccer, title: 'Quadra', value: quadraNome),
                  _buildDetailRow(icon: Icons.access_time, title: 'Horário', value: horario),
                  _buildDetailRow(icon: Icons.monetization_on_outlined, title: 'Valor', value: preco, isBold: true, color: Colors.green[700]),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 2. Botão de Chat
            if (isConfirmed) 
               ElevatedButton.icon(
                  onPressed: _isAccessingChat ? null : _handleClientChat, 
                  icon: _isAccessingChat
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.chat_bubble_outline),
                  label: const Text('FALAR COM O CLIENTE'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
              ),

            const SizedBox(height: 32),
            
            // 3. Ações de Gestão
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_currentStatus.toLowerCase() == 'pendente') ...[
              const Text('Ações Pendentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateBookingStatus('confirm'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateBookingStatus('reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('RECUSAR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else if (_currentStatus.toLowerCase() == 'confirmada') ...[
              OutlinedButton.icon(
                onPressed: () => _updateBookingStatus('reject'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar Reserva (Reembolsar)'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.grey[600], size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color ?? AppTheme.textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}