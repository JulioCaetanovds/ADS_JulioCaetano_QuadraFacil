// lib/features/owner_panel/presentation/pages/payment_settings_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class PaymentSettingsPage extends StatelessWidget {
  const PaymentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações de Pagamento')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Chave PIX',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta será a chave utilizada para gerar os QR Codes de pagamento para os seus clientes. Certifique-se de que ela está correta.',
            style: TextStyle(color: AppTheme.hintColor),
          ),
          const SizedBox(height: 24),
          // Simulação de um Dropdown para tipo de chave
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Tipo de Chave'),
            initialValue: 'email',
            items: const [
              DropdownMenuItem(value: 'email', child: Text('E-mail')),
              DropdownMenuItem(value: 'cpf_cnpj', child: Text('CPF/CNPJ')),
              DropdownMenuItem(value: 'celular', child: Text('Celular')),
              DropdownMenuItem(value: 'aleatoria', child: Text('Chave Aleatória')),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: 'dono@email.com',
            decoration: const InputDecoration(labelText: 'Sua Chave PIX'),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('SALVAR CONFIGURAÇÕES'),
          ),
        ],
      ),
    );
  }
}