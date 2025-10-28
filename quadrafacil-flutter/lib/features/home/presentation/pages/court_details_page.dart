import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for initializeDateFormatting

import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
// Import from shared widgets
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

class CourtDetailsPage extends StatefulWidget {
  // Recebe o ID e nome da quadra
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
  DateTime _selectedDate = DateTime.now(); // Data selecionada na AgendaTabContent
  TimeOfDay? _selectedTimeSlot; // Horário selecionado na AgendaTabContent

  @override
  void initState() {
    super.initState();
    // Garante que a formatação pt_BR está disponível
    // Note: A inicialização principal já está no main.dart
    // initializeDateFormatting('pt_BR', null);
    _availabilityFuture = _fetchAvailability();
  }

  Future<AvailabilityInfo> _fetchAvailability() async {
    // Busca disponibilidade da API
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}/availability');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return AvailabilityInfo(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao carregar disponibilidade: ${response.body}');
      }
    } catch (e) {
      // Retorna o erro para o FutureBuilder tratar
      throw Exception('Erro de conexão ao buscar disponibilidade: ${e.toString()}');
    }
  }

  // Callback chamado pela AgendaTabContent quando um horário é selecionado/desselecionado
  void _onTimeSlotSelected(DateTime date, TimeOfDay? timeSlot) {
    // Atualiza o estado desta página (pai) para guardar a seleção
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = timeSlot;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Número de abas
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            // Constrói a barra superior que encolhe (SliverAppBar)
            return <Widget>[
              SliverAppBar(
                expandedHeight: 220.0, // Altura quando expandida
                floating: false, // Não flutua ao rolar para baixo
                pinned: true, // Mantém a barra visível quando encolhida
                stretch: true, // Efeito de esticar ao puxar além do limite
                iconTheme: const IconThemeData(color: Colors.white), // Cor do ícone de voltar
                title: Text(widget.courtName, style: const TextStyle(color: Colors.white)), // Usa o nome recebido
                backgroundColor: AppTheme.primaryColor, // Cor de fundo quando encolhida
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Imagem de fundo
                      Image.asset(
                        'assets/images/placeholder_quadra.png', // Placeholder local
                        fit: BoxFit.cover,
                      ),
                      // Gradiente para contraste
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6), // Escuro no topo
                              Colors.transparent,
                              Colors.black.withOpacity(0.8), // Escuro na base
                            ],
                            stops: const [0.0, 0.4, 1.0], // Ajuste do gradiente
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Abas na parte inferior da SliverAppBar
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'SOBRE'),
                    Tab(text: 'AGENDA'),
                    Tab(text: 'PARTIDAS'),
                  ],
                  labelColor: Colors.white, // Cor do texto da aba ativa
                  unselectedLabelColor: Colors.white70, // Cor do texto das abas inativas
                  indicatorColor: Colors.white, // Cor da linha indicadora
                  indicatorWeight: 3.0, // Espessura da linha
                ),
              ),
            ];
          },
          // Conteúdo principal que rola abaixo da SliverAppBar
          body: TabBarView(
            children: [
              // --- Aba Sobre ---
              ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Text('Descrição', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Quadra poliesportiva coberta, ideal para futsal e vôlei. Vestiários e iluminação de LED inclusos.'), // Exemplo
                  SizedBox(height: 24),
                  Text('Regras de Utilização', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('- Obrigatório uso de tênis de futsal.\n- Proibido consumo de bebidas alcoólicas na quadra.'), // Exemplo
                  SizedBox(height: 80), // Espaço extra para o FAB não cobrir o texto
                ],
              ),

              // --- Aba Agenda (Usa FutureBuilder) ---
              FutureBuilder<AvailabilityInfo>(
                future: _availabilityFuture, // O Future que busca os dados
                builder: (context, snapshot) {
                  // Enquanto espera os dados
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Se deu erro na busca
                  else if (snapshot.hasError) {
                    return Center(
                        child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Erro ao carregar agenda: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                    ));
                  }
                  // Se os dados chegaram com sucesso
                  else if (snapshot.hasData) {
                    return AgendaTabContent(
                      availability: snapshot.data!, // Passa os dados para o widget filho
                      onTimeSlotSelected: _onTimeSlotSelected, // Passa a função callback
                      initialDate: _selectedDate, // Passa a data atual selecionada
                    );
                  }
                  // Caso padrão (pouco provável de acontecer)
                  else {
                    return const Center(
                        child: Text('Nenhuma informação de agenda disponível.'));
                  }
                },
              ),

              // --- Aba Partidas ---
              ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Text('Partidas abertas nesta quadra:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  // Usa o widget importado da pasta shared
                  OpenMatchCard(
                      vagas: 2,
                      esporte: 'Futsal',
                      horario: '20:00',
                      quadra: 'Quadra Central'), // Exemplo
                  // Adicionar mais partidas se houver...
                   SizedBox(height: 80), // Espaço extra para o FAB
                ],
              ),
            ],
          ),
        ),
        // Botão flutuante para reservar
        floatingActionButton: _selectedTimeSlot != null // Só aparece se um horário for selecionado
            ? FloatingActionButton.extended(
                onPressed: () {
                  // Navega para a página de confirmação, passando os dados
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => BookingPage(
                              courtId: widget.courtId,
                              courtName: widget.courtName,
                              selectedDate: _selectedDate,
                              selectedTimeSlot: _selectedTimeSlot!,
                            )),
                  );
                },
                // Exibe a hora selecionada no botão
                label: Text(
                    'Reservar ${DateFormat('HH:mm').format(DateTime(0, 1, 1, _selectedTimeSlot!.hour, _selectedTimeSlot!.minute))}'),
                icon: const Icon(Icons.calendar_month_outlined),
                // Estilo vem do tema global
              )
            : null, // O botão fica oculto se nenhum horário estiver selecionado
      ),
    );
  }
}

