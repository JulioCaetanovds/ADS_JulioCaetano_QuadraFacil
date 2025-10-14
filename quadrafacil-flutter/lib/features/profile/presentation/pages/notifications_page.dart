// lib/features/profile/presentation/pages/notifications_page.dart
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Variáveis de estado para controlar os switches
  bool _newParticipantNotifications = true;
  bool _bookingConfirmationNotifications = true;
  bool _chatNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Novo participante na partida'),
            subtitle: const Text('Receber alerta quando alguém entrar no seu jogo.'),
            value: _newParticipantNotifications,
            onChanged: (bool value) {
              setState(() {
                _newParticipantNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Confirmação de reserva'),
            subtitle: const Text('Ser notificado quando o dono confirmar seu horário.'),
            value: _bookingConfirmationNotifications,
            onChanged: (bool value) {
              setState(() {
                _bookingConfirmationNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Novas mensagens no chat'),
            subtitle: const Text('Alertas para mensagens não lidas.'),
            value: _chatNotifications,
            onChanged: (bool value) {
              setState(() {
                _chatNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }
}