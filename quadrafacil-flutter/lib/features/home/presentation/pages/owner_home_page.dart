// lib/features/home/presentation/pages/owner_home_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/authentication/presentation/pages/login_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/add_edit_court_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/booking_details_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/edit_owner_profile_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/payment_settings_page.dart';
import 'package:quadrafacil/features/owner_panel/presentation/pages/reports_page.dart';

// ============================================================================
// ABA MEUS ESPAÇOS (RF03) - VISUAL PREMIUM
// ============================================================================
class MyCourtsTab extends StatefulWidget {
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
    _fetchCourts();
  }

  Future<void> _fetchCourts() async {
    if (!mounted) return;
    // Se a lista já tem itens, não mostra loading full screen, só atualiza silenciosamente
    if (_courts.isEmpty) setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');

      final idToken = await user.getIdToken(true);
      final url = Uri.parse('${AppConfig.apiUrl}/courts');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $idToken'});

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _courts = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Falha ao carregar quadras');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar seus espaços.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleNavigationResult(dynamic result) async {
    if (result == true && mounted) {
      await _fetchCourts(); // Recarrega a lista silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Meus Espaços', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _fetchCourts,
            tooltip: 'Atualizar',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Nenhum espaço cadastrado.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                           final result = await Navigator.of(context).push(
                             MaterialPageRoute(builder: (context) => const AddEditCourtPage()),
                           );
                           _handleNavigationResult(result);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Cadastrar Primeiro Espaço'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      )
                    ],
                  ))
              : RefreshIndicator(
                  onRefresh: _fetchCourts,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _courts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final court = _courts[index];
                      
                      // --- CORREÇÃO DE SEGURANÇA AQUI ---
                      String enderecoDisplay = 'Endereço N/D';
                      final rawEndereco = court['endereco'];

                      if (rawEndereco is String) {
                        // Se for string direta, usa ela
                        enderecoDisplay = rawEndereco;
                      } else if (rawEndereco is Map) {
                        // Se for mapa, tenta pegar a rua ou monta o endereço
                        enderecoDisplay = rawEndereco['rua'] ?? rawEndereco['logradouro'] ?? 'Endereço detalhado';
                        if (rawEndereco['numero'] != null) {
                          enderecoDisplay += ', ${rawEndereco['numero']}';
                        }
                      }
                      // ----------------------------------
                      return OwnedCourtCard(
                          courtId: court['id'],
                          nome: court['nome'] ?? 'Nome indisponível',
                          endereco: enderecoDisplay, // Usa a variável tratada
                          status: 'Ativo', 
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditCourtPage(courtId: court['id'])),
                            );
                            _handleNavigationResult(result);
                          });
                    },
                  ),
                ),
      floatingActionButton: _courts.isEmpty ? null : FloatingActionButton.extended( // Esconde se vazio pois já tem botão no centro
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditCourtPage()),
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

// ============================================================================
// ABA AGENDA (RF04, RF07) - PAINEL DE CONTROLE
// ============================================================================
class OwnerAgendaTab extends StatefulWidget {
  const OwnerAgendaTab({super.key});
  @override
  State<OwnerAgendaTab> createState() => _OwnerAgendaTabState();
}

