import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
// 1. Importa o modelo compartilhado
import 'package:quadrafacil/shared/models/booking_data.dart';


// ABA MINHAS RESERVAS (RF07)
class MyBookingsTab extends StatelessWidget {
 const MyBookingsTab({super.key});

 @override
 Widget build(BuildContext context) {
   // Dados de Exemplo - TODO: Implementar busca de reservas da API
   final upcomingBookings = [
     BookingData(quadra: 'Quadra Central', data: 'Hoje, 28/10/25', horario: '20:00 - 21:00', status: 'Confirmada', cliente: 'Carlos'), // Exemplo com cliente
     BookingData(quadra: 'Arena Litoral', data: 'Amanhã, 29/10/25', horario: '19:00 - 20:00', status: 'Pendente', cliente: 'Fernanda'), // Exemplo com cliente
   ];
   final historyBookings = [
     BookingData(quadra: 'Ginásio do Bairro', data: '20/10/25', horario: '21:00 - 22:00', status: 'Finalizada', cliente: 'Grupo'), // Exemplo com cliente
   ];

   return DefaultTabController(
     length: 2,
     child: Scaffold(
       appBar: AppBar(
         title: const Text('Minhas Reservas'),
         bottom: const TabBar(
           tabs: [ Tab(text: 'PRÓXIMOS JOGOS'), Tab(text: 'HISTÓRICO') ],
           labelColor: AppTheme.primaryColor, indicatorColor: AppTheme.primaryColor, unselectedLabelColor: AppTheme.hintColor,
         ),
       ),
       body: TabBarView(
         children: [
           // Aba Próximos
           ListView.builder(
             padding: const EdgeInsets.all(16.0),
             itemCount: upcomingBookings.length,
             itemBuilder: (context, index) {
               final booking = upcomingBookings[index];
               return BookingListItem(
                 quadra: booking.quadra, data: booking.data, horario: booking.horario, status: booking.status,
                 onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyBookingDetailsPage(booking: booking))),
               );
             },
           ),
           // Aba Histórico
           ListView.builder(
             padding: const EdgeInsets.all(16.0),
             itemCount: historyBookings.length,
             itemBuilder: (context, index) {
               final booking = historyBookings[index];
               return BookingListItem(
                 quadra: booking.quadra, data: booking.data, horario: booking.horario, status: booking.status,
                 onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyBookingDetailsPage(booking: booking))),
               );
             },
           ),
         ],
       ),
     ),
   );
 }
}

// WIDGET REUTILIZÁVEL PARA ITEM DE RESERVA
class BookingListItem extends StatelessWidget {
 final String quadra, data, horario, status;
 final VoidCallback? onTap;

 const BookingListItem({ super.key, required this.quadra, required this.data, required this.horario, required this.status, this.onTap });

 Color _getStatusColor(String status) {
   switch (status) {
     case 'Confirmada': return Colors.green;
     case 'Pendente': return Colors.orange;
     case 'Cancelada': return Colors.red;
     case 'Finalizada': return Colors.blueGrey;
     default: return Colors.grey;
   }
 }

 @override
 Widget build(BuildContext context) {
    return Card(
     margin: const EdgeInsets.only(bottom: 12),
     child: ListTile(
       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       leading: const Icon(Icons.sports_soccer, color: AppTheme.primaryColor, size: 40),
       title: Text(quadra, style: const TextStyle(fontWeight: FontWeight.bold)),
       subtitle: Text('$data • $horario'),
       trailing: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
       onTap: onTap ?? () {},
     ),
   );
 }
}

// ABA PERFIL (RF02)
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
           radius: 50, backgroundColor: AppTheme.primaryColor,
           backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
           child: user?.photoURL == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
         ),
         const SizedBox(height: 12),
         Text(userName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
         Text(userEmail, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppTheme.hintColor)),
         const SizedBox(height: 32),
         const Divider(),
         ListTile(
           leading: const Icon(Icons.edit_outlined), title: const Text('Editar Perfil'), trailing: const Icon(Icons.chevron_right),
           onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfilePage())),
         ),
         ListTile(
           leading: const Icon(Icons.notifications_outlined), title: const Text('Notificações'), trailing: const Icon(Icons.chevron_right),
           onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsPage())),
         ),
         ListTile(
           leading: const Icon(Icons.security_outlined), title: const Text('Segurança'), trailing: const Icon(Icons.chevron_right),
           onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SecurityPage())),
         ),
         const Divider(),
         ListTile(
           leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Deslogar', style: TextStyle(color: Colors.red)),
           onTap: () async {
             await FirebaseAuth.instance.signOut();
             if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()), (Route<dynamic> route) => false
                );
             }
           },
         ),
       ],
     ),
   );
 }
}

// HOME PAGE PRINCIPAL DO ATLETA
class AthleteHomePage extends StatefulWidget {
 const AthleteHomePage({super.key});
 @override
 State<AthleteHomePage> createState() => _AthleteHomePageState();
}

class _AthleteHomePageState extends State<AthleteHomePage> {
 int _selectedIndex = 0;
 static const List<Widget> _tabs = <Widget>[ ExploreTab(), MyBookingsTab(), ProfileTab() ];
 void _onItemTapped(int index) => setState(() => _selectedIndex = index);

