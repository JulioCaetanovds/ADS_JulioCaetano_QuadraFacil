// lib/features/owner_panel/presentation/pages/booking_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  late String _currentStatus;
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking['status'] ?? 'N/A';
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
          SnackBar(
              content: Text('Reserva $newStatus com sucesso!'),
              backgroundColor: Colors.green),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao atualizar status.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBookingTimestamp(dynamic timestamp) {
    DateTime? startTime;
    if (timestamp is Map && timestamp['_seconds'] != null) {
      startTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      startTime = DateTime.tryParse(timestamp);
    }

    if (startTime != null) {
      return DateFormat('dd/MM/yy (EEEE) • HH:mm', 'pt_BR').format(startTime);
    }
    return 'N/A';
  }
  
  // Função helper para encapsular a lógica de "voltar"
  void _popWithResult() {
    // Retorna 'true' se o status tiver sido alterado, 'false' caso contrário
    final bool statusHasChanged = _currentStatus != widget.booking['status'];
    Navigator.of(context).pop(statusHasChanged);
  }


  @override
  Widget build(BuildContext context) {
    final clienteNome = widget.booking['userName'] ?? 'Cliente N/A';
    final quadraNome = widget.booking['quadraNome'] ?? 'Quadra N/A';
    final horario = _formatBookingTimestamp(widget.booking['startTime']);
    final preco = widget.booking['priceTotal'] != null
        ? 'R\$ ${widget.booking['priceTotal'].toStringAsFixed(2).replaceAll('.', ',')}'
        : 'Valor N/D';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Reserva'),
        // O botão da setinha agora chama a função helper
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _popWithResult, // Chama a função helper
        ),
      ),
      // ---- CORREÇÃO AQUI ----
      body: PopScope( 
         // 1. Intercepta o pop do sistema
         canPop: false,
         // 2. didPop será 'false' porque interceptamos
         onPopInvoked: (didPop) {
           if (!didPop) { 
             // 3. Executa nossa lógica de pop manualmente
             _popWithResult();
           }
         },
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildDetailRow(
                icon: Icons.person_outline,
                title: 'Cliente',
                value: clienteNome),
            _buildDetailRow(
                icon: Icons.sports_soccer, title: 'Quadra', value: quadraNome),
            _buildDetailRow(
                icon: Icons.access_time, title: 'Horário', value: horario),
            _buildDetailRow(
                icon: Icons.monetization_on_outlined, title: 'Valor', value: preco), 
            _buildDetailRow(
                icon: Icons.info_outline,
                title: 'Status Atual',
                value: _currentStatus.toUpperCase()),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Alterar Status',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor),
            ),
            const SizedBox(height: 16),
            
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_currentStatus.toLowerCase() == 'pendente') ...[
              ElevatedButton.icon(
                onPressed: () => _updateBookingStatus('confirm'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmar Pagamento/Reserva'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _updateBookingStatus('reject'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Recusar Reserva'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red)),
              ),
            ] else if (_currentStatus.toLowerCase() == 'confirmada') ...[
              OutlinedButton.icon(
                onPressed: () => _updateBookingStatus('reject'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar Reserva (Reembolsar)'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red)),
              ),
            ] else ... [
              Text('Esta reserva não pode mais ser alterada.', 
                style: TextStyle(color: AppTheme.hintColor),
                textAlign: TextAlign.center,
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      {required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.hintColor)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}