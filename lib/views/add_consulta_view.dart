import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

class AddConsultaView extends StatefulWidget {
  final ReminderModel? reminderToEdit;

  const AddConsultaView({super.key, this.reminderToEdit});

  @override
  State<AddConsultaView> createState() => _AddConsultaViewState();
}

class _AddConsultaViewState extends State<AddConsultaView> {
  late final TextEditingController _localController;
  late final TextEditingController _profissionalController;
  late final TextEditingController _acompanhanteController;
  late final TextEditingController _motivoController;

  // Data e hora da consulta (separados para facilitar seleção)
  DateTime? _dataConsulta;
  TimeOfDay? _horaConsulta;

  @override
  void initState() {
    super.initState();
    final r = widget.reminderToEdit;
    _localController = TextEditingController(text: r?.localConsulta ?? '');
    _profissionalController = TextEditingController(text: r?.profissionalConsulta ?? '');
    _acompanhanteController = TextEditingController(text: r?.acompanhanteConsulta ?? '');
    _motivoController = TextEditingController(text: r?.motivoConsulta ?? '');

    // Tenta parsear data/hora guardadas se vier de edição
    if (r?.dataConsulta != null && r!.dataConsulta!.isNotEmpty) {
      try {
        final parts = r.dataConsulta!.split('/');
        if (parts.length == 3) {
          _dataConsulta = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}
    }
    if (r?.horarioConsulta != null && r!.horarioConsulta!.isNotEmpty) {
      try {
        final parts = r.horarioConsulta!.split(':');
        if (parts.length == 2) {
          _horaConsulta = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _localController.dispose();
    _profissionalController.dispose();
    _acompanhanteController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final now = DateTime.now();
    final initial = _dataConsulta ?? now;
    final first = initial.isBefore(now.subtract(const Duration(days: 365)))
        ? initial.subtract(const Duration(days: 30))
        : now.subtract(const Duration(days: 365));
    final last = now.add(const Duration(days: 365 * 5));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFC18AD1),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _dataConsulta = date);
  }

  Future<void> _selecionarHora() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _horaConsulta ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFC18AD1)),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _horaConsulta = time);
  }

  String get _dataFormatada {
    if (_dataConsulta == null) return 'Selecionar data';
    final d = _dataConsulta!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get _horaFormatada {
    if (_horaConsulta == null) return 'Selecionar horário';
    return '${_horaConsulta!.hour.toString().padLeft(2, '0')}:${_horaConsulta!.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reminderToEdit != null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      isEditing ? 'EDITAR CONSULTA' : 'ADICIONAR CONSULTA',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 30),

              const Icon(Icons.local_hospital_outlined, size: 100, color: Color(0xFFC18AD1)),
              const SizedBox(height: 10),
              const Text(
                'CONSULTA MÉDICA',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'serif',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // ── Seletor de Data ────────────────────────────────────────────
              _buildSeletorCard(
                icon: Icons.calendar_today_outlined,
                label: 'DATA DA CONSULTA:',
                valor: _dataFormatada,
                onTap: _selecionarData,
                selecionado: _dataConsulta != null,
              ),
              const SizedBox(height: 14),

              // ── Seletor de Hora ────────────────────────────────────────────
              _buildSeletorCard(
                icon: Icons.access_time_outlined,
                label: 'HORÁRIO DA CONSULTA:',
                valor: _horaFormatada,
                onTap: _selecionarHora,
                selecionado: _horaConsulta != null,
              ),
              const SizedBox(height: 14),

              _buildTextField('LOCAL:', _localController),
              _buildTextField('NOME DO PROFISSIONAL:', _profissionalController),
              _buildTextField('ACOMPANHANTE:', _acompanhanteController),
              _buildTextField('MOTIVO:', _motivoController),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final profissional = _profissionalController.text.trim();
                    final local = _localController.text.trim();

                    if (profissional.isEmpty && local.isEmpty && _dataConsulta == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, preencha ao menos a data e o profissional.'),
                        ),
                      );
                      return;
                    }

                    final id = isEditing
                        ? widget.reminderToEdit!.id
                        : DateTime.now().millisecondsSinceEpoch.toString();

                    // Monta lista de horários para agendamento de notificação
                    final List<String> horariosAgendamento = [];
                    if (_horaConsulta != null) {
                      horariosAgendamento.add(
                        '${_horaConsulta!.hour.toString().padLeft(2, '0')}:${_horaConsulta!.minute.toString().padLeft(2, '0')}',
                      );
                    }

                    final reminder = ReminderModel(
                      id: id,
                      type: ReminderType.consulta,
                      profissionalConsulta: profissional,
                      horarioConsulta: _horaConsulta != null ? _horaFormatada : '',
                      dataConsulta: _dataConsulta != null ? _dataFormatada : '',
                      localConsulta: local,
                      acompanhanteConsulta: _acompanhanteController.text.trim(),
                      motivoConsulta: _motivoController.text.trim(),
                      horarios: horariosAgendamento,
                    );

                    if (isEditing) {
                      ReminderService().updateReminder(reminder);
                    } else {
                      ReminderService().addReminder(reminder);
                    }

                    Navigator.pop(context, reminder);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEditing ? 'Atualizar Consulta' : 'Salvar Consulta',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeletorCard({
    required IconData icon,
    required String label,
    required String valor,
    required VoidCallback onTap,
    required bool selecionado,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? const Color(0xFF9C72AD) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF9C72AD), size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF9C72AD),
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selecionado ? Colors.black87 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: Color(0xFF9C72AD), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF9C72AD),
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
