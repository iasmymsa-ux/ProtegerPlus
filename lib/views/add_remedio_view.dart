import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

// Frequências mais comuns de medicamentos
const List<Map<String, dynamic>> _frequencias = [
  {'label': 'Diário (1x por dia)',      'icone': Icons.sunny,            'intervalHours': 24},
  {'label': 'De 8 em 8 horas (3x/dia)', 'icone': Icons.access_alarm,     'intervalHours': 8},
  {'label': 'De 12 em 12 horas (2x/dia)','icone': Icons.schedule,        'intervalHours': 12},
  {'label': 'De 6 em 6 horas (4x/dia)', 'icone': Icons.alarm,            'intervalHours': 6},
  {'label': 'Semanal',                  'icone': Icons.calendar_view_week,'intervalHours': null},
  {'label': 'Mensal',                   'icone': Icons.calendar_month,    'intervalHours': null},
  {'label': 'Personalizado',            'icone': Icons.tune,              'intervalHours': null},
];

class AddRemedioView extends StatefulWidget {
  final ReminderModel? reminderToEdit;

  const AddRemedioView({super.key, this.reminderToEdit});

  @override
  State<AddRemedioView> createState() => _AddRemedioViewState();
}

class _AddRemedioViewState extends State<AddRemedioView> {
  late final TextEditingController _nomeController;
  late final TextEditingController _quantidadeController;
  final List<TimeOfDay> _horarios = [];
  String? _frequenciaSelecionada;

  @override
  void initState() {
    super.initState();
    final r = widget.reminderToEdit;
    _nomeController = TextEditingController(text: r?.nomeMedicamento ?? '');
    _quantidadeController = TextEditingController(text: r?.quantidadeMedicamento ?? '');
    _frequenciaSelecionada = r?.frequenciaMedicamento;

    if (r != null && r.horarios.isNotEmpty) {
      for (final hStr in r.horarios) {
        final parts = hStr.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            _horarios.add(TimeOfDay(hour: hour, minute: minute));
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  /// Ao selecionar uma frequência automática, calcula os horários a partir de agora
  void _aplicarFrequencia(String label, int? intervalHours) {
    setState(() {
      _frequenciaSelecionada = label;
      if (intervalHours != null && intervalHours < 24) {
        // Calcula horários automáticos distribuídos pelo dia
        _horarios.clear();
        final now = TimeOfDay.now();
        int startHour = now.hour;
        final count = 24 ~/ intervalHours;
        for (int i = 0; i < count; i++) {
          final h = (startHour + i * intervalHours) % 24;
          _horarios.add(TimeOfDay(hour: h, minute: 0));
        }
        _horarios.sort((a, b) =>
            (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      } else if (label == 'Diário (1x por dia)') {
        // Mantém o horário que já existe ou usa 08:00
        if (_horarios.isEmpty) _horarios.add(const TimeOfDay(hour: 8, minute: 0));
      }
      // Semanal/Mensal/Personalizado: o usuário adiciona manualmente
    });
  }

  Future<void> _addTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFC18AD1)),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _horarios.add(time);
        _horarios.sort(
            (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      });
    }
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
              // ── Cabeçalho ──────────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      isEditing ? 'EDITAR REMÉDIO' : 'ADICIONAR REMÉDIO',
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
              const SizedBox(height: 24),

              const Icon(Icons.medication_outlined, size: 90, color: Color(0xFFC18AD1)),
              const Text(
                'REMÉDIOS',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'serif',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Nome do remédio ────────────────────────────────────────────
              TextField(
                controller: _nomeController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'NOME DO REMÉDIO',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9C72AD),
                    fontFamily: 'serif',
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),

              // ── Quantidade ─────────────────────────────────────────────────
              TextField(
                controller: _quantidadeController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'QUANTIDADE (ex: 1 comprimido)',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9C72AD),
                    fontFamily: 'serif',
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // ── Frequência ─────────────────────────────────────────────────
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FREQUÊNCIA',
                  style: TextStyle(
                    color: Color(0xFF9C72AD),
                    fontSize: 16,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              ...(_frequencias.map((f) {
                final label = f['label'] as String;
                final intervalHours = f['intervalHours'] as int?;
                final icon = f['icone'] as IconData;
                final selected = _frequenciaSelecionada == label;

                return GestureDetector(
                  onTap: () => _aplicarFrequencia(label, intervalHours),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF9C72AD) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? const Color(0xFF9C72AD) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: selected ? Colors.white : const Color(0xFF9C72AD),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: selected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                );
              })),

              const SizedBox(height: 24),

              // ── Horários ───────────────────────────────────────────────────
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'HORÁRIOS DO ALARME',
                  style: TextStyle(
                    color: Color(0xFF9C72AD),
                    fontSize: 16,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'O alarme vai tocar por 30 segundos ou até você desligar',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._horarios.map(
                    (t) => Chip(
                      label: Text(
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => setState(() => _horarios.remove(t)),
                      backgroundColor: const Color(0xFFF1DBED),
                      side: const BorderSide(color: Color(0xFF9C72AD)),
                    ),
                  ),
                  InkWell(
                    onTap: _addTime,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C72AD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // ── Salvar ─────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final nome = _nomeController.text.trim();
                    if (nome.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Por favor, preencha o nome do remédio.')),
                      );
                      return;
                    }
                    if (_frequenciaSelecionada == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Por favor, selecione a frequência do remédio.')),
                      );
                      return;
                    }

                    final listHorariosStr = _horarios
                        .map((t) =>
                            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
                        .toList();

                    final id = isEditing
                        ? widget.reminderToEdit!.id
                        : DateTime.now().millisecondsSinceEpoch.toString();

                    final reminder = ReminderModel(
                      id: id,
                      type: ReminderType.medicamento,
                      nomeMedicamento: nome,
                      quantidadeMedicamento: _quantidadeController.text.trim(),
                      frequenciaMedicamento: _frequenciaSelecionada,
                      horarios: listHorariosStr,
                    );

                    if (isEditing) {
                      ReminderService().updateReminder(reminder);
                    } else {
                      ReminderService().addReminder(reminder);
                    }

                    Navigator.pop(context, reminder);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Atualizar Remédio' : 'Salvar Remédio',
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
}
