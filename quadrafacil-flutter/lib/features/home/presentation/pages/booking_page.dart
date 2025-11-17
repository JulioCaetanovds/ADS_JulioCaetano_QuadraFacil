// lib/features/home/presentation/pages/booking_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import para copiar para clipboard
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class BookingPage extends StatefulWidget {
  final String courtId;
  final String courtName;
  final DateTime selectedDate;
  final TimeOfDay selectedTimeSlot;
  final String? ownerPixKey; // 1. Recebe a chave PIX

  const BookingPage({
    super.key,
    required this.courtId,
    required this.courtName,
    required this.selectedDate,
    required this.selectedTimeSlot,
    this.ownerPixKey, // 2. Adiciona ao construtor
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _isLoading = false;
  double? _price; 

  @override
  void initState() {
    super.initState();
    // 3. Removemos o _fetchPrice(), pois já temos o preço na CourtDetailsPage
    //    Mas deixamos a função caso queira reutilizar
    _fetchPrice(); 
  }

  Future<void> _fetchPrice() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}/availability');
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        final availabilityData = jsonDecode(response.body);
        final dayKey = _getDayKey(widget.selectedDate); 
        final dayAvailability = availabilityData[dayKey];
        if (dayAvailability != null) {
          setState(() {
            _price = (dayAvailability['pricePerHour'] as num?)?.toDouble();
          });
        } else {
          print("Aviso: Não foi possível encontrar preço para o dia $dayKey.");
        }
      } else {
        print("Aviso: Falha ao buscar preço (${response.statusCode})");
      }

    } catch (e) {
      print("Erro ao buscar preço: $e");
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao buscar preço da reserva.'), backgroundColor: Colors.orange));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  String _getDayKey(DateTime date) {
    switch (date.weekday) {
      case 1: return 'segunda';
      case 2: return 'terca';
      case 3: return 'quarta';
      case 4: return 'quinta';
      case 5: return 'sexta';
      case 6: return 'sabado';
      case 7: return 'domingo';
      default: return '';
    }
  }


  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final localStartTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        widget.selectedTimeSlot.hour,
        widget.selectedTimeSlot.minute,
      );
      
      final startTimeUtc = localStartTime.toUtc();
      final endTimeUtc = startTimeUtc.add(const Duration(hours: 1)); 

      final url = Uri.parse('${AppConfig.apiUrl}/bookings');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'courtId': widget.courtId,
          'startTime': startTimeUtc.toIso8601String(),
          'endTime': endTimeUtc.toIso8601String(),
          'priceTotal': _price 
        }),
      );

        if (response.statusCode == 201 && mounted) {
        // 4. Texto do SnackBar atualizado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva solicitada! Pague o PIX e aguarde a confirmação do dono.'), backgroundColor: Colors.green),
        );
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);

        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Falha ao criar reserva.');
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


  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR').format(widget.selectedDate);
    final formattedStartTime = widget.selectedTimeSlot.format(context);
    final formattedEndTime = TimeOfDay(hour: widget.selectedTimeSlot.hour + 1, minute: widget.selectedTimeSlot.minute).format(context);
    final priceString = _price == null ? 'Buscando...' : 'R\$ ${_price!.toStringAsFixed(2).replaceAll('.', ',')}';
    
    // 5. Verifica se a chave PIX existe
    final bool hasPixKey = widget.ownerPixKey != null && widget.ownerPixKey!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Reserva'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 6. NOVO CARD DE INSTRUÇÕES DE PAGAMENTO (RF10)
            if (hasPixKey) ...[
              Card(
                color: AppTheme.primaryColor.withOpacity(0.05),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.primaryColor)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Instruções de Pagamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      const SizedBox(height: 12),
                      const Text('Para confirmar sua reserva, faça um PIX para a chave abaixo e clique em "Solicitar Confirmação".', style: TextStyle(height: 1.4)),
                      const SizedBox(height: 16),
                      Text('Chave PIX do Dono:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      // Campo da Chave PIX com botão de copiar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.ownerPixKey!, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: widget.ownerPixKey!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Chave PIX copiada!')),
                                );
                              },
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text('Resumo da sua Reserva:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16), // Diminuído
            Card(
              elevation: 2, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.store_outlined, 'Quadra', widget.courtName),
                    const Divider(height: 24, thickness: 1),
                    _buildInfoRow(Icons.calendar_today_outlined, 'Data', formattedDate),
                    const Divider(height: 24, thickness: 1),
                     _buildInfoRow(Icons.access_time_outlined, 'Horário', '$formattedStartTime - $formattedEndTime'),
                    const Divider(height: 24, thickness: 1),
                    _buildInfoRow(Icons.monetization_on_outlined, 'Valor (1 hora)', priceString),
                  ],
                ),
              ),
            ),
             const Spacer(),
             ElevatedButton(
              onPressed: _isLoading ? null : _confirmBooking,
              child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                // 7. Texto do botão atualizado
                : const Text('SOLICITAR CONFIRMAÇÃO'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.hintColor, size: 20),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: AppTheme.hintColor)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}