// --- WIDGET PARA O CONTEÚDO DA ABA AGENDA ---
class AgendaTabContent extends StatefulWidget {
  final AvailabilityInfo availability;
  final Function(DateTime date, TimeOfDay? timeSlot) onTimeSlotSelected; // Callback para notificar o pai
  final DateTime initialDate; // Recebe a data inicial do pai

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
  late DateTime _selectedDate; // Data atualmente exibida
  TimeOfDay? _selectedTimeSlot; // Horário selecionado pelo usuário

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate; // Usa a data inicial vinda do pai
  }

  // Helper para obter a chave do dia da semana ('segunda', 'terca', etc.)
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

  // Gera a lista de slots de horário disponíveis para um dia
  List<TimeOfDay> _generateTimeSlots(String startTimeStr, String endTimeStr) {
    try {
      // Converte string "HH:MM" para TimeOfDay
      TimeOfDay parseTime(String timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      TimeOfDay startTime = parseTime(startTimeStr);
      TimeOfDay endTime = parseTime(endTimeStr);
      List<TimeOfDay> slots = [];

      // Cria um DateTime para facilitar a iteração de hora em hora
      DateTime current = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, startTime.hour, startTime.minute);
      DateTime end = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, endTime.hour, endTime.minute);

      // Garante que só mostre horários futuros se for hoje
      DateTime now = DateTime.now();
      if (DateUtils.isSameDay(_selectedDate, now)) {
        // Se a hora atual já passou do horário de início, ajusta o início
        if (now.isAfter(current)) {
           // Ajusta para a próxima hora cheia após a hora atual
           current = DateTime(now.year, now.month, now.day, now.hour + 1);
        }
      }

      // Gera slots de 1 em 1 hora até o horário final
      while (current.isBefore(end)) {
        slots.add(TimeOfDay.fromDateTime(current));
        current = current.add(const Duration(hours: 1));
      }
      return slots;
    } catch (e) {
      print("Erro ao gerar slots de horário: $e");
      return []; // Retorna lista vazia em caso de erro
    }
  }

  // Formata a data para exibição amigável ("Hoje", "Amanhã" ou "dd/MM (Dia)")
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
    // Busca os dados de disponibilidade para o dia selecionado
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
        // --- Seletor de Data ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              // Desabilita voltar se a data for hoje
              onPressed: DateUtils.isSameDay(_selectedDate, DateTime.now())
                  ? null
                  : () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        _selectedTimeSlot = null; // Reseta horário ao mudar data
                      });
                      widget.onTimeSlotSelected(_selectedDate, _selectedTimeSlot); // Notifica o pai
                    },
            ),
            // Exibe a data formatada
            Text(
              _formatDate(_selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                 setState(() {
                   _selectedDate = _selectedDate.add(const Duration(days: 1));
                   _selectedTimeSlot = null; // Reseta horário ao mudar data
                 });
                 widget.onTimeSlotSelected(_selectedDate, _selectedTimeSlot); // Notifica o pai
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- Exibição dos Horários ou Mensagem ---
        if (isClosed) // Se estiver fechado no dia selecionado
          Center(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Text('Fechado neste dia.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ))
        else if (timeSlots.isEmpty) // Se estiver aberto, mas sem horários futuros
          Center(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Text('Nenhum horário disponível para ${DateFormat('dd/MM').format(_selectedDate)}.', // Mais específico
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ))
        else // Se estiver aberto e com horários
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Horários disponíveis (R\$ ${pricePerHour.toStringAsFixed(2).replaceAll('.', ',')} / hora):',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Usa Wrap para organizar os botões de horário
              Wrap(
                spacing: 8.0, // Espaçamento horizontal entre os botões
                runSpacing: 8.0, // Espaçamento vertical entre as linhas de botões
                children: timeSlots.map((time) {
                  final isSelected = _selectedTimeSlot == time;
                  // Formata a hora para HH:MM
                  final formattedTime = DateFormat('HH:mm').format(DateTime(0,1,1,time.hour, time.minute));

                  return ChoiceChip(
                    label: Text(formattedTime),
                    selected: isSelected,
                    onSelected: (selected) {
                      final newTimeSlot = selected ? time : null;
                      setState(() {
                        _selectedTimeSlot = newTimeSlot; // Atualiza o estado local
                      });
                      // Notifica o widget pai sobre a seleção
                      widget.onTimeSlotSelected(_selectedDate, newTimeSlot);
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    backgroundColor: Colors.grey[100],
                    // Estilo da borda para indicar seleção
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300)),
                    showCheckmark: false, // Remove o checkmark padrão
                  );
                }).toList(),
              ),
              const SizedBox(height: 80), // Espaço para o FAB não cobrir
            ],
          ),
      ],
    );
  }
}

