// lib/features/home/presentation/pages/court_details_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/shared/widgets/open_match_card.dart';
import 'package:quadrafacil/features/home/presentation/pages/booking_page.dart';

// Modelo para guardar a disponibilidade parseada
class AvailabilityInfo {
  final Map<String, dynamic> availabilityData;
  AvailabilityInfo(this.availabilityData);

  Map<String, dynamic>? getDay(String dayKey) {
    return availabilityData[dayKey];
  }
}

// 1. NOVO Modelo para guardar os detalhes públicos
class CourtDetailsInfo {
  final Map<String, dynamic> detailsData;
  final String? ownerPixKey; // A chave PIX que buscamos

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
  // 2. Agora temos DOIS futures
  Future<AvailabilityInfo>? _availabilityFuture;
  Future<CourtDetailsInfo>? _detailsFuture; // Future para os detalhes e PIX

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTimeSlot;
  String? _ownerPixKey; // 3. Variável local para guardar a chave PIX

  @override
  void initState() {
    super.initState();
    // 4. Inicia as duas buscas
    _availabilityFuture = _fetchAvailability();
    _detailsFuture = _fetchPublicDetails();
  }

  // (Função _fetchAvailability sem alterações)
  Future<AvailabilityInfo> _fetchAvailability() async {
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}/availability');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return AvailabilityInfo(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao carregar disponibilidade: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao buscar disponibilidade: ${e.toString()}');
    }
  }

  // 5. NOVA Função para buscar Detalhes Públicos (incluindo PIX)
  Future<CourtDetailsInfo> _fetchPublicDetails() async {
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}/public-details');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pixKey = data['ownerPixKey'] as String?;
        // 6. Guarda a chave PIX no estado da página
        if (mounted) {
          setState(() {
            _ownerPixKey = pixKey;
          });
        }
        return CourtDetailsInfo(data, pixKey);
      } else {
        throw Exception('Falha ao carregar detalhes da quadra: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao buscar detalhes: ${e.toString()}');
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
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                stretch: true,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(widget.courtName, style: const TextStyle(color: Colors.white)),
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/placeholder_quadra.png',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'SOBRE'),
                    Tab(text: 'AGENDA'),
                    Tab(text: 'PARTIDAS'),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3.0,
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // --- Aba Sobre (Atualizada para usar FutureBuilder) ---
              // 7. Usa o _detailsFuture para preencher a Aba 'Sobre'
              FutureBuilder<CourtDetailsInfo>(
                future: _detailsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (snapshot.hasData) {
                    final details = snapshot.data!.detailsData;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('Descrição', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(details['descricao'] ?? 'Nenhuma descrição informada.'),
                        const SizedBox(height: 24),
                        const Text('Regras de Utilização', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(details['regras'] ?? 'Nenhuma regra informada.'),
                        const SizedBox(height: 80),
                      ],
                    );
                  }
                  return const Center(child: Text('Não foi possível carregar os detalhes.'));
                }
              ),

              // --- Aba Agenda (Sem alterações na lógica) ---
              FutureBuilder<AvailabilityInfo>(
                future: _availabilityFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  else if (snapshot.hasError) {
                    return Center(
                        child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Erro ao carregar agenda: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                    ));
                  }
                  else if (snapshot.hasData) {
                    return AgendaTabContent(
                      availability: snapshot.data!,
                      onTimeSlotSelected: _onTimeSlotSelected,
                      initialDate: _selectedDate,
                    );
                  }
                  else {
                    return const Center(
                        child: Text('Nenhuma informação de agenda disponível.'));
                  }
                },
              ),

              // --- Aba Partidas (Sem alterações) ---
              ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Text('Partidas abertas nesta quadra:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  OpenMatchCard(
                      vagas: 2,
                      esporte: 'Futsal',
                      horario: '20:00',
                      quadra: 'Quadra Central'),
                      SizedBox(height: 80), 
                ],
              ),
            ],
          ),
        ),
        // 8. Botão flutuante ATUALIZADO
        floatingActionButton: _selectedTimeSlot != null
            ? FloatingActionButton.extended(
                onPressed: () {
                  // 9. Passa a 'ownerPixKey' para a BookingPage
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => BookingPage(
                              courtId: widget.courtId,
                              courtName: widget.courtName,
                              selectedDate: _selectedDate,
                              selectedTimeSlot: _selectedTimeSlot!,
                              ownerPixKey: _ownerPixKey, // <-- PASSA A CHAVE PIX
                            )),
                  );
                },
                label: Text(
                    'Reservar ${DateFormat('HH:mm').format(DateTime(0, 1, 1, _selectedTimeSlot!.hour, _selectedTimeSlot!.minute))}'),
                icon: const Icon(Icons.calendar_month_outlined),
              )
            : null,
      ),
    );
  }
}

