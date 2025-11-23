// lib/features/chat/presentation/pages/chat_detail_page.dart
import 'package:flutter/material.dart';
// IMPORTS CORRIGIDOS:
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart'; 

// IMPORT LOCAL CORRIGIDO:
import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String title; 

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
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;

  StreamSubscription? _messagesSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _listenForMessages(); 
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _listenForMessages() {
    setState(() => _isLoading = true);

    final messagesStream = _firestore
        .collection('conversas')
        .doc(widget.chatId)
        .collection('mensagens')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();

    _messagesSubscription = messagesStream.listen((snapshot) {
      if (mounted) {
        final newMessages = snapshot.docs.map((doc) {
          final data = doc.data();
          final DateTime timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          return {
            'id': doc.id,
            'remetenteId': data['remetenteId'],
            'texto': data['texto'],
            'timestamp': timestamp,
          };
        }).toList().reversed.toList();

        setState(() {
          _messages = newMessages;
          _isLoading = false;
        });
        
        _scrollToBottom();
      }
    }, onError: (error) {
      if (mounted) {
        print('Erro ao ouvir mensagens: $error');
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      // Chamada da API REST para enviar a mensagem
      final url = Uri.parse('${AppConfig.apiUrl}/chats/${widget.chatId}/messages');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'texto': messageText,
        }),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['remetenteId'] == _currentUserId;
    final time = message['timestamp'] != null
        ? DateFormat('HH:mm').format(message['timestamp'] as DateTime)
        : '';
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(2),
            bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
               Text(
                 'Participante ${message['remetenteId']?.substring(0, 4) ?? 'Desconhecido'}', 
                 style: const TextStyle(fontSize: 10, color: AppTheme.textColor, fontWeight: FontWeight.bold)
               ),
            if (!isMe) const SizedBox(height: 4),
            
            Text(
              message['texto'] ?? '',
              style: TextStyle(color: isMe ? Colors.white : AppTheme.textColor),
            ),
            
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
      ),
    );
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
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? const Center(child: Text('Nenhuma mensagem. Comece a conversa!', style: TextStyle(color: AppTheme.hintColor)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 10, bottom: 5),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
          ),
          
          Container(
            padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8, top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5),
              ],
            ),
            child: SafeArea( 
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
                      onSubmitted: (_) => _sendMessage(),
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