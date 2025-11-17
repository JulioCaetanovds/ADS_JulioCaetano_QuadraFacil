// lib/features/owner_panel/presentation/pages/payment_settings_page.dart
import 'package:flutter/material.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';
import 'package:http/http.dart' as http; // 1. Imports necessários
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:quadrafacil/core/config.dart';

// 2. Convertido para StatefulWidget
class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({super.key});

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  final _pixKeyController = TextEditingController();
  bool _isLoading = true; // Loading da página
  bool _isSaving = false; // Loading do botão salvar

  @override
  void initState() {
    super.initState();
    _loadCurrentPixKey();
  }

  @override
  void dispose() {
    _pixKeyController.dispose();
    super.dispose();
  }

  // 3. Busca a chave PIX atual do Dono na API
  Future<void> _loadCurrentPixKey() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Dono não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/auth/me'); // API que já criamos
      final response = await http.get(url, headers: {'Authorization': 'Bearer $idToken'});

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final pixKey = data['user']['pixKey'];
        if (pixKey != null) {
          _pixKeyController.text = pixKey; // Preenche o campo
        }
      } else {
        throw Exception('Falha ao carregar dados do perfil.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 4. Salva a nova chave PIX na API
  Future<void> _savePixKey() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Dono não autenticado.');
      final idToken = await user.getIdToken(true);

      final url = Uri.parse('${AppConfig.apiUrl}/auth/me'); // API PUT que criamos
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'pixKey': _pixKeyController.text, // Envia a chave
        }),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chave PIX salva com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Volta para a tela de perfil
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao salvar chave PIX.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações de Pagamento')),
      // 5. Mostra o loading enquanto busca os dados
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                const Text(
                  'Sua Chave PIX',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta será a chave PIX (CPF, E-mail, Celular ou Aleatória) que o atleta usará para fazer o pagamento. A confirmação da reserva ainda é manual.',
                  style: TextStyle(color: AppTheme.hintColor),
                ),
                const SizedBox(height: 24),
                
                // 6. Removemos o Dropdown (simplificação)
                
                // 7. TextFormField agora usa um controller
                TextFormField(
                  controller: _pixKeyController,
                  decoration: const InputDecoration(labelText: 'Sua Chave PIX'),
                ),
                const SizedBox(height: 48),
                
                // 8. Botão de Salvar agora chama a API
                ElevatedButton(
                  onPressed: _isSaving ? null : _savePixKey,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('SALVAR CONFIGURAÇÕES'),
                ),
              ],
            ),
    );
  }
}