class _OwnerAgendaTabState extends State<OwnerAgendaTab> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _handleNavigationResult(dynamic result) async {
    if (result == true && mounted) {
      await _fetchBookings();
    }
  }

  Future<void> _fetchBookings() async {
    if (!mounted) return;
    if (_bookings.isEmpty) setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/bookings/owner');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $idToken'});

      if (response.statusCode == 200) {
        if (mounted) {
          // Ordenação: Pendentes primeiro, depois por data
          List<dynamic> loaded = jsonDecode(response.body);
          loaded.sort((a, b) {
             // Prioridade para Pendentes
             bool aPendente = (a['status'] ?? '').toLowerCase() == 'pendente';
             bool bPendente = (b['status'] ?? '').toLowerCase() == 'pendente';
             if (aPendente && !bPendente) return -1;
             if (!aPendente && bPendente) return 1;
             
             // Desempate por data (mais recente primeiro)
             // (Simplificação aqui, idealmente converteria timestamp)
             return 0;
          });

          setState(() {
            _bookings = loaded;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Falha ao carregar reservas.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar agenda.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBookingTimestamp(dynamic timestamp) {
    DateTime? startTime;
    if (timestamp is Map && timestamp['_seconds'] != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      startTime = DateTime.tryParse(timestamp);
    }

    if (startTime != null) {
      return DateFormat('dd/MM/yy HH:mm', 'pt_BR').format(startTime);
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Agenda de Reservas', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black87),
                onPressed: _fetchBookings,
                tooltip: 'Atualizar')
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bookings.isEmpty
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Sua agenda está livre.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                          onPressed: _fetchBookings,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Atualizar'))
                    ],
                  ))
                : RefreshIndicator(
                    onRefresh: _fetchBookings,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _bookings.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        
                        final quadraNome = booking['quadraNome'] ?? booking['courtId'] ?? 'Quadra N/A';
                        final clienteNome = booking['userName'] ?? booking['userId'] ?? 'Cliente N/A';
                        final horarioFormatado = _formatBookingTimestamp(booking['startTime']);
                        final status = booking['status'] ?? 'N/A';

                        return BookingCardOwner(
                          quadra: quadraNome,
                          cliente: clienteNome,
                          horario: horarioFormatado,
                          status: status,
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      BookingDetailsPage(booking: booking)),
                            );
                            _handleNavigationResult(result);
                          },
                        );
                      },
                    ),
                  ));
  }
}

// ============================================================================
// ABA PERFIL (RF02) - ESTILO MODERNO
// ============================================================================
class OwnerProfileTab extends StatelessWidget {
  const OwnerProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Dono do Espaço';
    final userEmail = user?.email ?? 'email@exemplo.com';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
          title: const Text('Meu Perfil', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white, 
          elevation: 0
      ),
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
                    child: user?.photoURL != null 
                        ? ClipOval(child: Image.network(user!.photoURL!, fit: BoxFit.cover, width: 100, height: 100))
                        : const Icon(Icons.store, size: 50, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(userName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(userEmail, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),
          
          // Menu Options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildProfileOption(context, 'Editar Perfil', Icons.edit_outlined, const EditOwnerProfilePage()),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildProfileOption(context, 'Configurações de Pagamento', Icons.account_balance_wallet_outlined, const PaymentSettingsPage()),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildProfileOption(context, 'Relatórios & Métricas', Icons.bar_chart_outlined, const ReportsPage()),
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
// HOME PAGE PRINCIPAL DO DONO (WRAPPER)
// ============================================================================
class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  int _selectedIndex = 0;
  final GlobalKey<_MyCourtsTabState> myCourtsTabKey = GlobalKey<_MyCourtsTabState>();
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = <Widget>[
      MyCourtsTab(key: myCourtsTabKey), 
      const OwnerAgendaTab(),
      const OwnerProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _selectedIndex,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.store_mall_directory_outlined),
                label: 'Espaços'),
            BottomNavigationBarItem(
                icon: Icon(Icons.event_note_outlined), label: 'Agenda'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET: CARD DE QUADRA DO DONO (VISUAL PREMIUM)
// ============================================================================
class OwnedCourtCard extends StatelessWidget {
  final String courtId;
  final String nome;
  final String endereco;
  final String status;
  final VoidCallback? onTap;

  const OwnedCourtCard({
    super.key,
    required this.courtId,
    required this.nome,
    required this.endereco,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = 'https://placehold.co/300x200/2E7D32/FFFFFF/png?text=${Uri.encodeComponent(nome)}&font=roboto';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Imagem Pequena
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(endereco, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: Colors.green[400]),
                          const SizedBox(width: 6),
                          Text('Ativo', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      )
                    ],
                  ),
                ),
                
                // Ícone Editar
                const Icon(Icons.edit_square, color: AppTheme.primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET: CARD DE RESERVA DO DONO (USADO NA AGENDA)
// ============================================================================
class BookingCardOwner extends StatelessWidget {
  final String quadra, cliente, horario, status;
  final VoidCallback? onTap;

  const BookingCardOwner({
    super.key,
    required this.quadra,
    required this.cliente,
    required this.horario,
    required this.status,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada': return Colors.green[700]!;
      case 'pendente': return Colors.orange[800]!;
      case 'cancelada': return Colors.red[700]!;
      default: return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada': return Colors.green[50]!;
      case 'pendente': return Colors.orange[50]!;
      case 'cancelada': return Colors.red[50]!;
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        // Borda lateral colorida para indicar status rapidamente
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(quadra, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                      child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(cliente, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(horario, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}