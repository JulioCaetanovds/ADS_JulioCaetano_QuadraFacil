// lib/features/home/presentation/pages/athlete_home_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Para formatar datas

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/login_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/all_courts_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/court_details_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/match_details_page.dart'; // Import da tela de detalhes da partida
import 'package:quadrafacil/features/home/presentation/pages/my_booking_details_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/open_matches_page.dart';
import 'package:quadrafacil/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:quadrafacil/features/profile/presentation/pages/notifications_page.dart';
import 'package:quadrafacil/features/profile/presentation/pages/security_page.dart';
import 'package:quadrafacil/shared/widgets/open_match_card.dart';

// ABA MINHAS RESERVAS (RF07)
// ... (Nenhuma alteração nesta classe, mantenha seu código da MyBookingsTab como está)
class MyBookingsTab extends StatefulWidget {
  const MyBookingsTab({super.key});

  @override
  State<MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<MyBookingsTab> {
  List<dynamic> _upcomingBookings = [];
  List<dynamic> _historyBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAthleteBookings();
  }

  Future<void> _fetchAthleteBookings() async {
    if (!mounted) return;
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/bookings/athlete');
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $idToken'});

      if (response.statusCode == 200) {
        if (mounted) {
          final allBookings = jsonDecode(response.body) as List;
          final now = DateTime.now();
          final upcoming = <dynamic>[];
          final history = <dynamic>[];

          for (var booking in allBookings) {
            DateTime? startTime;
            if (booking['startTime'] is Map &&
                booking['startTime']['_seconds'] != null) {
              startTime = DateTime.fromMillisecondsSinceEpoch(
                  booking['startTime']['_seconds'] * 1000);
            } else if (booking['startTime'] is String) {
              startTime = DateTime.tryParse(booking['startTime']);
            }

            booking['parsedStartTime'] = startTime;

            if (startTime != null && startTime.isAfter(now)) {
              upcoming.add(booking);
            } else {
              history.add(booking);
            }
          }

          upcoming.sort((a, b) => (a['parsedStartTime'] ?? DateTime(0))
              .compareTo(b['parsedStartTime'] ?? DateTime(0)));
          history.sort((a, b) => (b['parsedStartTime'] ?? DateTime(0))
              .compareTo(a['parsedStartTime'] ?? DateTime(0)));

          setState(() {
            _upcomingBookings = upcoming;
            _historyBookings = history;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Falha ao carregar minhas reservas: ${response.body}');
      }
    } catch (e) {
      print('Erro ao buscar reservas do atleta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBookingListItemTime(DateTime? dateTime) {
    if (dateTime != null) {
      return DateFormat('dd/MM/yy HH:mm', 'pt_BR').format(dateTime);
    }
    return 'Data inválida';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Reservas'),
          bottom: const TabBar(
            tabs: [Tab(text: 'PRÓXIMOS JOGOS'), Tab(text: 'HISTÓRICO')],
            labelColor: AppTheme.primaryColor,
            indicatorColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.hintColor,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBookingList(
                      _upcomingBookings, 'Nenhum jogo agendado.'),
                  _buildBookingList(
                      _historyBookings, 'Nenhum histórico de jogos.'),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchAthleteBookings,
          tooltip: 'Atualizar Reservas',
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildBookingList(List<dynamic> bookings, String emptyMessage) {
    return bookings.isEmpty
        ? Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emptyMessage,
                  style: const TextStyle(color: AppTheme.hintColor)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchAthleteBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              )
            ],
          ))
        : RefreshIndicator(
            onRefresh: _fetchAthleteBookings,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];

                final quadraNome =
                    booking['quadraNome'] ?? booking['courtId'] ?? 'Quadra N/A';
                final horarioFormatado = _formatBookingListItemTime(
                    booking['parsedStartTime'] as DateTime?);
                final status = booking['status'] ?? 'N/A';
                final dataParte = horarioFormatado.split(' ')[0];
                final horaParte = horarioFormatado.split(' ').length > 1
                    ? horarioFormatado.split(' ')[1]
                    : '';

                return BookingListItem(
                  quadra: quadraNome,
                  data: dataParte,
                  horario: horaParte,
                  status: status,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) =>
                            MyBookingDetailsPage(booking: booking)),
                  ),
                );
              },
            ),
          );
  }
}

