// lib/features/home/presentation/pages/all_courts_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/features/home/presentation/pages/athlete_home_page.dart'; // Para reutilizar o CourtCard

class AllCourtsPage extends StatefulWidget {
  const AllCourtsPage({super.key});

  @override
  State<AllCourtsPage> createState() => _AllCourtsPageState();
}

class _AllCourtsPageState extends State<AllCourtsPage> {
  final _allCourts = const [
    CourtCard(nome: 'Quadra Central', endereco: 'Centro, Passo Fundo', esporte: 'Futsal, Tênis', preco: 'R\$ 80/h'),
    CourtCard(nome: 'Arena Litoral', endereco: 'Boqueirão, Passo Fundo', esporte: 'Futevôlei, Vôlei', preco: 'R\$ 60/h'),
    CourtCard(nome: 'Ginásio Municipal', endereco: 'Vila Luiza, Passo Fundo', esporte: 'Basquete', preco: 'R\$ 90/h'),
  ];

  late List<CourtCard> _filteredCourts;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCourts = _allCourts;
    _searchController.addListener(_filterCourts);
  }

  void _filterCourts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCourts = _allCourts.where((court) {
        return court.nome.toLowerCase().contains(query) ||
               court.esporte.toLowerCase().contains(query);
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
        title: const Text('Todas as Quadras'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou esporte...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: _filteredCourts,
            ),
          ),
        ],
      ),
    );
  }
}