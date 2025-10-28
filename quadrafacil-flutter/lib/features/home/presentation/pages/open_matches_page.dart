import 'package:flutter/material.dart';
// 1. Importa o OpenMatchCard do local compartilhado correto
import 'package:quadrafacil/shared/widgets/open_match_card.dart';

class OpenMatchesPage extends StatefulWidget {
  const OpenMatchesPage({super.key});

  @override
  State<OpenMatchesPage> createState() => _OpenMatchesPageState();
}

class _OpenMatchesPageState extends State<OpenMatchesPage> {
  // 2. Guarda os dados como uma lista de Mapas
  final List<Map<String, dynamic>> _allMatchesData = const [
    {'vagas': 2, 'esporte': 'Futsal', 'horario': '20:00', 'quadra': 'Quadra Central'},
    {'vagas': 3, 'esporte': 'Vôlei', 'horario': '19:00', 'quadra': 'Arena Litoral'},
    {'vagas': 1, 'esporte': 'Basquete', 'horario': '21:00', 'quadra': 'Ginásio Municipal'},
    {'vagas': 5, 'esporte': 'Futsal', 'horario': '22:00', 'quadra': 'Quadra Central'},
    // Adicione mais partidas aqui
  ];

  // A lista filtrada também conterá Mapas
  late List<Map<String, dynamic>> _filteredMatchesData;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredMatchesData = _allMatchesData;
    _searchController.addListener(_filterMatches);
  }

  // 3. Função de filtro atualizada para trabalhar com Mapas
  void _filterMatches() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMatchesData = _allMatchesData.where((match) {
        // Acessa os dados dentro do Mapa
        final quadra = match['quadra']?.toLowerCase() ?? '';
        final esporte = match['esporte']?.toLowerCase() ?? '';
        return quadra.contains(query) || esporte.contains(query);
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
            child: _filteredMatchesData.isEmpty
                ? const Center(child: Text("Nenhuma partida encontrada."))
                // 4. ListView.builder cria os widgets OpenMatchCard dinamicamente
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredMatchesData.length,
                    itemBuilder: (context, index) {
                      final matchData = _filteredMatchesData[index];
                      // Cria o widget passando os dados do Mapa
                      return OpenMatchCard(
                        vagas: matchData['vagas'] ?? 0,
                        esporte: matchData['esporte'] ?? 'N/A',
                        horario: matchData['horario'] ?? 'N/A',
                        quadra: matchData['quadra'] ?? 'N/A',
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
