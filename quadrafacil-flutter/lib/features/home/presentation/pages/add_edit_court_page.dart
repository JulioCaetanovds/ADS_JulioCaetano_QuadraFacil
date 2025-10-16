// lib/features/home/presentation/pages/add_edit_court_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quadrafacil/core/theme/app_theme.dart';

class AddEditCourtPage extends StatefulWidget {
  // A classe agora recebe 'courtId'
  final String? courtId;

  const AddEditCourtPage({super.key, this.courtId});

  @override
  State<AddEditCourtPage> createState() => _AddEditCourtPageState();
}

class _AddEditCourtPageState extends State<AddEditCourtPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sportsController = TextEditingController();
  final _addressController = TextEditingController();
  final _rulesController = TextEditingController();

  bool _isLoading = true;
  bool get isEditing => widget.courtId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _fetchCourtDetails();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCourtDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);
      
      // Lembre-se de usar o seu IP local
      final url = Uri.parse('http://192.168.10.196:3000/courts/${widget.courtId}');
      
      final response = await http.get(
        url,
        headers: { 'Authorization': 'Bearer $idToken' },
      );

      if (response.statusCode == 200 && mounted) {
        final courtData = jsonDecode(response.body);
        setState(() {
          _nameController.text = courtData['nome'] ?? '';
          _descriptionController.text = courtData['descricao'] ?? '';
          _sportsController.text = courtData['esporte'] ?? '';
          _addressController.text = courtData['endereco'] ?? '';
          _rulesController.text = courtData['regras'] ?? '';
        });
      } else {
        throw Exception('Falha ao carregar detalhes da quadra.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sportsController.dispose();
    _addressController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Espaço' : 'Adicionar Novo Espaço'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome do espaço'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                const Text('Fotos do Espaço', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_a_photo_outlined, color: AppTheme.hintColor),
                      SizedBox(height: 8),
                      Text('Adicionar fotos', style: TextStyle(color: AppTheme.hintColor)),
                  ],),),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _sportsController,
                  decoration: const InputDecoration(labelText: 'Esportes (separados por vírgula)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Endereço Completo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rulesController,
                  decoration: const InputDecoration(labelText: 'Regras de utilização'),
                   maxLines: 2,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    // Aqui virá a lógica para SALVAR (criar ou atualizar)
                    Navigator.of(context).pop();
                  },
                  child: Text(isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR ESPAÇO'),
                ),
              ],
            ),
    );
  }
}