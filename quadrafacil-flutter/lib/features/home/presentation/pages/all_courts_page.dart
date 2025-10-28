import 'package:flutter/material.dart';
// Precisamos importar o CourtCard de onde ele está definido
import 'package:quadrafacil/features/home/presentation/pages/athlete_home_page.dart';

class AllCourtsPage extends StatefulWidget {
  const AllCourtsPage({super.key});

  @override
  State<AllCourtsPage> createState() => _AllCourtsPageState();
}

class _AllCourtsPageState extends State<AllCourtsPage> {
  // CORREÇÃO: Adicionamos 'courtId' a cada item da lista
  final List<CourtCard> _allCourts = const [
    CourtCard(courtId: 'Qdm9G1rO4kQEw03pNosK', nome: 'Quadra Central', endereco: 'Centro, Passo Fundo', esporte: 'Futsal, Tênis', preco: 'R\$ 80/h'),
    CourtCard(courtId: 'dummyIdArena', nome: 'Arena Litoral', endereco: 'Boqueirão, Passo Fundo', esporte: 'Futevôlei, Vôlei', preco: 'R\$ 60/h'),
    CourtCard(courtId: 'dummyIdGinasio', nome: 'Ginásio Municipal', endereco: 'Vila Luiza, Passo Fundo', esporte: 'Basquete', preco: 'R\$ 90/h'),
    // Adicione mais quadras aqui com seus IDs
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
        // A busca continua a mesma
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
            child: _filteredCourts.isEmpty // Adiciona mensagem se filtro não encontrar nada
              ? const Center(child: Text("Nenhuma quadra encontrada."))
              : ListView.builder( // Usamos ListView.builder para melhor performance com listas longas
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _filteredCourts.length,
                  itemBuilder: (context, index) {
                    // Retorna o próprio widget CourtCard que já está filtrado
                    return _filteredCourts[index];
                  }
                ),
          ),
        ],
      ),
    );
  }
}
