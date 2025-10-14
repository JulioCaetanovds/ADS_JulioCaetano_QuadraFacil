// lib/features/home/presentation/pages/booking_page.dart
import 'package:flutter/material.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar Horário'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Em breve, aqui você poderá selecionar a data e os horários disponíveis para esta quadra.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {},
                child: const Text('CONFIRMAR RESERVA'),
              )
            ],
          ),
        ),
      ),
    );
  }
}