// lib/features/home/presentation/pages/athlete_home_page.dart
import 'package:flutter/material.dart';
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

// ABA MINHAS RESERVAS (RF07) - ATUALIZADA
class MyBookingsTab extends StatelessWidget {
  const MyBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados de Exemplo
    final upcomingBookings = [
      BookingData(quadra: 'Quadra Central', data: 'Hoje, 06/10/25', horario: '20:00 - 21:00', status: 'Confirmada'),
      BookingData(quadra: 'Arena Litoral', data: 'Amanhã, 07/10/25', horario: '19:00 - 20:00', status: 'Pendente'),
    ];
    final historyBookings = [
      BookingData(quadra: 'Ginásio do Bairro', data: '28/09/25', horario: '21:00 - 22:00', status: 'Finalizada'),
    ];

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
        body: TabBarView(
          children: [
            // Aba Próximos
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: upcomingBookings.length,
              itemBuilder: (context, index) {
                final booking = upcomingBookings[index];
                return BookingListItem(
                  quadra: booking.quadra,
                  data: booking.data,
                  horario: booking.horario,
                  status: booking.status,
                  onTap: () { // 2. Navegação adicionada
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MyBookingDetailsPage(booking: booking)),
                    );
                  },
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
                  quadra: booking.quadra,
                  data: booking.data,
                  horario: booking.horario,
                  status: booking.status,
                  onTap: () { // 2. Navegação adicionada
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MyBookingDetailsPage(booking: booking)),
                    );
                  },
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

  const BookingListItem({
    super.key,
    required this.quadra,
    required this.data,
    required this.horario,
    required this.status,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmada': return Colors.green;
      case 'Pendente': return Colors.orange;
      case 'Cancelada': return Colors.red;
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
        trailing: Text(
          status.toUpperCase(),
          style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
        ),
        onTap: onTap, // 3. Ação de clique conectada
      ),
    );
  }
}

// ABA PERFIL (RF02)
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          const CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'Júlio Caetano',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'atleta@email.com',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppTheme.hintColor),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar Perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfilePage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Segurança'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SecurityPage()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Deslogar', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
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

  static const List<Widget> _tabs = <Widget>[
    ExploreTab(),
    MyBookingsTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Minhas Reservas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ABA EXPLORAR (RF05) - SIMPLIFICADA
class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, Júlio!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppTheme.hintColor)),
            Text('Encontre sua próxima partida', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
          ],
        ),
        toolbarHeight: 80,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Seção de Partidas Abertas (Scroll Horizontal)
          _buildSectionHeader('Partidas Abertas', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OpenMatchesPage()));
          }),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                OpenMatchCard(vagas: 2, esporte: 'Futsal', horario: '20:00', quadra: 'Quadra Central'),
                OpenMatchCard(vagas: 3, esporte: 'Vôlei', horario: '19:00', quadra: 'Arena Litoral'),
                OpenMatchCard(vagas: 1, esporte: 'Basquete', horario: '21:00', quadra: 'Ginásio Municipal'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção de Quadras (Scroll Horizontal)
          _buildSectionHeader('Quadras Perto de Você', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AllCourtsPage()));
          }),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                CourtCard(nome: 'Quadra Central', endereco: 'Centro, Passo Fundo', esporte: 'Futsal, Tênis', preco: 'R\$ 80/h'),
                CourtCard(nome: 'Arena Litoral', endereco: 'Boqueirão, Passo Fundo', esporte: 'Futevôlei, Vôlei', preco: 'R\$ 60/h'),
                CourtCard(nome: 'Ginásio Municipal', endereco: 'Vila Luiza, Passo Fundo', esporte: 'Basquete', preco: 'R\$ 90/h'),
              ],
            ),
          ),
        ],
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

// CARD PARA PARTIDA ABERTA
class OpenMatchCard extends StatelessWidget {
  final int vagas;
  final String esporte;
  final String horario;
  final String quadra;

  const OpenMatchCard({super.key, required this.vagas, required this.esporte, required this.horario, required this.quadra});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MatchDetailsPage()));
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(8)),
                child: Text('$vagas vagas', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Text('$esporte • $horario', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(quadra, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

// CARD PARA QUADRA - REDESENHADO
class CourtCard extends StatelessWidget {
  final String nome, endereco, esporte, preco;

  const CourtCard({super.key, required this.nome, required this.endereco, required this.esporte, required this.preco});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CourtDetailsPage()));
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
                  Text(endereco, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(esporte, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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