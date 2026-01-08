// lib/features/home/presentation/pages/court_details_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/home/presentation/pages/booking_page.dart';

class AvailabilityInfo {
  final Map<String, dynamic> availabilityData;
  AvailabilityInfo(this.availabilityData);
  Map<String, dynamic>? getDay(String dayKey) => availabilityData[dayKey];
}

class CourtDetailsInfo {
  final Map<String, dynamic> detailsData;
  final String? ownerPixKey;
  CourtDetailsInfo(this.detailsData, this.ownerPixKey);
}

class CourtDetailsPage extends StatefulWidget {
  final String courtId;
  final String courtName;

  const CourtDetailsPage({
    super.key,
    required this.courtId,
    required this.courtName,
  });

  @override
  State<CourtDetailsPage> createState() => _CourtDetailsPageState();
}

class _CourtDetailsPageState extends State<CourtDetailsPage> {
  Future<AvailabilityInfo>? _availabilityFuture;
  Future<CourtDetailsInfo>? _detailsFuture;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTimeSlot;
  String? _ownerPixKey;

  @override
  void initState() {
    super.initState();
    _availabilityFuture = _fetchAvailability();
    _detailsFuture = _fetchPublicDetails();
  }

  Future<AvailabilityInfo> _fetchAvailability() async {
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}/availability');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return AvailabilityInfo(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao carregar disponibilidade.');
      }
    } catch (e) {
      throw Exception('Erro de conexão.');
    }
  }

  Future<CourtDetailsInfo> _fetchPublicDetails() async {
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}/public-details');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pixKey = data['ownerPixKey'] as String?;
        if (mounted) setState(() => _ownerPixKey = pixKey);
        return CourtDetailsInfo(data, pixKey);
      } else {
        throw Exception('Falha ao carregar detalhes.');
      }
    } catch (e) {
      throw Exception('Erro de conexão.');
    }
  }

  void _onTimeSlotSelected(DateTime date, TimeOfDay? timeSlot) {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = timeSlot;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Imagem de placeholder bonita baseada no nome
    final imageUrl = 'https://placehold.co/600x400/2E7D32/FFFFFF/png?text=${Uri.encodeComponent(widget.courtName)}&font=roboto';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const BackButton(color: Colors.white),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  // --- A CORREÇÃO ESTÁ AQUI ---
                  // Definimos padding inferior de 60px (48px da TabBar + margem)
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 60), 
                  title: Text(
                    widget.courtName,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Tamanho fixo ajuda a não quebrar
                      shadows: [Shadow(color: Colors.black45, blurRadius: 5)]
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(imageUrl, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: const TabBar(
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [Tab(text: 'SOBRE'), Tab(text: 'AGENDA'), Tab(text: 'PARTIDAS')],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // ABA SOBRE
              FutureBuilder<CourtDetailsInfo>(
                future: _detailsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasData) {
                    final details = snapshot.data!.detailsData;
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Text('Descrição', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(details['descricao'] ?? 'Sem descrição.', style: const TextStyle(color: Colors.black87, height: 1.5)),
                        const SizedBox(height: 24),
                        const Text('Regras', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Text(details['regras'] ?? 'Sem regras específicas.', style: TextStyle(color: Colors.grey[700])),
                        ),
                        const SizedBox(height: 80),
                      ],
                    );
                  }
                  return const Center(child: Text('Erro ao carregar detalhes.'));
                },
              ),

              // ABA AGENDA
              FutureBuilder<AvailabilityInfo>(
                future: _availabilityFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasData) {
                    return AgendaTabContent(
                      availability: snapshot.data!,
                      onTimeSlotSelected: _onTimeSlotSelected,
                      initialDate: _selectedDate,
                    );
                  }
                  return const Center(child: Text('Agenda indisponível.'));
                },
              ),

              // ABA PARTIDAS (Placeholder por enquanto)
              ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Nenhuma partida pública nesta quadra.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: _selectedTimeSlot != null
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => BookingPage(
                      courtId: widget.courtId,
                      courtName: widget.courtName,
                      selectedDate: _selectedDate,
                      selectedTimeSlot: _selectedTimeSlot!,
                      ownerPixKey: _ownerPixKey,
                    ),
                  ));
                },
                label: Text('RESERVAR  ${_selectedTimeSlot!.format(context)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                icon: const Icon(Icons.check_circle),
                backgroundColor: AppTheme.primaryColor,
              )
            : null,
      ),
    );
  }
}

