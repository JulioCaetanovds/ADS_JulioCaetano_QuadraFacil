// lib/features/home/presentation/pages/add_edit_court_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quadrafacil/core/config.dart';
import 'package:quadrafacil/core/theme/app_theme.dart';

// Modelo de Disponibilidade
class AvailabilityDay {
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  TextEditingController priceController = TextEditingController();
  bool isOpen = false;

  AvailabilityDay({this.startTime, this.endTime, String? price, this.isOpen = false}) {
    priceController.text = price?.replaceAll(',', '.') ?? '';
  }

  void dispose() => priceController.dispose();

  Map<String, dynamic>? toJson() {
    if (!isOpen || startTime == null || endTime == null || priceController.text.isEmpty) {
      return null; 
    }
    try {
      String formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      final priceValue = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
      return {
        'startTime': formatTime(startTime!),
        'endTime': formatTime(endTime!),
        'pricePerHour': priceValue,
      };
    } catch (e) {
      return null;
    }
  }

  static AvailabilityDay fromJson(Map<String, dynamic>? json) {
    if (json == null) return AvailabilityDay(isOpen: false);
    try {
      TimeOfDay parseTime(String timeStr) {
         final parts = timeStr.split(':');
         return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      final priceString = json['pricePerHour']?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      return AvailabilityDay(
        startTime: parseTime(json['startTime']),
        endTime: parseTime(json['endTime']),
        price: priceString,
        isOpen: true,
      );
    } catch(e) {
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
    'segunda': AvailabilityDay(), 'terca': AvailabilityDay(), 'quarta': AvailabilityDay(),
    'quinta': AvailabilityDay(), 'sexta': AvailabilityDay(), 'sabado': AvailabilityDay(),
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

      final detailsUrl = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}');
      final detailsResponse = await http.get(detailsUrl, headers: {'Authorization': 'Bearer $idToken'});
      if (detailsResponse.statusCode != 200) throw Exception('Falha ao carregar detalhes.');
      final courtData = jsonDecode(detailsResponse.body);

      final availabilityUrl = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}/availability');
      final availabilityResponse = await http.get(availabilityUrl);
      Map<String, dynamic> availabilityData = {};
      if (availabilityResponse.statusCode == 200) {
         availabilityData = jsonDecode(availabilityResponse.body);
      }

      if (mounted) {
        setState(() {
          _nameController.text = courtData['nome'] ?? '';
          _descriptionController.text = courtData['descricao'] ?? '';
          _sportsController.text = courtData['esporte'] ?? '';
          _addressController.text = courtData['endereco'] ?? ''; // Simplificação: Assumindo string, ajuste se for Map
          _rulesController.text = courtData['regras'] ?? '';

           for (var day in _daysOfWeek) {
             _availability[day] = AvailabilityDay.fromJson(availabilityData[day]);
           }
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
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

      final courtData = {
        'nome': _nameController.text,
        'descricao': _descriptionController.text,
        'esporte': _sportsController.text,
        'endereco': _addressController.text,
        'regras': _rulesController.text,
      };
      
      http.Response detailsResponse;
      String courtIdToUse;

      if (isEditing) {
        final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}');
        detailsResponse = await http.put(url, headers: {'Content-Type': 'application/json','Authorization': 'Bearer $idToken'}, body: jsonEncode(courtData));
        courtIdToUse = widget.courtId!;
      } else {
         final url = Uri.parse('${AppConfig.apiUrl}/courts');
         detailsResponse = await http.post(url, headers: {'Content-Type': 'application/json','Authorization': 'Bearer $idToken'}, body: jsonEncode(courtData));
         if (detailsResponse.statusCode == 201) {
            courtIdToUse = jsonDecode(detailsResponse.body)['courtId'];
         } else {
             throw Exception(jsonDecode(detailsResponse.body)['message'] ?? 'Erro ao criar.');
         }
      }

      if (![200, 201].contains(detailsResponse.statusCode)) {
         throw Exception('Erro ao salvar detalhes.');
      }

      final availabilityPayload = Map.fromEntries(
        _availability.entries.map((entry) => MapEntry(entry.key, entry.value.toJson()))
      );
      final avUrl = Uri.parse('${AppConfig.apiUrl}/courts/$courtIdToUse/availability');
      await http.put(avUrl, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'}, body: jsonEncode(availabilityPayload));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo com sucesso!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Espaço?'),
        content: const Text('Essa ação é irreversível.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user!.getIdToken(true);
      final url = Uri.parse('${AppConfig.apiUrl}/courts/${widget.courtId}');
      final response = await http.delete(url, headers: {'Authorization': 'Bearer $idToken'});

      if (response.statusCode == 200 && mounted) {
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Erro ao excluir.');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao excluir.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); _descriptionController.dispose(); _sportsController.dispose();
    _addressController.dispose(); _rulesController.dispose();
    _availability.forEach((key, value) => value.dispose());
    super.dispose();
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay? initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 18, minute: 0),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Espaço' : 'Novo Espaço', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _buildSectionTitle('Informações Básicas'),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _nameController, label: 'Nome do Espaço', icon: Icons.store, required: true),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _sportsController, label: 'Esportes (ex: Futsal, Vôlei)', icon: Icons.sports_soccer, required: true),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _addressController, label: 'Endereço Completo', icon: Icons.location_on_outlined, required: true),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _descriptionController, label: 'Descrição', icon: Icons.description_outlined, maxLines: 3),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _rulesController, label: 'Regras de Uso', icon: Icons.rule, maxLines: 2),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Fotos'),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {}, // TODO: Implementar upload
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppTheme.primaryColor.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text('Toque para adicionar fotos', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Disponibilidade & Preços'),
                  const SizedBox(height: 4),
                  Text('Defina os horários de funcionamento e valor por hora.', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 16),
                  ..._daysOfWeek.map((day) => _buildAvailabilityCard(day, _availability[day]!)),

                  const SizedBox(height: 40),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving || _isDeleting ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) 
                        : Text(isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting || _isSaving ? null : _handleDelete,
                        icon: _isDeleting ? const SizedBox() : const Icon(Icons.delete_outline),
                        label: _isDeleting ? const CircularProgressIndicator(color: Colors.red) : const Text('Excluir Espaço'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor));
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildAvailabilityCard(String dayName, AvailabilityDay dayData) {
    final dayLabel = dayName[0].toUpperCase() + dayName.substring(1);
    String formatTime(TimeOfDay? time) => time == null ? '--:--' : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: dayData.isOpen ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey[200]!),
      ),
      color: dayData.isOpen ? Colors.white : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: dayData.isOpen,
                  activeColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => dayData.isOpen = val ?? false),
                ),
                Text(dayLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dayData.isOpen ? Colors.black87 : Colors.grey)),
              ],
            ),
            if (dayData.isOpen) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await _selectTime(context, dayData.startTime);
                        if(t != null) setState(() => dayData.startTime = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Abre às', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(formatTime(dayData.startTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await _selectTime(context, dayData.endTime);
                        if(t != null) setState(() => dayData.endTime = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fecha às', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(formatTime(dayData.endTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                      child: TextFormField(
                        controller: dayData.priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Preço/h',
                          prefixText: 'R\$ ',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        validator: (v) => (dayData.isOpen && (v==null || v.isEmpty)) ? '!' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}