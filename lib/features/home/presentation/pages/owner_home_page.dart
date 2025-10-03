// lib/features/home/presentation/pages/owner_home_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/login_page.dart';

// PLACEHOLDER PAGE
class AddEditCourtPage extends StatelessWidget {
  const AddEditCourtPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Adicionar/Editar Espaço')), body: const Center(child: Text('Formulário para dados do espaço')));
  }
}

// ABA AGENDA (RF04, RF07) - DETALHADA
class OwnerAgendaTab extends StatelessWidget {
  const OwnerAgendaTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de Hoje')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          // Usaremos o mesmo widget de item de reserva do Atleta
          BookingListItem(
            quadra: 'Quadra Central',
            data: 'Cliente: Carlos Silva',
            horario: '19:00 - 20:00',
            status: 'Confirmada',
          ),
           BookingListItem(
            quadra: 'Quadra Central',
            data: 'Cliente: Fernanda Lima',
            horario: '20:00 - 21:00',
            status: 'Confirmada',
          ),
           BookingListItem(
            quadra: 'Arena Litoral',
            data: 'Cliente: Grupo Amigos',
            horario: '21:00 - 22:00',
            status: 'Pendente',
          ),
        ],
      )
    );
  }
}

// ABA PERFIL (RF02) - DETALHADA
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
          ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Editar Perfil'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
          ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('Configurações de Pagamento'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
          ListTile(leading: const Icon(Icons.bar_chart_outlined), title: const Text('Relatórios'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
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


// ... O restante do arquivo (OwnerHomePage, MyCourtsTab, etc.) continua o mesmo
class OwnerHomePage extends StatefulWidget { /* ...código inalterado... */ 
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _tabs = <Widget>[
    const MyCourtsTab(),
    const OwnerAgendaTab(),
    const OwnerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // Para poder reutilizar o BookingListItem, precisamos importá-lo aqui
    // A forma mais limpa é movê-lo para um arquivo próprio em /shared/widgets/
    // Mas por enquanto, vamos apenas adicionar o import.
    _tabs[1] = const OwnerAgendaTab(); // Apenas garantindo que a versão detalhada seja usada.

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
class MyCourtsTab extends StatelessWidget { /* ...código inalterado... */ 
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
class OwnedCourtListItem extends StatelessWidget { /* ...código inalterado... */ 
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
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddEditCourtPage()));
        },
      ),
    );
  }
}
// Importando o BookingListItem para ser usado na OwnerHomePage
// O ideal é mover este widget para seu próprio arquivo
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