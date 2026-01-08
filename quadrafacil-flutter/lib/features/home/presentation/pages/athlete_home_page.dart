import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/login_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/all_courts_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/court_details_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/match_details_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/my_booking_details_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/open_matches_page.dart';
import 'package:quadrafacil/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:quadrafacil/features/profile/presentation/pages/notifications_page.dart';
import 'package:quadrafacil/features/profile/presentation/pages/security_page.dart';
import 'package:quadrafacil/shared/widgets/open_match_card.dart';

// ============================================================================
// ABA MINHAS RESERVAS (RENOVADA)
// ============================================================================
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
    // Só mostra loading se a lista estiver vazia (para não piscar no refresh)
    if (_upcomingBookings.isEmpty && _historyBookings.isEmpty) {
        setState(() => _isLoading = true);
    }
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/bookings/athlete');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $idToken'});

      if (response.statusCode == 200) {
        if (mounted) {
          final allBookings = jsonDecode(response.body) as List;
          final now = DateTime.now();
          final upcoming = <dynamic>[];
          final history = <dynamic>[];

          for (var booking in allBookings) {
            DateTime? startTime;
            if (booking['startTime'] is Map && booking['startTime']['_seconds'] != null) {
              startTime = DateTime.fromMillisecondsSinceEpoch(booking['startTime']['_seconds'] * 1000);
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

          // Ordenação
          upcoming.sort((a, b) => (a['parsedStartTime'] ?? DateTime(0)).compareTo(b['parsedStartTime'] ?? DateTime(0)));
          history.sort((a, b) => (b['parsedStartTime'] ?? DateTime(0)).compareTo(a['parsedStartTime'] ?? DateTime(0)));

          setState(() {
            _upcomingBookings = upcoming;
            _historyBookings = history;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Falha ao carregar reservas.');
      }
    } catch (e) {
      print('Erro: $e');
      if (mounted) {
        // Mostra snackbar apenas se for erro real, não cancelamento de widget
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar reservas. Tente novamente.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBookingListItemTime(DateTime? dateTime) {
    if (dateTime != null) {
      return DateFormat('dd/MM • HH:mm', 'pt_BR').format(dateTime);
    }
    return 'Data inválida';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Reservas', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorWeight: 3,
            tabs: [Tab(text: 'PRÓXIMOS JOGOS'), Tab(text: 'HISTÓRICO')],
            labelColor: AppTheme.primaryColor,
            indicatorColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.hintColor,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBookingList(_upcomingBookings, 'Nenhum jogo agendado.', Icons.calendar_today_outlined),
                  _buildBookingList(_historyBookings, 'Nenhum histórico de jogos.', Icons.history),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchAthleteBookings,
          tooltip: 'Atualizar',
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildBookingList(List<dynamic> bookings, String emptyMessage, IconData emptyIcon) {
    if (bookings.isEmpty) {
        return Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(emptyIcon, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(emptyMessage, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                    onPressed: _fetchAthleteBookings,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Atualizar'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                )
            ],
            ),
        );
    }

    return RefreshIndicator(
      onRefresh: _fetchAthleteBookings,
      child: ListView.separated( // Separated para adicionar espaço entre itens
        padding: const EdgeInsets.all(16.0),
        itemCount: bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = bookings[index];
          final itemType = item['type'] ?? 'booking';
          final quadraNome = item['quadraNome'] ?? item['courtId'] ?? 'Quadra N/A';
          final horarioFormatado = _formatBookingListItemTime(item['parsedStartTime'] as DateTime?);
          final status = item['status'] ?? 'N/A';
          
          // Separa Data e Hora para o layout novo
          final dataParts = horarioFormatado.split(' • ');
          final dataStr = dataParts[0];
          final horaStr = dataParts.length > 1 ? dataParts[1] : '';

          return BookingListItem(
            quadra: quadraNome,
            data: dataStr,
            horario: horaStr,
            status: status,
            isMatch: itemType == 'match', // Flag para ícone diferente
            onTap: () {
              if (itemType == 'match') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => MatchDetailsPage(matchId: item['id'])
                ));
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => MyBookingDetailsPage(booking: item)
                ));
              }
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// WIDGET REUTILIZÁVEL: CARD DE RESERVA (VISUAL PREMIUM)
// ============================================================================
class BookingListItem extends StatelessWidget {
  final String quadra, data, horario, status;
  final bool isMatch;
  final VoidCallback? onTap;

  const BookingListItem({
    super.key,
    required this.quadra,
    required this.data,
    required this.horario,
    required this.status,
    this.isMatch = false,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada': return Colors.green[700]!;
      case 'pendente': return Colors.orange[800]!;
      case 'cancelada': return Colors.red[700]!;
      case 'finalizada': return Colors.grey[600]!;
      case 'aberta': return Colors.blue[700]!; // Para partidas
      default: return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada': return Colors.green[50]!;
      case 'pendente': return Colors.orange[50]!;
      case 'cancelada': return Colors.red[50]!;
      case 'finalizada': return Colors.grey[100]!;
      case 'aberta': return Colors.blue[50]!;
      default: return Colors.grey[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    final statusBg = _getStatusBgColor(status);

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Ícone / Data Box
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isMatch ? Colors.blue[50] : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isMatch ? Icons.groups : Icons.calendar_month, 
                           color: isMatch ? Colors.blue : AppTheme.primaryColor, size: 24),
                      const SizedBox(height: 4),
                      Text(data, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quadra, 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                           maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(horario, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Tag de Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ABA PERFIL (LEVE AJUSTE VISUAL)
// ============================================================================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Usuário';
    final userEmail = user?.email ?? 'email@exemplo.com';

    return Scaffold(
      appBar: AppBar(
          title: const Text('Meu Perfil', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white, elevation: 0),
      backgroundColor: Colors.grey[50], // Fundo levemente cinza
      body: ListView(
        children: [
          const SizedBox(height: 32),
          Center(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(userName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
          Text(userEmail, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),
          
          // Menu Options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildProfileOption(context, 'Editar Perfil', Icons.edit_outlined, const EditProfilePage()),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildProfileOption(context, 'Notificações', Icons.notifications_outlined, const NotificationsPage()),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildProfileOption(context, 'Segurança', Icons.security_outlined, const SecurityPage()),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
                onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (Route<dynamic> route) => false);
                    }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sair da Conta', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, String title, IconData icon, Widget page) {
    return ListTile(
        leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20)
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => page)),
    );
  }
}

// ============================================================================
// HOME PAGE PRINCIPAL (WRAPPER)
// ============================================================================
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Reservas'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// ============================================================================
// ABA EXPLORAR (RF05) - VISUAL LIMPO
// ============================================================================
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});
  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  List<dynamic> _courtsData = [];
  List<dynamic> _openMatchesData = [];
  
  bool _isLoadingCourts = true;
  bool _isLoadingMatches = true; 

  @override
  void initState() {
    super.initState();
    _fetchPublicCourts();
    _fetchOpenMatches(); 
  }

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
        throw Exception('Falha ao carregar quadras.');
      }
    } catch (e) {
      print('Erro quadras: $e');
      if (mounted) setState(() => _isLoadingCourts = false);
    }
  }

  Future<void> _fetchOpenMatches() async {
    if (!mounted) return;
    setState(() => _isLoadingMatches = true);
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/matches/public');
      final response = await http.get(url); 

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _openMatchesData = jsonDecode(response.body);
          _isLoadingMatches = false;
        });
      } else {
        throw Exception('Falha ao carregar partidas.');
      }
    } catch (e) {
      print('Erro partidas: $e');
      if (mounted) setState(() => _isLoadingMatches = false);
    }
  }

  String _formatMatchTime(dynamic timestamp) {
    DateTime? startTime;
    if (timestamp is Map && timestamp['_seconds'] != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
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
        return DateFormat('E, dd/MM • HH:mm', 'pt_BR').format(startTime);
      }
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final userName = FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'Atleta';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá, $userName! 👋',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600])),
              const SizedBox(height: 4),
              const Text('Bora jogar hoje?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
            ],
          ),
        ),
        toolbarHeight: 80,
        actions: [
            // Botão de Notificação (Decorativo para dar um charme)
            Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
                    icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.textColor, size: 28),
                ),
            )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchPublicCourts();
          await _fetchOpenMatches();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0), // Remove padding lateral global para o scroll horizontal ir até a borda
          children: [
            _buildSectionHeader(context, '🔥 Partidas Abertas', () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const OpenMatchesPage()));
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 190, // Altura ajustada para os cards
              child: _isLoadingMatches
                  ? const Center(child: CircularProgressIndicator())
                  : _openMatchesData.isEmpty
                      ? _buildEmptyState('Nenhuma partida rolando agora.')
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _openMatchesData.length,
                          itemBuilder: (context, index) {
                            final match = _openMatchesData[index];
                            final vagas = match['vagasDisponiveis'] ?? 0;
                            final esporte = match['esporte'] ?? 'N/D';
                            final horario = _formatMatchTime(match['startTime']);
                            final quadra = match['quadraNome'] ?? 'N/D';
                            final matchId = match['id']; 

                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: OpenMatchCard(
                                vagas: vagas as int,
                                esporte: esporte as String,
                                horario: horario,
                                quadra: quadra as String,
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => MatchDetailsPage(matchId: matchId)
                                  ));
                                },
                              ),
                            );
                          }),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader(context, '🏟️ Quadras Perto', () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AllCourtsPage()));
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 220, // Altura maior para quadras
              child: _isLoadingCourts
                  ? const Center(child: CircularProgressIndicator())
                  : _courtsData.isEmpty
                      ? _buildEmptyState('Nenhuma quadra disponível.')
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _courtsData.length,
                          itemBuilder: (context, index) {
                            final court = _courtsData[index];
                            final courtId = court['id'] ?? 'unknown';
                            final nome = court['nome'] ?? 'Quadra';
                            final endereco = court['endereco'] ?? 'Endereço N/D';
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

                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: CourtCard(
                                courtId: courtId,
                                nome: nome,
                                endereco: endereco,
                                esporte: esporte,
                                preco: preco,
                              ),
                            );
                          }),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
          InkWell(
            onTap: onViewAll,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Text('Ver todas', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
      return Center(
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
              child: Text(msg, style: TextStyle(color: Colors.grey[500])),
          ),
      );
  }
}

// ============================================================================
// WIDGET: CARD DA QUADRA
// ============================================================================
class CourtCard extends StatelessWidget {
  final String courtId, nome, endereco, esporte, preco;

  const CourtCard({
    super.key,
    required this.courtId,
    required this.nome,
    required this.endereco,
    required this.esporte,
    required this.preco,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = 'https://placehold.co/300x200/2E7D32/FFFFFF/png?text=${Uri.encodeComponent(nome)}&font=roboto';

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => CourtDetailsPage(
                courtId: courtId,
                courtName: nome,
              ),
            ));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Imagem (Reduzi de 140 para 115 para dar espaço ao texto)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      height: 115, // <--- AJUSTE AQUI
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 115,
                          color: Colors.grey[100],
                          child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor.withOpacity(0.5))),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 115,
                          color: Colors.grey[200],
                          child: const Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  // Tag de Preço
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        preco,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              
              // 2. Informações (Usando Expanded para evitar overflow)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribui o espaço
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  endereco,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Esporte (Badge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          esporte,
                          style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}