// lib/features/home/presentation/pages/owner_home_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quadrafacil/core/config.dart'; // Import da configuração de URL
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/login_page.dart';
// Import correto da AddEditCourtPage
import 'package:quadrafacil/features/home/presentation/pages/add_edit_court_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/booking_details_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/edit_owner_profile_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/payment_settings_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/reports_page.dart';

// ABA MEUS ESPAÇOS (RF03) - COM LÓGICA DE DADOS E REFRESH
class MyCourtsTab extends StatefulWidget {
  // Adicionamos a key aqui para podermos chamar o refresh externamente se necessário
  const MyCourtsTab({super.key});

  @override
  State<MyCourtsTab> createState() => _MyCourtsTabState();
}

class _MyCourtsTabState extends State<MyCourtsTab> {
  List<dynamic> _courts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourts(); // Chama a função para buscar as quadras quando a tela inicia
  }

  // Função pública para poder ser chamada de fora (ex: após salvar)
  Future<void> _fetchCourts() async {
    // Garante que o loading seja exibido se já não estiver
    if (!mounted) return; // Checagem extra de montagem
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');

      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/courts');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _courts = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Falha ao carregar quadras: ${response.body}');
      }
    } catch (e) {
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

  // Função para lidar com o retorno da tela de Adicionar/Editar
  Future<void> _handleNavigationResult(dynamic result) async {
     if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Operação realizada com sucesso! Atualizando lista...'), backgroundColor: Colors.green)
         );
         await _fetchCourts(); // Recarrega a lista
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Espaços'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCourts, // Botão para recarregar a lista
            tooltip: 'Atualizar',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostra loading
          : _courts.isEmpty
              ? Center(
                  child: Column( // Mensagem centralizada com botão refresh
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                     const Text('Nenhum espaço cadastrado ainda.'),
                     const SizedBox(height: 16),
                     ElevatedButton.icon(
                       onPressed: _fetchCourts,
                       icon: const Icon(Icons.refresh),
                       label: const Text('Tentar Novamente'),
                      )
                    ],
                  )
                )
              : RefreshIndicator( // Permite "puxar para atualizar"
                  onRefresh: _fetchCourts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _courts.length,
                    itemBuilder: (context, index) {
                      final court = _courts[index];
                      return OwnedCourtListItem(
                        courtId: court['id'],
                        nome: court['nome'] ?? 'Nome indisponível',
                        ocupacao: 0, // Placeholder
                        status: 'Ativo', // Placeholder
                        onTap: () async { // Navega e espera o resultado
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => AddEditCourtPage(courtId: court['id']))
                          );
                          _handleNavigationResult(result);
                        }
                      );
                    },
                  ),
                ),
       floatingActionButton: FloatingActionButton.extended(
        onPressed: () async { // Navega e espera o resultado
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditCourtPage())
          );
           _handleNavigationResult(result);
        },
        label: const Text('Novo Espaço'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ABA AGENDA (RF04, RF07)
class OwnerAgendaTab extends StatelessWidget {
  const OwnerAgendaTab({super.key});
  @override
  Widget build(BuildContext context) {
    // Dados de exemplo - MANTIDOS POR ENQUANTO
    final bookings = [
      BookingData(
          quadra: 'Quadra Central',
          cliente: 'Carlos Silva',
          horario: '19:00 - 20:00',
          status: 'Confirmada'),
      BookingData(
          quadra: 'Quadra Central',
          cliente: 'Fernanda Lima',
          horario: '20:00 - 21:00',
          status: 'Confirmada'),
      BookingData(
          quadra: 'Arena Litoral',
          cliente: 'Grupo Amigos',
          horario: '21:00 - 22:00',
          status: 'Pendente'),
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
                  MaterialPageRoute(
                      builder: (context) => BookingDetailsPage(booking: booking)),
                );
              },
            );
          },
        ));
  }
}

// ABA PERFIL (RF02)
class OwnerProfileTab extends StatelessWidget {
  const OwnerProfileTab({super.key});
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
              child: Icon(Icons.store, size: 60, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Júlio Caetano (Dono)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('dono@email.com',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.hintColor)),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar Perfil'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const EditOwnerProfilePage()));
              }),
          ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Configurações de Pagamento'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const PaymentSettingsPage()));
              }),
          ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Relatórios'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ReportsPage()));
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

  // Key para podermos chamar o refresh da lista de quadras
  // Embora tenhamos a função _handleNavigationResult agora, a key pode ser útil
  // para outras interações futuras entre abas, então vamos mantê-la por enquanto.
  final GlobalKey<_MyCourtsTabState> myCourtsTabKey = GlobalKey<_MyCourtsTabState>();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
     _tabs = <Widget>[
      MyCourtsTab(key: myCourtsTabKey), // Passamos a key aqui
      const OwnerAgendaTab(),
      const OwnerProfileTab(),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // Usamos IndexedStack para manter o estado das abas
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.store_mall_directory_outlined),
              label: 'Meus Espaços'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined), label: 'Agenda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

// WIDGET REUTILIZÁVEL PARA ITEM DA LISTA DE QUADRAS DO DONO
class OwnedCourtListItem extends StatelessWidget {
  final String courtId;
  final String nome;
  final int ocupacao;
  final String status;
  final VoidCallback? onTap; // Adicionado onTap para navegação

  const OwnedCourtListItem({
    super.key,
    required this.courtId,
    required this.nome,
    required this.ocupacao,
    required this.status,
    this.onTap, // Adicionado
  });

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
        onTap: onTap, // Usa o onTap passado
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
      case 'Confirmada':
        return Colors.green;
      case 'Pendente':
        return Colors.orange;
      case 'Cancelada':
        return Colors.red;
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
        leading: const Icon(Icons.receipt_long_outlined,
            color: AppTheme.primaryColor, size: 40),
        title: Text(quadra, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$data • $horario'),
        trailing: Text(
          status.toUpperCase(),
          style:
              TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }
}