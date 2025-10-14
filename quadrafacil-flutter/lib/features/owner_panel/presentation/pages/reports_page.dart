// lib/features/owner_panel/presentation/pages/reports_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              // Lógica para exportar PDF (futura)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exportação para PDF em breve!')),
              );
            },
            tooltip: 'Exportar PDF',
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Seletor de Data
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {}, // Abriria o DatePicker
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('01/10/25'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('até'),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {}, // Abriria o DatePicker
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('06/10/25'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPIs (Indicadores Chave)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: const [
              _KpiCard(title: 'Faturamento', value: 'R\$ 1.250,00', icon: Icons.attach_money),
              _KpiCard(title: 'Reservas', value: '15', icon: Icons.book_online),
              _KpiCard(title: 'Ocupação', value: '82%', icon: Icons.pie_chart),
              _KpiCard(title: 'Novos Clientes', value: '4', icon: Icons.person_add),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Gráfico (Placeholder)
          const Text('Desempenho no Período', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Container(
            height: 200,
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Gráfico de Faturamento (em breve)')),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para os cards de KPI
class _KpiCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const _KpiCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(color: AppTheme.hintColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}