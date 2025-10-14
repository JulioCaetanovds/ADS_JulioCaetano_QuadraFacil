// lib/features/home/presentation/pages/court_details_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:quadrafacil/features/home/presentation/pages/athlete_home_page.dart';
import 'package:quadrafacil/features/home/presentation/pages/booking_page.dart'; // 1. Import da nova página

class CourtDetailsPage extends StatelessWidget {
  const CourtDetailsPage({super.key});

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

                // 2. Título agora com a cor branca
                title: const Text('Quadra Central', style: TextStyle(color: Colors.white)),
                
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
                            stops: const [0.0, 0.5, 1.0],
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
                ),
              ),
            ];
          },
          body: TabBarView(
            // ... (O conteúdo das abas continua o mesmo)
            children: [
              ListView(padding: const EdgeInsets.all(16), children: const [
                Text('Descrição', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Quadra poliesportiva coberta, ideal para futsal e vôlei. Vestiários e iluminação de LED inclusos.'),
                SizedBox(height: 24),
                Text('Regras de Utilização', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('- Obrigatório uso de tênis de futsal.\n- Proibido consumo de bebidas alcoólicas na quadra.'),
                SizedBox(height: 80),
              ]),
              const Center(child: Text('Aqui ficará a grade de horários para reserva.')),
              ListView(padding: const EdgeInsets.all(16), children: const [
                Text('Partidas abertas nesta quadra:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                OpenMatchCard(vagas: 2, esporte: 'Futsal', horario: '20:00', quadra: 'Quadra Central'),
              ]),
            ],
          ),
        ),
        // 3. Botão agora navega para a nova página
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const BookingPage()),
            );
          },
          label: const Text('Reservar Horário'),
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ),
    );
  }
}