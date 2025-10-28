import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quadrafacil/core/config.dart'; // Importamos nossa configuração de URL
import 'package:quadrafacil/core/theme/app_theme.dart';

// Modelo simples para guardar os dados de disponibilidade de um dia
class AvailabilityDay {
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  TextEditingController priceController = TextEditingController();
  bool isOpen = false;

  AvailabilityDay({this.startTime, this.endTime, String? price, this.isOpen = false}) {
    // Garante que o preço use ponto como separador decimal
    priceController.text = price?.replaceAll(',', '.') ?? '';
  }

  // Limpa os recursos do controller
  void dispose() {
    priceController.dispose();
  }

  // Converte para JSON para enviar para a API
  Map<String, dynamic>? toJson() {
    if (!isOpen || startTime == null || endTime == null || priceController.text.isEmpty) {
      return null; // Retorna null se estiver fechado ou incompleto
    }
    try {
      String formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      // Converte vírgula para ponto antes de fazer o parse
      final priceValue = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
      return {
        'startTime': formatTime(startTime!),
        'endTime': formatTime(endTime!),
        'pricePerHour': priceValue,
      };
    } catch (e) {
      print("Erro ao converter disponibilidade para JSON: $e");
      return null;
    }
  }

  // Cria a partir de JSON vindo da API
  static AvailabilityDay fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AvailabilityDay(isOpen: false);
    }
    try {
      TimeOfDay parseTime(String timeStr) {
         final parts = timeStr.split(':');
         return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      // Formata o preço vindo da API para exibir corretamente
      final priceString = json['pricePerHour']?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      return AvailabilityDay(
        startTime: parseTime(json['startTime']),
        endTime: parseTime(json['endTime']),
        price: priceString,
        isOpen: true,
      );
    } catch(e) {
       print("Erro ao converter JSON para disponibilidade: $e");
       return AvailabilityDay(isOpen: false);
    }
  }
}


class AddEditCourtPage extends StatefulWidget {
  final String? courtId;
  const AddEditCourtPage({super.key, this.courtId});
  @override
  State<AddEditCourtPage> createState() => _AddEditCourtPageState();
}

