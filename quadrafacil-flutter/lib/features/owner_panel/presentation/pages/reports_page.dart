// lib/features/owner_panel/presentation/pages/reports_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Relatórios', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exportando PDF...'), backgroundColor: Colors.blue),
              );
            },
            tooltip: 'Exportar PDF',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seletor de Período (Visual)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Visão Geral', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[300]!)),
                  child: const Row(
                    children: [
                      Text('Últimos 7 dias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                )
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
              childAspectRatio: 1.4,
              children: const [
                _KpiCard(title: 'Faturamento', value: 'R\$ 1.250,00', icon: Icons.attach_money, color: Colors.green),
                _KpiCard(title: 'Reservas', value: '15', icon: Icons.book_online, color: Colors.blue),
                _KpiCard(title: 'Ocupação', value: '82%', icon: Icons.pie_chart, color: Colors.orange),
                _KpiCard(title: 'Novos Clientes', value: '+4', icon: Icons.person_add, color: Colors.purple),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Gráfico Simulado (Barras)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Desempenho da Semana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end, // Alinha barras embaixo
                    children: [
                      _ChartBar(label: 'Seg', height: 60, color: Colors.blue[100]!),
                      _ChartBar(label: 'Ter', height: 80, color: Colors.blue[200]!),
                      const _ChartBar(label: 'Qua', height: 120, color: AppTheme.primaryColor),
                      _ChartBar(label: 'Qui', height: 90, color: Colors.blue[200]!),
                      const _ChartBar(label: 'Sex', height: 140, color: AppTheme.primaryColor),
                      const _ChartBar(label: 'Sáb', height: 160, color: Colors.green),
                      _ChartBar(label: 'Dom', height: 100, color: Colors.green[300]!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para os cards de KPI
class _KpiCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para Barra do Gráfico
class _ChartBar extends StatelessWidget {
  final String label;
  final double height;
  final Color color;

  const _ChartBar({required this.label, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}