 @override
 Widget build(BuildContext context) {
    return Scaffold(
     body: IndexedStack(index: _selectedIndex, children: _tabs),
     bottomNavigationBar: BottomNavigationBar(
       items: const <BottomNavigationBarItem>[
         BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
         BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Minhas Reservas'),
         BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
       ],
       currentIndex: _selectedIndex, selectedItemColor: AppTheme.primaryColor, onTap: _onItemTapped,
     ),
   );
 }
}

// ABA EXPLORAR (RF05) - BUSCA DADOS DA API E REMOVE DADOS LOCAIS
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});
  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  List<dynamic> _courtsData = []; // Lista para guardar os dados das quadras da API
  // TODO: Adicionar busca de partidas abertas da API
  final List<Map<String, dynamic>> _openMatchesData = const [ // Mantém dados locais para partidas por enquanto
     {'vagas': 2, 'esporte': 'Futsal', 'horario': '20:00', 'quadra': 'Quadra Central'},
     {'vagas': 3, 'esporte': 'Vôlei', 'horario': '19:00', 'quadra': 'Arena Litoral'},
     {'vagas': 1, 'esporte': 'Basquete', 'horario': '21:00', 'quadra': 'Ginásio Municipal'},
   ];
  bool _isLoadingCourts = true;
  // bool _isLoadingMatches = true;

  @override
  void initState() {
    super.initState();
    _fetchPublicCourts();
    // TODO: Chamar _fetchOpenMatches();
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
        throw Exception('Falha ao carregar quadras públicas: ${response.body}');
      }
    } catch (e) {
      print('Erro ao buscar quadras públicas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
        setState(() => _isLoadingCourts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'Atleta';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, $userName!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppTheme.hintColor)),
            const Text('Encontre sua próxima partida', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
          ],
        ),
        toolbarHeight: 80,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchPublicCourts();
          // TODO: await _fetchOpenMatches();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por quadra ou esporte...',
                prefixIcon: const Icon(Icons.search),
              ),
               onChanged: (value) {
                 print('Buscando por: $value');
               },
            ),
            const SizedBox(height: 24),

            // Seção de Partidas Abertas
            _buildSectionHeader('Partidas Abertas', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OpenMatchesPage()));
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: _openMatchesData.isEmpty
                ? const Center(child: Text("Nenhuma partida aberta no momento.", style: TextStyle(color: AppTheme.hintColor)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _openMatchesData.length,
                    itemBuilder: (context, index) {
                       final match = _openMatchesData[index];
                       return OpenMatchCard(
                          vagas: match['vagas'] as int,
                          esporte: match['esporte'] as String,
                          horario: match['horario'] as String,
                          quadra: match['quadra'] as String
                        );
                     }
                   ),
            ),
            const SizedBox(height: 24),

            // Seção de Quadras (com dados da API)
            _buildSectionHeader('Quadras Perto de Você', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AllCourtsPage()));
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: _isLoadingCourts
                ? const Center(child: CircularProgressIndicator())
                : _courtsData.isEmpty
                    ? const Center(child: Text("Nenhuma quadra encontrada.", style: TextStyle(color: AppTheme.hintColor)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _courtsData.length,
                        itemBuilder: (context, index) {
                          final court = _courtsData[index];
                          final courtId = court['id'] ?? 'unknown_id_${index}';
                          final nome = court['nome'] ?? 'Quadra sem nome';
                          final endereco = court['endereco'] ?? 'Endereço indisponível';
                          final esporte = court['esporte'] ?? 'Esporte não definido';
                          final pricePerHour = court['availability']?['segunda']?['pricePerHour']
                                                ?.toStringAsFixed(2)?.replaceAll('.', ',') ?? 'N/D';
                          final preco = 'R\$ $pricePerHour/h';

                          return CourtCard(
                            courtId: courtId, nome: nome, endereco: endereco, esporte: esporte, preco: preco,
                          );
                        }
                      ),
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
        TextButton(onPressed: onViewAll, child: const Text('Ver todas')),
      ],
    );
  }
}

// CARD PARA QUADRA
class CourtCard extends StatelessWidget {
 final String courtId, nome, endereco, esporte, preco;

 const CourtCard({
   super.key, required this.courtId, required this.nome, required this.endereco, required this.esporte, required this.preco
 });

 @override
 Widget build(BuildContext context) {
   return Container(
     width: 250,
     margin: const EdgeInsets.only(right: 16, bottom: 8),
     child: InkWell(
       onTap: () {
         Navigator.of(context).push(MaterialPageRoute(
           builder: (context) => CourtDetailsPage( courtId: courtId, courtName: nome )
         ));
       },
       borderRadius: BorderRadius.circular(12),
       child: Ink(
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(12),
           image: DecorationImage(
             image: const AssetImage('assets/images/placeholder_quadra.png'),
             fit: BoxFit.cover,
             colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
           ),
         ),
         child: Stack(
           children: [
             Column(
               mainAxisAlignment: MainAxisAlignment.end,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(nome, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 4),
                 Text(endereco, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis),
                 const SizedBox(height: 4),
                 Text(esporte, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
               ],
             ),
             Positioned(
               top: 0,
               right: 0,
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
                 child: Text(preco, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               ),
             ),
           ],
         ),
       ),
     ),
   );
 }
}

// 2. Remove a definição duplicada da classe BookingData daqui
// class BookingData { ... }