// --- WIDGET PARA O CONTEÚDO DA ABA AGENDA ---
// (Sem alterações, mantenha seu código da AgendaTabContent como está)
class AgendaTabContent extends StatefulWidget {
  final AvailabilityInfo availability;
  final Function(DateTime date, TimeOfDay? timeSlot) onTimeSlotSelected;
  final DateTime initialDate;

  const AgendaTabContent({
    super.key,
    required this.availability,
    required this.onTimeSlotSelected,
    required this.initialDate,
  });

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
    switch (date.weekday) {
      case 1: return 'segunda';
      case 2: return 'terca';
      case 3: return 'quarta';
      case 4: return 'quinta';
      case 5: return 'sexta';
      case 6: return 'sabado';
      case 7: return 'domingo';
      default: return '';
    }
  }

  List<TimeOfDay> _generateTimeSlots(String startTimeStr, String endTimeStr) {
    try {
      TimeOfDay parseTime(String timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      TimeOfDay startTime = parseTime(startTimeStr);
      TimeOfDay endTime = parseTime(endTimeStr);
      List<TimeOfDay> slots = [];

      DateTime current = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, startTime.hour, startTime.minute);
      DateTime end = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, endTime.hour, endTime.minute);

      DateTime now = DateTime.now();
      if (DateUtils.isSameDay(_selectedDate, now)) {
        if (now.isAfter(current)) {
          current = DateTime(now.year, now.month, now.day, now.hour + 1);
        }
      }

      while (current.isBefore(end)) {
        slots.add(TimeOfDay.fromDateTime(current));
        current = current.add(const Duration(hours: 1));
      }
      return slots;
    } catch (e) {
      print("Erro ao gerar slots de horário: $e");
      return []; 
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return 'Hoje (${DateFormat('EEEE', 'pt_BR').format(date)})';
    } else if (selectedDay == tomorrow) {
      return 'Amanhã (${DateFormat('EEEE', 'pt_BR').format(date)})';
    } else {
      return DateFormat('dd/MM (EEEE)', 'pt_BR').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayKey = _getDayKey(_selectedDate);
    final dayAvailability = widget.availability.getDay(dayKey);
    final isClosed = dayAvailability == null;
    final timeSlots = isClosed
        ? <TimeOfDay>[]
        : _generateTimeSlots(
            dayAvailability['startTime'], dayAvailability['endTime']);
    final pricePerHour =
        isClosed ? 0.0 : (dayAvailability['pricePerHour'] ?? 0.0);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: DateUtils.isSameDay(_selectedDate, DateTime.now())
                  ? null
                  : () {
                      setState(() {
                        _selectedDate =
                            _selectedDate.subtract(const Duration(days: 1));
                        _selectedTimeSlot = null; 
                      });
                      widget.onTimeSlotSelected(_selectedDate, _selectedTimeSlot);
                    },
            ),
            Text(
              _formatDate(_selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                  _selectedTimeSlot = null; 
                });
                widget.onTimeSlotSelected(_selectedDate, _selectedTimeSlot);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isClosed) 
          Center(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Text('Fechado neste dia.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ))
        else if (timeSlots.isEmpty)
          Center(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Text('Nenhum horário disponível para ${DateFormat('dd/MM').format(_selectedDate)}.', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ))
        else 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Horários disponíveis (R\$ ${pricePerHour.toStringAsFixed(2).replaceAll('.', ',')} / hora):',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0, 
                runSpacing: 8.0, 
                children: timeSlots.map((time) {
                  final isSelected = _selectedTimeSlot == time;
                  final formattedTime = DateFormat('HH:mm').format(DateTime(0,1,1,time.hour, time.minute));

                  return ChoiceChip(
                    label: Text(formattedTime),
                    selected: isSelected,
                    onSelected: (selected) {
                      final newTimeSlot = selected ? time : null;
                      setState(() {
                        _selectedTimeSlot = newTimeSlot; 
                      });
                      widget.onTimeSlotSelected(_selectedDate, newTimeSlot);
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300)),
                    showCheckmark: false, 
                  );
                }).toList(),
              ),
              const SizedBox(height: 80), 
            ],
          ),
      ],
    );
  }
}