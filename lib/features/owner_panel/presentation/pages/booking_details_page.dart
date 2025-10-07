// lib/features/owner_panel/presentation/pages/booking_details_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

// Criamos um objeto simples para passar os dados da reserva
class BookingData {
  final String quadra;
  final String cliente;
  final String horario;
  final String status;

  BookingData({required this.quadra, required this.cliente, required this.horario, required this.status});
}

class BookingDetailsPage extends StatefulWidget {
  final BookingData booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking.status;
  }

  void _changeStatus(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });
    // Aqui virá a lógica para salvar o novo status no banco de dados
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status alterado para $_currentStatus!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Reserva'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildDetailRow(icon: Icons.person_outline, title: 'Cliente', value: widget.booking.cliente),
          _buildDetailRow(icon: Icons.sports_soccer, title: 'Quadra', value: widget.booking.quadra),
          _buildDetailRow(icon: Icons.access_time, title: 'Horário', value: widget.booking.horario),
          _buildDetailRow(icon: Icons.info_outline, title: 'Status Atual', value: _currentStatus),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Alterar Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
          ),
          const SizedBox(height: 16),
          
          // Botões de Ação para o Dono
          if (_currentStatus == 'Pendente') ...[
            ElevatedButton.icon(
              onPressed: () => _changeStatus('Confirmada'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirmar Pagamento/Reserva'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _changeStatus('Cancelada'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar Reserva'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            ),
          ],
          
          if (_currentStatus == 'Confirmada') ...[
             OutlinedButton.icon(
              onPressed: () => _changeStatus('Cancelada'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar Reserva'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  // Widget auxiliar para as linhas de detalhe
  Widget _buildDetailRow({required IconData icon, required String title, required String value}) {
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
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}