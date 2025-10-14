// lib/features/owner_panel/presentation/pages/add_edit_court_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

class AddEditCourtPage extends StatelessWidget {
  // Para simular a edição, podemos receber um nome de quadra
  final String? courtName;

  const AddEditCourtPage({super.key, this.courtName});

  @override
  Widget build(BuildContext context) {
    // A tela muda o título se estivermos editando ou adicionando
    final isEditing = courtName != null;
    final title = isEditing ? 'Editar Espaço' : 'Adicionar Novo Espaço';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Campo para Nome do Espaço
          TextFormField(
            initialValue: courtName,
            decoration: const InputDecoration(labelText: 'Nome do espaço'),
          ),
          const SizedBox(height: 16),

          // Campo para Descrição
          TextFormField(
            decoration: const InputDecoration(labelText: 'Descrição'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Placeholder para Upload de Fotos
          const Text('Fotos do Espaço', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: AppTheme.hintColor),
                  SizedBox(height: 8),
                  Text('Adicionar fotos', style: TextStyle(color: AppTheme.hintColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Campos para Esportes e Endereço
          TextFormField(
            decoration: const InputDecoration(labelText: 'Esportes (separados por vírgula)'),
            initialValue: isEditing ? 'Futsal, Tênis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Endereço Completo'),
             initialValue: isEditing ? 'Centro, Passo Fundo' : null,
          ),
          const SizedBox(height: 16),
           TextFormField(
            decoration: const InputDecoration(labelText: 'Regras de utilização'),
            maxLines: 2,
          ),
          const SizedBox(height: 48),

          // Botão de Salvar
          ElevatedButton(
            onPressed: () {
              // Lógica para salvar os dados virá aqui
              Navigator.of(context).pop();
            },
            child: Text(isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR ESPAÇO'),
          ),
        ],
      ),
    );
  }
}