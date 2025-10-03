// lib/features/home/presentation/pages/athlete_home_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/login_page.dart';

// PLACEHOLDER PAGE
class CourtDetailsPage extends StatelessWidget {
  const CourtDetailsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Detalhes da Quadra')), body: const Center(child: Text('Página com detalhes da quadra, horários, etc.')));
  }
}

// ABA MINHAS RESERVAS (RF07) - DETALHADA
class MyBookingsTab extends StatelessWidget {
  const MyBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // TabController para gerenciar as abas "Próximos" e "Histórico"
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Reservas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'PRÓXIMOS JOGOS'),
              Tab(text: 'HISTÓRICO'),
            ],
            labelColor: AppTheme.primaryColor,
            indicatorColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.hintColor,
          ),
        ),
        body: TabBarView(
          children: [
            // Conteúdo da aba "Próximos"
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: const [
                BookingListItem(
                  quadra: 'Quadra Central',
                  data: 'Hoje, 03/10/25',
                  horario: '20:00 - 21:00',
                  status: 'Confirmada',
                ),
                BookingListItem(
                  quadra: 'Arena Litoral',
                  data: 'Amanhã, 04/10/25',
                  horario: '19:00 - 20:00',
                  status: 'Pendente',
                ),
              ],
            ),
            // Conteúdo da aba "Histórico"
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: const [
                BookingListItem(
                  quadra: 'Ginásio do Bairro',
                  data: '28/09/25',
                  horario: '21:00 - 22:00',
                  status: 'Finalizada',
                ),
              ],
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

  const BookingListItem({
    super.key,
    required this.quadra,
    required this.data,
    required this.horario,
    required this.status,
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
        onTap: () { /* Levaria para os detalhes da reserva */ },
      ),
    );
  }
}


// ABA PERFIL (RF02) - DETALHADA
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          // Seção com foto e nome
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
          // Opções do Perfil
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar Perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Segurança'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
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

// ... O restante do arquivo (AthleteHomePage, ExploreTab, CourtCard) continua o mesmo
class AthleteHomePage extends StatefulWidget { /* ...código inalterado... */ 
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
class ExploreTab extends StatelessWidget { /* ...código inalterado... */ 
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
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por quadra ou esporte...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {},
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Partidas Abertas', () {}),
          const SizedBox(height: 16),
          const CourtCard(nome: 'Quadra Central', endereco: 'Centro, Passo Fundo', esporte: 'Futsal, Tênis', preco: 'R\$ 80/h'),
          const CourtCard(nome: 'Arena Litoral', endereco: 'Boqueirão, Passo Fundo', esporte: 'Futevôlei, Vôlei', preco: 'R\$ 60/h'),
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
class CourtCard extends StatelessWidget { /* ...código inalterado... */ 
  final String nome, endereco, esporte, preco;

  const CourtCard({super.key, required this.nome, required this.endereco, required this.esporte, required this.preco});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CourtDetailsPage()));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.asset('assets/images/placeholder_quadra.png', fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(endereco, style: const TextStyle(color: AppTheme.hintColor)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(esporte, style: const TextStyle(color: AppTheme.textColor)),
                      Text(preco, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}