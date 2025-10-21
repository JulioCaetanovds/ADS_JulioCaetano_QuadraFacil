// lib/features/home/presentation/pages/add_edit_court_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quadrafacil/core/config.dart'; // Importamos nossa configuração de URL
import 'package:quadrafacil/core/theme/app_theme.dart';

class AddEditCourtPage extends StatefulWidget {
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

  bool _isLoadingData = true; // Loading para buscar dados
  bool _isSaving = false; // Loading para o botão salvar
  bool _isDeleting = false;
  bool get isEditing => widget.courtId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _fetchCourtDetails();
    } else {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _fetchCourtDetails() async {
    // ... (código inalterado para buscar detalhes) ...
     try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);
      
      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}'); // Usa AppConfig
      
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
        throw Exception('Falha ao carregar detalhes da quadra: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // --- NOVA FUNÇÃO PARA SALVAR ---
  Future<void> _handleSave() async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      // Prepara os dados do formulário
      final courtData = {
        'nome': _nameController.text,
        'descricao': _descriptionController.text,
        'esporte': _sportsController.text,
        'endereco': _addressController.text,
        'regras': _rulesController.text,
      };

      http.Response response;
      if (isEditing) {
        // --- ATUALIZAR (PUT) ---
        final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}');
        response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode(courtData),
        );
      } else {
        // --- CRIAR (POST) ---
        final url = Uri.parse('${AppConfig.apiUrl}/courts');
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode(courtData),
        );
      }

      // Verifica a resposta da API
      if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quadra ${isEditing ? 'atualizada' : 'cadastrada'} com sucesso!'), backgroundColor: Colors.green),
        );
        // Volta para a tela anterior, passando 'true' para indicar que a lista deve ser atualizada
        Navigator.of(context).pop(true); 
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao salvar quadra.');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- NOVA FUNÇÃO PARA DELETAR ---
  Future<void> _handleDelete() async {
    // 1. Mostrar diálogo de confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir este espaço? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Não exclui
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirma exclusão
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    // Se o usuário não confirmou, sai da função
    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}');
      
      final response = await http.delete( // Usa o método DELETE
        url,
        headers: { 'Authorization': 'Bearer $idToken' },
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quadra excluída com sucesso!'), backgroundColor: Colors.green),
        );
        // Volta para a tela anterior, passando 'true' para indicar que a lista deve ser atualizada
        Navigator.of(context).pop(true);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao excluir quadra.');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
  // ------------------------------

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
      body: _isLoadingData // Mostra loading inicial
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome do espaço *'),
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
                TextFormField(
                  controller: _sportsController,
                  decoration: const InputDecoration(labelText: 'Esportes (separados por vírgula) *'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Endereço Completo *'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rulesController,
                  decoration: const InputDecoration(labelText: 'Regras de utilização'),
                  maxLines: 2,
                ),
                const SizedBox(height: 48),
                
                // Botão de Salvar atualizado
                ElevatedButton(
                  onPressed: _isSaving || _isDeleting ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR ESPAÇO'),
                ),
                
                // --- BOTÃO DELETAR ADICIONADO ---
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isDeleting || _isSaving ? null : _handleDelete,
                    icon: _isDeleting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text('Excluir Espaço'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}