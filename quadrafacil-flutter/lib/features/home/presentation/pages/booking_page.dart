// lib/features/home/presentation/pages/booking_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
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
  final String? ownerPixKey;

  const BookingPage({
    super.key,
    required this.courtId,
    required this.courtName,
    required this.selectedDate,
    required this.selectedTimeSlot,
    this.ownerPixKey,
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
        }
      } 
    } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao buscar preço.'), backgroundColor: Colors.redAccent));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva solicitada! Aguarde a confirmação.'), backgroundColor: Colors.green),
        );
        // Volta duas telas (para a home ou lista)
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);

        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Falha ao criar reserva.');
        }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
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
    final priceString = _price == null ? '...' : 'R\$ ${_price!.toStringAsFixed(2).replaceAll('.', ',')}';
    
    final bool hasPixKey = widget.ownerPixKey != null && widget.ownerPixKey!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Confirmar Reserva', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: SingleChildScrollView( // Adicionado para telas pequenas
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // 1. CARD DE RESUMO DA RESERVA
            const Text('Resumo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildSummaryRow(Icons.store_mall_directory, 'Quadra', widget.courtName, isBold: true),
                  const Divider(height: 32),
                  _buildSummaryRow(Icons.calendar_today, 'Data', formattedDate),
                  const SizedBox(height: 16),
                  _buildSummaryRow(Icons.access_time, 'Horário', '$formattedStartTime - $formattedEndTime'),
                  const Divider(height: 32),
                  _buildSummaryRow(Icons.attach_money, 'Total', priceString, color: Colors.green[700], isBold: true),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // 2. CARD DE PAGAMENTO (PIX)
            if (hasPixKey) ...[
              const Text('Pagamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08), // Fundo verde bem clarinho
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pix, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('Pagamento via PIX', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Faça a transferência para a chave abaixo e aguarde a confirmação do dono.', 
                        style: TextStyle(color: Colors.black87, height: 1.4)),
                    const SizedBox(height: 16),
                    
                    // Chave PIX Copiável
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: widget.ownerPixKey!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chave PIX copiada para a área de transferência!'), backgroundColor: Colors.green),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.ownerPixKey!, 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey[800]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy, size: 20, color: AppTheme.primaryColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(child: Text('Toque para copiar', style: TextStyle(fontSize: 12, color: Colors.grey))),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // 3. BOTÃO DE CONFIRMAÇÃO
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('SOLICITAR CONFIRMAÇÃO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.grey[600], size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Text(value, style: TextStyle(
                color: color ?? AppTheme.textColor, 
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 16)),
          ],
        )
      ],
    );
  }
}