// WIDGET REUTILIZÁVEL PARA ITEM DE RESERVA
// ... (Nenhuma alteração nesta classe, mantenha seu código do BookingListItem como está)
class BookingListItem extends StatelessWidget {
  final String quadra, data, horario, status;
  final VoidCallback? onTap;
  const BookingListItem(
      {super.key,
      required this.quadra,
      required this.data,
      required this.horario,
      required this.status,
      this.onTap});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada':
        return Colors.green;
      case 'pendente':
        return Colors.orange;
      case 'cancelada':
        return Colors.red;
      case 'finalizada':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.sports_soccer,
            color: AppTheme.primaryColor, size: 40),
        title: Text(quadra, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$data • $horario'),
        trailing: Text(status.toUpperCase(),
            style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        onTap: onTap ?? () {},
      ),
    );
  }
}

// ABA PERFIL (RF02)
// ... (Nenhuma alteração nesta classe, mantenha seu código da ProfileTab como está)
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Usuário';
    final userEmail = user?.email ?? 'email@exemplo.com';

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor,
            backgroundImage:
                user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 12),
          Text(userName,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(userEmail,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppTheme.hintColor)),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar Perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditProfilePage())),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const NotificationsPage())),
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Segurança'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SecurityPage())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Deslogar', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}

// HOME PAGE PRINCIPAL DO ATLETA
// ... (Nenhuma alteração nesta classe, mantenha seu código da AthleteHomePage como está)
class AthleteHomePage extends StatefulWidget {
  const AthleteHomePage({super.key});
  @override
  State<AthleteHomePage> createState() => _AthleteHomePageState();
}

