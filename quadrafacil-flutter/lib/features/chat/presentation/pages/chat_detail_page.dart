// lib/features/chat/presentation/pages/chat_detail_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
// Import necessário para o próximo passo da API/Firebase

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String title; // Ex: "Chat da Partida" ou "Chat com Dono X"

  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.title,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  // TODO: Adicionar estados para lista de mensagens e loading

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // TODO: Chamar API POST /chats/:chatId/messages
    print('Mensagem enviada para ${widget.chatId}: $message');
    
    // Simula a adição da mensagem localmente para feedback
    // setState(() { /* Atualiza lista */ });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Área das Mensagens (Histórico)
          Expanded(
            child: Center(
              // TODO: Substituir por ListView.builder que carrega o histórico
              child: Text('Histórico do Chat ${widget.chatId}', style: TextStyle(color: AppTheme.hintColor)),
            ),
          ),
          
          // Área de Input (Composição)
          Container(
            padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8, top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5),
              ],
            ),
            child: SafeArea( // Garante que o input não fique sob a barra de navegação do celular
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _sendMessage(), // Envia com Enter
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}