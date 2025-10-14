// lib/features/home/presentation/pages/owner_home_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/login_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/add_edit_court_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/booking_details_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/edit_owner_profile_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/payment_settings_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/reports_page.dart';

// ABA AGENDA (RF04, RF07) - ATUALIZADA COM NAVEGAÇÃO
class OwnerAgendaTab extends StatelessWidget {
  const OwnerAgendaTab({super.key});
  @override
  Widget build(BuildContext context) {
    final bookings = [
      BookingData(quadra: 'Quadra Central', cliente: 'Carlos Silva', horario: '19:00 - 20:00', status: 'Confirmada'),
      BookingData(quadra: 'Quadra Central', cliente: 'Fernanda Lima', horario: '20:00 - 21:00', status: 'Confirmada'),
      BookingData(quadra: 'Arena Litoral', cliente: 'Grupo Amigos', horario: '21:00 - 22:00', status: 'Pendente'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de Hoje')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingListItem(
            quadra: booking.quadra,
            data: 'Cliente: ${booking.cliente}',
            horario: booking.horario,
            status: booking.status,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => BookingDetailsPage(booking: booking)),
              );
            },
          );
        },
      )
    );
  }
}

// ABA PERFIL (RF02) - ATUALIZADA COM NAVEGAÇÃO
class OwnerProfileTab extends StatelessWidget {
  const OwnerProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          const CircleAvatar(radius: 50, backgroundColor: AppTheme.primaryColor, child: Icon(Icons.store, size: 60, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Júlio Caetano (Dono)', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('dono@email.com', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppTheme.hintColor)),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Editar Perfil'), trailing: const Icon(Icons.chevron_right), onTap: () {
             Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditOwnerProfilePage()));
          }),
          ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('Configurações de Pagamento'), trailing: const Icon(Icons.chevron_right), onTap: () {
             Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PaymentSettingsPage()));
          }),
          ListTile(leading: const Icon(Icons.bar_chart_outlined), title: const Text('Relatórios'), trailing: const Icon(Icons.chevron_right), onTap: () {
             Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ReportsPage()));
          }),
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

// HOME PAGE PRINCIPAL DO DONO
class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _tabs = <Widget>[
    MyCourtsTab(),
    OwnerAgendaTab(),
    OwnerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddEditCourtPage()));
        },
        label: const Text('Novo Espaço'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.store_mall_directory_outlined), label: 'Meus Espaços'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ABA MEUS ESPAÇOS (RF03)
class MyCourtsTab extends StatelessWidget {
  const MyCourtsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Espaços'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          OwnedCourtListItem(nome: 'Quadra Central', ocupacao: 75, status: 'Ativo'),
          OwnedCourtListItem(nome: 'Arena Litoral', ocupacao: 40, status: 'Ativo'),
          OwnedCourtListItem(nome: 'Ginásio do Bairro', ocupacao: 0, status: 'Inativo'),
        ],
      ),
    );
  }
}

// WIDGET REUTILIZÁVEL PARA ITEM DA LISTA DE QUADRAS DO DONO
class OwnedCourtListItem extends StatelessWidget {
  final String nome;
  final int ocupacao;
  final String status;

  const OwnedCourtListItem({super.key, required this.nome, required this.ocupacao, required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Ocupação hoje: $ocupacao%'),
        trailing: Icon(
          Icons.circle,
          color: status == 'Ativo' ? Colors.green : Colors.grey,
          size: 12,
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddEditCourtPage(courtName: nome)));
        },
      ),
    );
  }
}

// WIDGET REUTILIZÁVEL PARA ITEM DE RESERVA (usado na OwnerAgendaTab)
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
        leading: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryColor, size: 40),
        title: Text(quadra, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$data • $horario'),
        trailing: Text(
          status.toUpperCase(),
          style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }
}