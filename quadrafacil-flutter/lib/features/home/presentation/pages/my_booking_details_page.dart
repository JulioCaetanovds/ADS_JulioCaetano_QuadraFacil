// lib/features/home/presentation/pages/my_booking_details_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

// Usaremos a mesma classe de dados de antes para passar a informação
class BookingData {
  final String quadra;
  final String data;
  final String horario;
  final String status;

  BookingData({required this.quadra, required this.data, required this.horario, required this.status});
}

class MyBookingDetailsPage extends StatelessWidget {
  final BookingData booking;

  const MyBookingDetailsPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Reserva'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Card principal com as informações
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.quadra,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Centro, Passo Fundo - RS', style: TextStyle(color: AppTheme.hintColor)), // Endereço de exemplo
                  const SizedBox(height: 16),
                  const Divider(),
                  _buildDetailRow(icon: Icons.calendar_today_outlined, title: 'Data', value: booking.data),
                  _buildDetailRow(icon: Icons.access_time_outlined, title: 'Horário', value: booking.horario),
                  _buildDetailRow(icon: Icons.receipt_long_outlined, title: 'Valor Pago', value: 'R\$ 80,00'), // Valor de exemplo
                  _buildDetailRow(icon: Icons.info_outline, title: 'Status', value: booking.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Botões de Ação para o Atleta
          if (booking.status != 'Finalizada' && booking.status != 'Cancelada')
            OutlinedButton.icon(
              onPressed: () {
                // Lógica para cancelar a reserva
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar Reserva'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  // Widget auxiliar para as linhas de detalhe
  Widget _buildDetailRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.hintColor, size: 20),
          const SizedBox(width: 16),
          Text(title),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}