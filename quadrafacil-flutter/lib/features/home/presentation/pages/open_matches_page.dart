// lib/features/home/presentation/pages/open_matches_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 1. Importar http
import 'dart:convert'; // 2. Importar convert
import 'package:intl/intl.dart'; // 3. Importar intl
import 'package:quadrafacil/core/config.dart'; // 4. Importar config

// 5. Importa o OpenMatchCard e a MatchDetailsPage
import 'package:quadrafacil/shared/widgets/open_match_card.dart';
import 'package:quadrafacil/features/home/presentation/pages/match_details_page.dart';

class OpenMatchesPage extends StatefulWidget {
  const OpenMatchesPage({super.key});

  @override
  State<OpenMatchesPage> createState() => _OpenMatchesPageState();
}

class _OpenMatchesPageState extends State<OpenMatchesPage> {
  // 6. Estados para loading e dados da API
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _allMatchesData = []; // Lista completa da API
  List<dynamic> _filteredMatchesData = []; // Lista para o filtro
  
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOpenMatches(); // 7. Busca dados da API ao iniciar
    _searchController.addListener(_filterMatches);
  }

  // 8. Função para buscar Partidas Abertas da API
  Future<void> _fetchOpenMatches() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/matches/public');
      final response = await http.get(url);

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _allMatchesData = data;
          _filteredMatchesData = data; // Popula as duas listas
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar partidas: ${response.body}');
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

  // 9. Função de filtro atualizada para chaves da API
  void _filterMatches() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMatchesData = _allMatchesData.where((match) {
        // Acessa os dados reais da API
        final quadra = match['quadraNome']?.toLowerCase() ?? '';
        final esporte = match['esporte']?.toLowerCase() ?? '';
        return quadra.contains(query) || esporte.contains(query);
      }).toList();
    });
  }

  // 10. Helper para formatar o horário (copiado da ExploreTab)
  String _formatMatchTime(dynamic timestamp) {
    DateTime? startTime;
    if (timestamp is Map && timestamp['_seconds'] != null) {
      startTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      startTime = DateTime.tryParse(timestamp);
    }

    if (startTime != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final dayOfMatch = DateTime(startTime.year, startTime.month, startTime.day);

      if (dayOfMatch == today) {
        return 'Hoje, ${DateFormat('HH:mm', 'pt_BR').format(startTime)}';
      } else if (dayOfMatch == tomorrow) {
        return 'Amanhã, ${DateFormat('HH:mm', 'pt_BR').format(startTime)}';
      } else {
        return DateFormat('E, dd/MM - HH:mm', 'pt_BR').format(startTime);
      }
    }
    return 'N/A';
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas as Partidas Abertas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por quadra ou esporte...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            // 11. Trata os estados de Loading e Erro
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _filteredMatchesData.isEmpty
                        ? const Center(child: Text("Nenhuma partida encontrada."))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _filteredMatchesData.length,
                            itemBuilder: (context, index) {
                              final matchData = _filteredMatchesData[index];
                              
                              // 12. Usa os dados reais da API
                              final vagas = matchData['vagasDisponiveis'] ?? 0;
                              final esporte = matchData['esporte'] ?? 'N/A';
                              final horario = _formatMatchTime(matchData['startTime']);
                              final quadra = matchData['quadraNome'] ?? 'N/A';
                              final matchId = matchData['id']; // ID da partida

                              return OpenMatchCard(
                                vagas: vagas,
                                esporte: esporte,
                                horario: horario,
                                quadra: quadra,
                                // 13. Adiciona o onTap para navegar
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => MatchDetailsPage(matchId: matchId)
                                  ));
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}