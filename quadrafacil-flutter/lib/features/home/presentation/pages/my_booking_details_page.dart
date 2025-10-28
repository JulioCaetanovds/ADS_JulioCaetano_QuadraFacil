import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
// 1. Importa o modelo compartilhado
import 'package:quadrafacil/shared/models/booking_data.dart';

// 2. Remove a definição duplicada da classe BookingData daqui
// class BookingData { ... }

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
                  // TODO: Buscar endereço real da quadra se necessário
                  const Text('Endereço da Quadra Aqui', style: TextStyle(color: AppTheme.hintColor)),
                  const SizedBox(height: 16),
                  const Divider(),
                  _buildDetailRow(icon: Icons.calendar_today_outlined, title: 'Data', value: booking.data),
                  _buildDetailRow(icon: Icons.access_time_outlined, title: 'Horário', value: booking.horario),
                   // TODO: Buscar valor real da reserva se necessário
                  _buildDetailRow(icon: Icons.receipt_long_outlined, title: 'Valor Pago', value: 'R\$ --,--'),
                  _buildDetailRow(icon: Icons.info_outline, title: 'Status', value: booking.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Botão de Cancelar (Apenas se não estiver finalizada ou cancelada)
          if (booking.status != 'Finalizada' && booking.status != 'Cancelada')
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implementar lógica de cancelamento (chamar API)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade de cancelamento em breve!')),
                );
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar Reserva'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            ),
        ],
      ),
    );
  }

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
