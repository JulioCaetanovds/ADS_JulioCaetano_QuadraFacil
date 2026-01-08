// lib/features/home/presentation/pages/open_matches_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/home/presentation/pages/match_details_page.dart';

class OpenMatchesPage extends StatefulWidget {
  const OpenMatchesPage({super.key});

  @override
  State<OpenMatchesPage> createState() => _OpenMatchesPageState();
}

class _OpenMatchesPageState extends State<OpenMatchesPage> {
  List<dynamic> _allMatches = [];
  List<dynamic> _filteredMatches = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/matches/public');
      final response = await http.get(url);

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _allMatches = data;
          _filteredMatches = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar partidas');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Erro ao carregar partidas.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterMatches(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredMatches = _allMatches.where((match) {
        final esporte = (match['esporte'] ?? '').toString().toLowerCase();
        final quadra = (match['quadraNome'] ?? '').toString().toLowerCase();
        
        return esporte.contains(lowerQuery) || quadra.contains(lowerQuery);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Partidas Abertas', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Busca
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterMatches,
              decoration: InputDecoration(
                hintText: 'Filtrar por esporte ou quadra...',
                prefixIcon: const Icon(Icons.filter_list, color: AppTheme.primaryColor),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredMatches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Nenhuma partida encontrada.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredMatches.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final match = _filteredMatches[index];
                      return _VerticalMatchCard(match: match);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VerticalMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const _VerticalMatchCard({required this.match});

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Data N/D';
    DateTime? date;
    if (timestamp is Map && timestamp['_seconds'] != null) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp);
    }
    
    if (date == null) return 'Data N/D';
    return DateFormat('dd/MM (EEE) • HH:mm', 'pt_BR').format(date).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final vagas = match['vagasDisponiveis'] ?? 0;
    final esporte = match['esporte'] ?? 'Esporte';
    final quadra = match['quadraNome'] ?? 'Quadra';
    final dataStr = _formatDate(match['startTime']);
    final matchId = match['id'];

    // Cor baseada nas vagas (Urgência)
    final Color vagasColor = vagas == 1 ? Colors.red : (vagas < 4 ? Colors.orange : Colors.green);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => MatchDetailsPage(matchId: matchId)
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topo: Esporte e Data
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sports_soccer, size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(esporte, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(dataStr, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Meio: Nome da Quadra e Info
                Text(quadra, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                const SizedBox(height: 4),
                Text('Organizado por ${match['organizadorNome'] ?? 'Alguém'}', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 16),
                
                // Rodapé: Vagas e Botão
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group, color: vagasColor, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '$vagas vagas restantes',
                          style: TextStyle(color: vagasColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}