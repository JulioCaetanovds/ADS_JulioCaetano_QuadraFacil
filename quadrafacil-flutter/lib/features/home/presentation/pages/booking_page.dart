// lib/features/home/presentation/pages/booking_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class BookingPage extends StatefulWidget {
  // 1. Define os parâmetros que a página vai receber
  final String courtId;
  final String courtName;
  final DateTime selectedDate;
  final TimeOfDay selectedTimeSlot;

  // 2. Atualiza o construtor para receber e exigir os parâmetros
  const BookingPage({
    super.key,
    required this.courtId,
    required this.courtName,
    required this.selectedDate,
    required this.selectedTimeSlot,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _isLoading = false;
  double? _price; // Para guardar o preço buscado da disponibilidade

  @override
  void initState() {
    super.initState();
    _fetchPrice(); // Busca o preço ao iniciar a tela
  }

  // Busca o preço na API de disponibilidade
  Future<void> _fetchPrice() async {
    setState(() => _isLoading = true); // Reutiliza o loading
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}/availability');
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        final availabilityData = jsonDecode(response.body);
        final dayKey = _getDayKey(widget.selectedDate); // Usa a mesma função helper
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

  // Função helper para chave do dia (pode ser movida para utils)
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

      // ---- CORREÇÃO DO FUSO HORÁRIO ----
      // 1. Cria o DateTime local "naive" (como era antes)
      final localStartTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        widget.selectedTimeSlot.hour,
        widget.selectedTimeSlot.minute,
      );
      
      // 2. Converte o DateTime local para UTC
      final startTimeUtc = localStartTime.toUtc();
      final endTimeUtc = startTimeUtc.add(const Duration(hours: 1)); 
      // ------------------------------------

      final url = Uri.parse('${AppConfig.apiUrl}/bookings');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'courtId': widget.courtId,
          // 3. Envia a string ISO 8601 em UTC (ex: "....Z")
          'startTime': startTimeUtc.toIso8601String(),
          'endTime': endTimeUtc.toIso8601String(),
          // Poderíamos enviar o preço aqui também se a API precisar
          'precoTotal': _price 
        }),
      );

        if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva solicitada! Aguardando pagamento.'), backgroundColor: Colors.green),
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
    final formattedStartTime = widget.selectedTimeSlot.format(context); // Usa formatação local
    final formattedEndTime = TimeOfDay(hour: widget.selectedTimeSlot.hour + 1, minute: widget.selectedTimeSlot.minute).format(context);
    final priceString = _price == null ? 'Buscando...' : 'R\$ ${_price!.toStringAsFixed(2).replaceAll('.', ',')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Reserva'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumo da sua Reserva:', style: Theme.of(context).textTheme.titleLarge), // Estilo atualizado
            const SizedBox(height: 24),
            Card(
              elevation: 2, // Sombra suave
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
                : const Text('CONFIRMAR E IR PARA PAGAMENTO'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding( // Adiciona padding para melhor espaçamento
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