class _AddEditCourtPageState extends State<AddEditCourtPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sportsController = TextEditingController();
  final _addressController = TextEditingController();
  final _rulesController = TextEditingController();

  final Map<String, AvailabilityDay> _availability = {
    'segunda': AvailabilityDay(),
    'terca': AvailabilityDay(),
    'quarta': AvailabilityDay(),
    'quinta': AvailabilityDay(),
    'sexta': AvailabilityDay(),
    'sabado': AvailabilityDay(),
    'domingo': AvailabilityDay(),
  };
  final List<String> _daysOfWeek = ['segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado', 'domingo'];

  bool _isLoadingData = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool get isEditing => widget.courtId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _fetchCourtDetailsAndAvailability();
    } else {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _fetchCourtDetailsAndAvailability() async {
    setState(() => _isLoadingData = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      // Busca Detalhes da Quadra
      final detailsUrl = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}');
      final detailsResponse = await http.get(detailsUrl, headers: {'Authorization': 'Bearer $idToken'});
      if (detailsResponse.statusCode != 200) throw Exception('Falha ao carregar detalhes: ${detailsResponse.body}');
      final courtData = jsonDecode(detailsResponse.body);

      // Busca Disponibilidade
      final availabilityUrl = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}/availability');
      final availabilityResponse = await http.get(availabilityUrl); // GET de disponibilidade pode ser público
      Map<String, dynamic> availabilityData = {};
      if (availabilityResponse.statusCode == 200) {
         availabilityData = jsonDecode(availabilityResponse.body);
      } else {
         print("Aviso: Falha ao carregar disponibilidade (${availabilityResponse.statusCode}). Usando dados vazios.");
      }


      if (mounted) {
        setState(() {
          _nameController.text = courtData['nome'] ?? '';
          _descriptionController.text = courtData['descricao'] ?? '';
          _sportsController.text = courtData['esporte'] ?? '';
          _addressController.text = courtData['endereco'] ?? '';
          _rulesController.text = courtData['regras'] ?? '';

           for (var day in _daysOfWeek) {
             _availability[day] = AvailabilityDay.fromJson(availabilityData[day]);
           }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);

      // 1. Salvar Detalhes da Quadra (PUT ou POST)
      final courtData = {
        'nome': _nameController.text,
        'descricao': _descriptionController.text,
        'esporte': _sportsController.text,
        'endereco': _addressController.text,
        'regras': _rulesController.text,
      };
      http.Response detailsResponse;
      late Uri detailsUrl;
      String courtIdToUse;

      if (isEditing) {
        detailsUrl = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}');
        detailsResponse = await http.put(detailsUrl, headers: {'Content-Type': 'application/json','Authorization': 'Bearer $idToken'}, body: jsonEncode(courtData));
        courtIdToUse = widget.courtId!;
      } else {
         detailsUrl = Uri.parse('${AppConfig.apiUrl}/courts');
         detailsResponse = await http.post(detailsUrl, headers: {'Content-Type': 'application/json','Authorization': 'Bearer $idToken'}, body: jsonEncode(courtData));
         // Pega o ID da resposta ao criar
         if (detailsResponse.statusCode == 201) {
            courtIdToUse = jsonDecode(detailsResponse.body)['courtId'];
         } else {
             final error = jsonDecode(detailsResponse.body);
             throw Exception(error['message'] ?? 'Falha ao criar quadra.');
         }
      }

      if (![200, 201].contains(detailsResponse.statusCode)) {
         final error = jsonDecode(detailsResponse.body);
         throw Exception(error['message'] ?? 'Falha ao salvar detalhes da quadra.');
      }

      // 2. Salvar Disponibilidade (PUT)
      final availabilityPayload = Map.fromEntries(
        _availability.entries.map((entry) => MapEntry(entry.key, entry.value.toJson()))
      );
      final availabilityUrl = Uri.parse('${AppConfig.apiUrl}/courts/$courtIdToUse/availability');
      final availabilityResponse = await http.put(
        availabilityUrl,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
        body: jsonEncode(availabilityPayload),
      );

      if (availabilityResponse.statusCode != 200) {
         final error = jsonDecode(availabilityResponse.body);
         print('Erro ao salvar disponibilidade: ${error['message']}');
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detalhes salvos, mas houve erro na disponibilidade: ${error['message']}'), backgroundColor: Colors.orange));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quadra ${isEditing ? 'atualizada' : 'cadastrada'} com sucesso!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir este espaço? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      final idToken = await user.getIdToken(true);
      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}');
      final response = await http.delete(url, headers: {'Authorization': 'Bearer $idToken'});

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quadra excluída com sucesso!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Falha ao excluir quadra.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sportsController.dispose();
    _addressController.dispose();
    _rulesController.dispose();
    _availability.forEach((key, value) => value.dispose()); // Limpa os controllers de preço
    super.dispose();
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay? initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 18, minute: 0), // Sugere 18:00
       builder: (context, child) { // Opcional: força modo de dial
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? Container(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Espaço' : 'Adicionar Novo Espaço'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 80.0), // Padding inferior maior
                children: [
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome do espaço *'), validator: (v) => (v==null || v.isEmpty) ? 'Obrigatório' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 3),
                  const SizedBox(height: 24),
                  const Text('Fotos do Espaço', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400)),
                    child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.add_a_photo_outlined, color: AppTheme.hintColor), SizedBox(height: 8), Text('Adicionar fotos', style: TextStyle(color: AppTheme.hintColor))]))
                  ),
                  const SizedBox(height: 24),
                  TextFormField(controller: _sportsController, decoration: const InputDecoration(labelText: 'Esportes (separados por vírgula) *'), validator: (v) => (v==null || v.isEmpty) ? 'Obrigatório' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Endereço Completo *'), validator: (v) => (v==null || v.isEmpty) ? 'Obrigatório' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _rulesController, decoration: const InputDecoration(labelText: 'Regras de utilização'), maxLines: 2),
                  const SizedBox(height: 32),
                  
                  // --- SEÇÃO DISPONIBILIDADE ---
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  const Text('Disponibilidade e Preços', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Marque os dias em que o espaço está aberto e defina os horários e preço por hora.', style: TextStyle(color: AppTheme.hintColor)),
                  const SizedBox(height: 16),
                  ..._daysOfWeek.map((day) => _buildAvailabilityRow(day, _availability[day]!)),
                  // -----------------------------

                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _isSaving || _isDeleting ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR ESPAÇO'),
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isDeleting || _isSaving ? null : _handleDelete,
                      icon: _isDeleting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                          : const Icon(Icons.delete_outline),
                      label: const Text('Excluir Espaço'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // Widget Auxiliar para Linha de Disponibilidade
  Widget _buildAvailabilityRow(String dayName, AvailabilityDay dayData) {
    String formatTime(TimeOfDay? time) => time == null ? 'HH:MM' : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material( // Wrap with Material for InkWell splash effect
        color: dayData.isOpen ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Checkbox(
                value: dayData.isOpen,
                activeColor: AppTheme.primaryColor,
                onChanged: (bool? value) => setState(() => dayData.isOpen = value ?? false),
              ),
              Expanded(flex: 2, child: Text(dayName[0].toUpperCase() + dayName.substring(1), style: TextStyle(fontWeight: FontWeight.w500, color: dayData.isOpen ? AppTheme.textColor : Colors.grey))),
              const SizedBox(width: 8),

              // Time Pickers
              InkWell(
                onTap: !dayData.isOpen ? null : () async {
                  final selectedTime = await _selectTime(context, dayData.startTime);
                  if (selectedTime != null) setState(() => dayData.startTime = selectedTime);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                   decoration: BoxDecoration(border: Border.all(color: dayData.isOpen ? Colors.grey.shade400 : Colors.transparent), borderRadius: BorderRadius.circular(4)),
                  child: Text(formatTime(dayData.startTime), style: TextStyle(color: dayData.isOpen ? AppTheme.textColor : Colors.grey)),
                )
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('às')),
              InkWell(
                 onTap: !dayData.isOpen ? null : () async {
                   final selectedTime = await _selectTime(context, dayData.endTime);
                  if (selectedTime != null) setState(() => dayData.endTime = selectedTime);
                },
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                   decoration: BoxDecoration(border: Border.all(color: dayData.isOpen ? Colors.grey.shade400 : Colors.transparent), borderRadius: BorderRadius.circular(4)),
                   child: Text(formatTime(dayData.endTime), style: TextStyle(color: dayData.isOpen ? AppTheme.textColor : Colors.grey)),
                 )
              ),
              const SizedBox(width: 12),

              // Price Field
              SizedBox(
                width: 90, // Aumentado um pouco
                child: TextFormField(
                  controller: dayData.priceController,
                  decoration: InputDecoration(
                     isDense: true, // Reduz altura
                     contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // Ajusta padding interno
                     labelText: 'Preço/h',
                     prefixText: 'R\$ ',
                     border: OutlineInputBorder(borderSide: BorderSide(color: dayData.isOpen ? Colors.grey.shade400 : Colors.transparent)),
                     enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: dayData.isOpen ? Colors.grey.shade400 : Colors.transparent)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: dayData.isOpen,
                  style: TextStyle(color: dayData.isOpen ? AppTheme.textColor : Colors.grey),
                  validator: (value) {
                    if (dayData.isOpen && (value == null || value.isEmpty || (double.tryParse(value.replaceAll(',', '.')) ?? -1) <= 0)) {
                      return 'Inválido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}