// --- COMPONENTE DE AGENDA (MANTIDO E REFATORADO VISUALMENTE) ---
class AgendaTabContent extends StatefulWidget {
  final AvailabilityInfo availability;
  final Function(DateTime date, TimeOfDay? timeSlot) onTimeSlotSelected;
  final DateTime initialDate;

  const AgendaTabContent({super.key, required this.availability, required this.onTimeSlotSelected, required this.initialDate});

  @override
  State<AgendaTabContent> createState() => _AgendaTabContentState();
}

class _AgendaTabContentState extends State<AgendaTabContent> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  String _getDayKey(DateTime date) {
    const days = ['domingo', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado'];
    return days[date.weekday % 7]; // Fix para Domingo ser 0 ou 7 dependendo da lib
  }

  List<TimeOfDay> _generateTimeSlots(String startTimeStr, String endTimeStr) {
    try {
      TimeOfDay parse(String s) { final p = s.split(':'); return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])); }
      final start = parse(startTimeStr);
      final end = parse(endTimeStr);
      
      final slots = <TimeOfDay>[];
      var current = DateTime(2024, 1, 1, start.hour, start.minute);
      final endTime = DateTime(2024, 1, 1, end.hour, end.minute);

      // Filtro de hora passada (se for hoje)
      final now = DateTime.now();
      if (DateUtils.isSameDay(_selectedDate, now)) {
         if (now.hour >= current.hour) {
            current = DateTime(2024, 1, 1, now.hour + 1, 0); // Próxima hora cheia
         }
      }

      while (current.isBefore(endTime)) {
        slots.add(TimeOfDay(hour: current.hour, minute: current.minute));
        current = current.add(const Duration(hours: 1));
      }
      return slots;
    } catch (e) { return []; }
  }

  @override
  Widget build(BuildContext context) {
    final dayKey = _getDayKey(_selectedDate);
    // IMPORTANTE: Mapeamento manual para garantir compatibilidade com o backend (segunda, terca...)
    // O backend usa keys como 'segunda', 'terca'. O DateTime.weekday 1 é Segunda.
    final keys = ['', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado', 'domingo'];
    final correctKey = keys[_selectedDate.weekday];

    final dayData = widget.availability.getDay(correctKey);
    final isClosed = dayData == null || (dayData['isOpen'] == false); // Checa se existe e se está aberto
    
    final timeSlots = isClosed ? <TimeOfDay>[] : _generateTimeSlots(dayData['startTime'], dayData['endTime']);
    final price = isClosed ? 0.0 : (dayData['pricePerHour'] ?? 0.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Seletor de Data
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: DateUtils.isSameDay(_selectedDate, DateTime.now()) 
                    ? null 
                    : () { setState(() { _selectedDate = _selectedDate.subtract(const Duration(days: 1)); _selectedTimeSlot = null; }); widget.onTimeSlotSelected(_selectedDate, null); },
              ),
              Text(DateFormat('EEEE, dd/MM', 'pt_BR').format(_selectedDate).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () { setState(() { _selectedDate = _selectedDate.add(const Duration(days: 1)); _selectedTimeSlot = null; }); widget.onTimeSlotSelected(_selectedDate, null); },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Lista de Horários
        if (isClosed)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Fechado neste dia.', style: TextStyle(color: Colors.grey))))
        else if (timeSlots.isEmpty)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Sem horários disponíveis hoje.', style: TextStyle(color: Colors.grey))))
        else ...[
          Text('Horários (R\$ ${price.toStringAsFixed(2)} / h)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: timeSlots.map((time) {
              final isSelected = _selectedTimeSlot == time;
              return ChoiceChip(
                label: Text(time.format(context), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!)),
                onSelected: (sel) {
                  setState(() => _selectedTimeSlot = sel ? time : null);
                  widget.onTimeSlotSelected(_selectedDate, _selectedTimeSlot);
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}