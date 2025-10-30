// lib/features/home/presentation/pages/my_booking_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:http/http.dart' as http; // 1. Importar HTTP
import 'package:firebase_auth/firebase_auth.dart'; // 2. Importar Firebase Auth
import 'dart:convert'; // 3. Importar Dart Convert
import 'package:quadrafacil/core/config.dart'; // 4. Importar AppConfig

// 5. Convertido para StatefulWidget para gerenciar o estado de loading do cancelamento
class MyBookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const MyBookingDetailsPage({super.key, required this.booking});

  @override
  State<MyBookingDetailsPage> createState() => _MyBookingDetailsPageState();
}

class _MyBookingDetailsPageState extends State<MyBookingDetailsPage> {
  bool _isCancelling = false; // Estado de loading

  // Função que exibe o diálogo de confirmação
  Future<void> _showCancelConfirmationDialog(String bookingId) async {
    if (_isCancelling) return; // Não faz nada se já estiver cancelando

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar Reserva?'),
        content: const Text('Tem certeza que deseja cancelar esta reserva? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), // Fecha o diálogo
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Fecha o diálogo
              _performCancelBooking(bookingId); // Chama a função de API
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  // Função que realmente chama a API de cancelamento
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
        headers: {'Authorization': 'Bearer $idToken'}, // Envia o token
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada com sucesso!'), backgroundColor: Colors.green),
        );
        // Volta para a lista de "Minhas Reservas"
        Navigator.of(context).pop();
      } else {
        // Mostra o erro da API (ex: "Não é possível cancelar no mesmo dia")
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

  @override
  Widget build(BuildContext context) {
    // Acessa os dados do booking através do 'widget'
    final quadraNome = widget.booking['quadraNome'] ?? 'Quadra N/A';
    final endereco = widget.booking['quadraEndereco'] ?? 'Endereço não disponível';
    final preco = widget.booking['priceTotal'] != null
        ? 'R\$ ${widget.booking['priceTotal'].toStringAsFixed(2).replaceAll('.', ',')}'
        : 'Valor N/D';
    final status = widget.booking['status'] ?? 'N/A';
    final bookingId = widget.booking['id']; // ID real da reserva

    final DateTime? startTime = widget.booking['parsedStartTime'] as DateTime?;
    final dataFormatada = startTime != null
        ? DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR').format(startTime)
        : 'Data N/D';
    final horaFormatada = startTime != null
        ? DateFormat('HH:mm', 'pt_BR').format(startTime)
        : 'Hora N/D';

    // Determina se o botão de cancelar deve estar visível
    final bool canCancel = status.toLowerCase() != 'finalizada' && status.toLowerCase() != 'cancelada';

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

          // Botão de Cancelar
          if (canCancel)
            OutlinedButton.icon(
              onPressed: _isCancelling
                  ? null // Desabilita o botão durante o loading
                  : () => _showCancelConfirmationDialog(bookingId!), // Chama o diálogo
              icon: const Icon(Icons.cancel_outlined),
              label: _isCancelling
                  ? const SizedBox( // Mostra um spinner
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    )
                  : const Text('Cancelar Reserva'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  disabledForegroundColor: Colors.red.withOpacity(0.5) // Cor quando desabilitado
                  ),
            ),
        ],
      ),
    );
  }

  // Helper (sem alteração)
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