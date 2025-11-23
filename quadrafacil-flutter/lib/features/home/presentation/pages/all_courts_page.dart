// lib/features/home/presentation/pages/all_courts_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
// Importamos o CourtCard da home (ou de onde você definiu o widget)
import 'package:quadrafacil/features/home/presentation/pages/athlete_home_page.dart';

class AllCourtsPage extends StatefulWidget {
  const AllCourtsPage({super.key});

  @override
  State<AllCourtsPage> createState() => _AllCourtsPageState();
}

class _AllCourtsPageState extends State<AllCourtsPage> {
  List<dynamic> _allCourts = [];
  List<dynamic> _filteredCourts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCourts();
  }

  Future<void> _fetchCourts() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/courts/public');
      final response = await http.get(url);

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _allCourts = data;
          _filteredCourts = data; // Inicialmente, todos são exibidos
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar quadras');
      }
    } catch (e) {
      print('Erro ao buscar quadras: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Erro ao carregar quadras.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterCourts(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredCourts = _allCourts.where((court) {
        final nome = (court['nome'] ?? '').toString().toLowerCase();
        final esporte = (court['esporte'] ?? '').toString().toLowerCase();
        final endereco = (court['endereco'] ?? '').toString().toLowerCase();
        
        return nome.contains(lowerQuery) || 
               esporte.contains(lowerQuery) ||
               endereco.contains(lowerQuery);
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
        backgroundColor: AppTheme.primaryColor, // Opcional: manter padrão
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCourts, // Filtra enquanto digita
              decoration: const InputDecoration(
                hintText: 'Buscar por nome, esporte ou endereço...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCourts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppTheme.hintColor),
                        SizedBox(height: 8),
                        Text("Nenhuma quadra encontrada.", 
                          style: TextStyle(color: AppTheme.hintColor)
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredCourts.length,
                    itemBuilder: (context, index) {
                      final court = _filteredCourts[index];
                      
                      // Lógica de extração de dados (igual à Home)
                      final courtId = court['id'] ?? 'unknown';
                      final nome = court['nome'] ?? 'Quadra sem nome';
                      final endereco = court['endereco'] ?? 'Endereço indisponível';
                      final esporte = court['esporte'] ?? 'Vários';
                      
                      // Lógica de Preço
                      String pricePerHourStr = 'N/D';
                      if (court['availability'] is Map) {
                        final availabilityMap = court['availability'] as Map<String, dynamic>;
                        for (var dayData in availabilityMap.values) {
                          if (dayData is Map && dayData['pricePerHour'] != null) {
                            pricePerHourStr = dayData['pricePerHour']?.toStringAsFixed(2)?.replaceAll('.', ',') ?? 'N/D';
                            break;
                          }
                        }
                      }
                      final preco = 'R\$ $pricePerHourStr/h';

                      // Ajuste de largura para ocupar a tela toda na lista vertical
                      return SizedBox(
                      width: double.infinity,
                      height: 220, // <--- ADICIONE ESTA ALTURA FIXA (Obrigatório)
                      child: CourtCard(
                        courtId: courtId, 
                        nome: nome, 
                        endereco: endereco, 
                        esporte: esporte, 
                        preco: preco
                      ),
                    );
                  },
                  ),
          ),
        ],
      ),
    );
  }
}