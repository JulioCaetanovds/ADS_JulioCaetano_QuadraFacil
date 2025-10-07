// lib/features/home/presentation/pages/open_matches_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/features/home/presentation/pages/athlete_home_page.dart'; // Reutilizaremos o OpenMatchCard

class OpenMatchesPage extends StatefulWidget {
  const OpenMatchesPage({super.key});

  @override
  State<OpenMatchesPage> createState() => _OpenMatchesPageState();
}

class _OpenMatchesPageState extends State<OpenMatchesPage> {
  final _allMatches = const [
    OpenMatchCard(vagas: 2, esporte: 'Futsal', horario: '20:00', quadra: 'Quadra Central'),
    OpenMatchCard(vagas: 3, esporte: 'Vôlei', horario: '19:00', quadra: 'Arena Litoral'),
    OpenMatchCard(vagas: 1, esporte: 'Basquete', horario: '21:00', quadra: 'Ginásio Municipal'),
    OpenMatchCard(vagas: 5, esporte: 'Futsal', horario: '22:00', quadra: 'Quadra Central'),
  ];

  late List<OpenMatchCard> _filteredMatches;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredMatches = _allMatches;
    _searchController.addListener(_filterMatches);
  }

  void _filterMatches() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMatches = _allMatches.where((match) {
        return match.quadra.toLowerCase().contains(query) ||
               match.esporte.toLowerCase().contains(query);
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
              decoration: InputDecoration(
                hintText: 'Buscar por quadra ou esporte...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: _filteredMatches,
            ),
          ),
        ],
      ),
    );
  }
}