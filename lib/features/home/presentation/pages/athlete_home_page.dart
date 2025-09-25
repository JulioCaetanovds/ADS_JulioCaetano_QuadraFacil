// lib/features/home/presentation/pages/athlete_home_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class AthleteHomePage extends StatefulWidget {
  const AthleteHomePage({super.key});

  @override
  State<AthleteHomePage> createState() => _AthleteHomePageState();
}

class _AthleteHomePageState extends State<AthleteHomePage> {
  int _selectedIndex = 0;

  // Telas placeholder para cada aba
  final List<Widget> _tabs = [
    const Center(child: Text('Aba Explorar (Atleta)')),
    const Center(child: Text('Aba Minhas Reservas (Atleta)')),
    const Center(child: Text('Aba Perfil (Atleta)')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quadra Fácil'),
        automaticallyImplyLeading: false,
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Minhas Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
