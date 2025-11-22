import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
// TODO: Importar ChatDetailPage aqui

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
    setState(() => _isLoading = true);

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
        throw Exception('Falha ao carregar conversas: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }
  
  // Helper para formatar a data da última mensagem
  String _formatLastMessageTime(Map<String, dynamic> ultimaMensagem) {
    if (ultimaMensagem['timestamp'] == null || ultimaMensagem['timestamp']['_seconds'] == null) {
      return '';
    }
    final timestamp = ultimaMensagem['timestamp']['_seconds'] * 1000;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
      return DateFormat('HH:mm').format(dateTime); // Hoje
    } else {
      return DateFormat('dd/MM/yy').format(dateTime); // Outros dias
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Mensagens')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchChats,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text('Erro: $_errorMessage', style: const TextStyle(color: Colors.red)),
      );
    }

    if (_chats.isEmpty) {
      return const Center(
        child: Text('Nenhuma conversa encontrada.', style: TextStyle(color: AppTheme.hintColor)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchChats,
      child: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final ultimaMensagem = chat['ultimaMensagem'] ?? {};
          
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(chat['otherUserName'] ?? 'Usuário Desconhecido', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(ultimaMensagem['texto'] ?? 'Nova conversa', overflow: TextOverflow.ellipsis),
            trailing: Text(_formatLastMessageTime(ultimaMensagem)),
            onTap: () {
              // TODO: Navegar para ChatDetailPage, passando chat.chatId
            },
          );
        },
      ),
    );
  }
}