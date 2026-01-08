// lib/features/home/presentation/pages/all_courts_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/home/presentation/pages/court_details_page.dart';

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
          _filteredCourts = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar quadras');
      }
    } catch (e) {
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
      backgroundColor: Colors.grey[50], // Fundo moderno
      appBar: AppBar(
        title: const Text('Todas as Quadras', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87), // Seta preta
      ),
      body: Column(
        children: [
          // Barra de Pesquisa Estilizada
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterCourts,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, esporte ou bairro...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
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
              : _filteredCourts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Nenhuma quadra encontrada.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredCourts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final court = _filteredCourts[index];
                      
                      final courtId = court['id'] ?? 'unknown';
                      final nome = court['nome'] ?? 'Quadra sem nome';
                      final endereco = court['endereco'] ?? 'Endereço indisponível';
                      final esporte = court['esporte'] ?? 'Vários';
                      
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

                      return _VerticalCourtCard(
                        courtId: courtId, 
                        nome: nome, 
                        endereco: endereco, 
                        esporte: esporte, 
                        preco: preco
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Card Otimizado para Lista Vertical (Mais Detalhes)
class _VerticalCourtCard extends StatelessWidget {
  final String courtId, nome, endereco, esporte, preco;

  const _VerticalCourtCard({
    required this.courtId,
    required this.nome,
    required this.endereco,
    required this.esporte,
    required this.preco,
  });

  @override
  Widget build(BuildContext context) {
    // Imagem baseada no nome
    final imageUrl = 'https://placehold.co/400x200/2E7D32/FFFFFF/png?text=${Uri.encodeComponent(nome)}&font=roboto';

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
              builder: (context) => CourtDetailsPage(courtId: courtId, courtName: nome),
            ));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem Grande
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(height: 150, color: Colors.grey[100]);
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150, color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            nome,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textColor),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(preco, style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(endereco, style: TextStyle(color: Colors.grey[600], fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.sports_soccer, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(esporte, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}