class _AthleteHomePageState extends State<AthleteHomePage> {
  int _selectedIndex = 0;
  static const List<Widget> _tabs = <Widget>[
    ExploreTab(),
    MyBookingsTab(),
    ProfileTab()
  ];
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Minhas Reservas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ABA EXPLORAR (RF05) - (MODIFICADA)
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});
  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  List<dynamic> _courtsData = []; // Lista para quadras da API
  List<dynamic> _openMatchesData = []; // 1. Lista (mutável) para partidas da API
  
  bool _isLoadingCourts = true;
  bool _isLoadingMatches = true; // 2. Estado de loading para partidas

  @override
  void initState() {
    super.initState();
    _fetchPublicCourts();
    _fetchOpenMatches(); // 3. Chamar a nova função
  }

  // (Função _fetchPublicCourts sem alterações)
  Future<void> _fetchPublicCourts() async {
    if (!mounted) return;
    setState(() => _isLoadingCourts = true);
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/courts/public');
      final response = await http.get(url);

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _courtsData = jsonDecode(response.body);
          _isLoadingCourts = false;
        });
      } else {
        throw Exception('Falha ao carregar quadras públicas: ${response.body}');
      }
    } catch (e) {
      print('Erro ao buscar quadras públicas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
        setState(() => _isLoadingCourts = false);
      }
    }
  }

  // 4. Nova função para buscar Partidas Abertas (RF05)
  Future<void> _fetchOpenMatches() async {
    if (!mounted) return;
    setState(() => _isLoadingMatches = true);
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/matches/public');
      final response = await http.get(url); // Endpoint público

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _openMatchesData = jsonDecode(response.body);
          _isLoadingMatches = false;
        });
      } else {
        throw Exception('Falha ao carregar partidas abertas: ${response.body}');
      }
    } catch (e) {
      print('Erro ao buscar partidas abertas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
        setState(() => _isLoadingMatches = false);
      }
    }
  }

  // 5. Nova função helper para formatar o Timestamp da partida
  String _formatMatchTime(dynamic timestamp) {
    DateTime? startTime;
    if (timestamp is Map && timestamp['_seconds'] != null) {
      startTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      startTime = DateTime.tryParse(timestamp);
    }

    if (startTime != null) {
      // Ex: "Hoje, 20:00", "Amanhã, 21:00", "Sáb, 10/11 - 22:00"
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
  Widget build(BuildContext context) {
    final userName =
        FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ??
            'Atleta';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, $userName!',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppTheme.hintColor)),
            const Text('Encontre sua próxima partida',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor)),
          ],
        ),
        toolbarHeight: 80,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 6. Atualiza ambas as listas no Refresh
          await _fetchPublicCourts();
          await _fetchOpenMatches();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por quadra ou esporte...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                print('Buscando por: $value');
              },
            ),
            const SizedBox(height: 24),

            // 7. Seção de Partidas Abertas (MODIFICADA)
            _buildSectionHeader('Partidas Abertas', () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const OpenMatchesPage()));
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              // 8. Usa _isLoadingMatches e dados da API
              child: _isLoadingMatches
                  ? const Center(child: CircularProgressIndicator())
                  : _openMatchesData.isEmpty
                      ? const Center(
                          child: Text("Nenhuma partida aberta no momento.",
                              style: TextStyle(color: AppTheme.hintColor)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _openMatchesData.length,
                          itemBuilder: (context, index) {
                            final match = _openMatchesData[index];

                            // 9. Extrai dados reais da API
                            final vagas = match['vagasDisponiveis'] ?? 0;
                            final esporte = match['esporte'] ?? 'N/D';
                            final horario = _formatMatchTime(match['startTime']);
                            final quadra = match['quadraNome'] ?? 'N/D';
                            final matchId = match['id']; // ID da partida

                            return OpenMatchCard(
                              vagas: vagas as int,
                              esporte: esporte as String,
                              horario: horario,
                              quadra: quadra as String,
                              // 10. Adiciona onTap para navegar (RF09)
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => MatchDetailsPage(matchId: matchId)
                                ));
                              },
                            );
                          }),
            ),
            const SizedBox(height: 24),

            // Seção de Quadras (Sem alterações)
            _buildSectionHeader('Quadras Perto de Você', () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AllCourtsPage()));
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: _isLoadingCourts
                  ? const Center(child: CircularProgressIndicator())
                  : _courtsData.isEmpty
                      ? const Center(
                          child: Text("Nenhuma quadra encontrada.",
                              style: TextStyle(color: AppTheme.hintColor)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _courtsData.length,
                          itemBuilder: (context, index) {
                            final court = _courtsData[index];
                            final courtId = court['id'] ?? 'unknown_id_$index';
                            final nome = court['nome'] ?? 'Quadra sem nome';
                            final endereco =
                                court['endereco'] ?? 'Endereço indisponível';
                            final esporte =
                                court['esporte'] ?? 'Esporte não definido';
                            
                            String pricePerHourStr = 'N/D';
                            if (court['availability'] is Map) {
                              final availabilityMap =
                                  court['availability'] as Map<String, dynamic>;
                              for (var dayData in availabilityMap.values) {
                                if (dayData is Map &&
                                    dayData['pricePerHour'] != null) {
                                  pricePerHourStr = dayData['pricePerHour']
                                          ?.toStringAsFixed(2)
                                          ?.replaceAll('.', ',') ??
                                      'N/D';
                                  break;
                                }
                              }
                            }
                            final preco = 'R\$ $pricePerHourStr/h';

                            return CourtCard(
                              courtId: courtId,
                              nome: nome,
                              endereco: endereco,
                              esporte: esporte,
                              preco: preco,
                            );
                          }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor)),
        TextButton(onPressed: onViewAll, child: const Text('Ver todas')),
      ],
    );
  }
}

// CARD PARA QUADRA
// ... (Nenhuma alteração nesta classe, mantenha seu código do CourtCard como está)
class CourtCard extends StatelessWidget {
  final String courtId, nome, endereco, esporte, preco;

  const CourtCard(
      {super.key,
      required this.courtId,
      required this.nome,
      required this.endereco,
      required this.esporte,
      required this.preco});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        'https://placehold.co/300x200/2E7D32/FFFFFF/png?text=${Uri.encodeComponent(nome)}&font=roboto';

    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => CourtDetailsPage(
                    courtId: courtId,
                    courtName: nome,
                  )));
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                        child: Icon(Icons.sports_soccer,
                            color: Colors.grey, size: 40));
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nome,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 2, color: Colors.black54)
                                ])),
                        const SizedBox(height: 4),
                        Text(endereco,
                            style: const TextStyle(
                                color: Colors.white70,
                                shadows: [
                                  Shadow(blurRadius: 2, color: Colors.black54)
                                ]),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(esporte,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                shadows: [
                                  Shadow(blurRadius: 2, color: Colors.black54)
                                ]),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(preco,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
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