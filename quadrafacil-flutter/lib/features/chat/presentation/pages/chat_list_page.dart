// lib/features/chat/presentation/pages/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/chat/presentation/pages/chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool _isLoading = true;
  List<dynamic> _chats = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    if (!mounted) return;
    // Só mostra loading full screen se a lista estiver vazia
    if (_chats.isEmpty) setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/chats');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $idToken'});

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _chats = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar conversas.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar mensagens.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  String _formatLastMessageTime(Map<String, dynamic> ultimaMensagem) {
    if (ultimaMensagem['timestamp'] == null || ultimaMensagem['timestamp']['_seconds'] == null) {
      return '';
    }
    final timestamp = ultimaMensagem['timestamp']['_seconds'] * 1000;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
      return DateFormat('HH:mm').format(dateTime); // Hoje
    } else if (dateTime.year == now.year) {
      return DateFormat('dd/MM').format(dateTime); // Este ano
    } else {
      return DateFormat('dd/MM/yy').format(dateTime); // Antigo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Minhas Mensagens', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            TextButton(onPressed: _fetchChats, child: const Text('Tentar novamente'))
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Nenhuma conversa encontrada.', style: TextStyle(color: AppTheme.hintColor, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchChats,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _chats.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 80), // Divisor estilo WhatsApp
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final ultimaMensagem = chat['ultimaMensagem'] ?? {};
          final otherUserName = chat['otherUserName'] ?? 'Usuário';
          final chatId = chat['chatId'];
          
          // Lógica para Avatar (Iniciais)
          String initials = otherUserName.length > 0 ? otherUserName[0].toUpperCase() : '?';
          if (otherUserName.contains(' ')) {
             final parts = otherUserName.split(' ');
             if (parts.length > 1 && parts[1].isNotEmpty) initials += parts[1][0].toUpperCase();
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(initials, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(
              otherUserName, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                ultimaMensagem['texto'] ?? 'Inicie a conversa...', 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatLastMessageTime(ultimaMensagem),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 6),
                // Badge de "Não lido" (Opcional/Futuro - deixei invisível por enquanto)
                // Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatDetailPage(chatId: chatId, title: otherUserName)
              )).then((_) => _fetchChats()); // Atualiza a lista ao voltar
            },
          );
        },
      ),
    );
  }
}