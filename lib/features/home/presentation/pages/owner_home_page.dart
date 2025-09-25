// lib/features/home/presentation/pages/owner_home_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  int _selectedIndex = 0;

  // Telas placeholder para cada aba
  final List<Widget> _tabs = [
    const Center(child: Text('Aba Meus Espaços (Dono)')),
    const Center(child: Text('Aba Agenda/Reservas (Dono)')),
    const Center(child: Text('Aba Perfil (Dono)')),
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
        title: const Text('Painel do Dono'),
        automaticallyImplyLeading: false,
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.store_mall_directory_outlined),
            label: 'Meus Espaços',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Agenda',
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
