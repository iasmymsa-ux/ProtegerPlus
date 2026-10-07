import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

class AddAlarmView extends StatefulWidget {
  final ReminderModel? reminderToEdit;

  const AddAlarmView({super.key, this.reminderToEdit});

  @override
  State<AddAlarmView> createState() => _AddAlarmViewState();
}

class _AddAlarmViewState extends State<AddAlarmView> {
  late final TextEditingController _tituloController;
  final List<TimeOfDay> _horarios = [];

  @override
  void initState() {
    super.initState();
    final r = widget.reminderToEdit;
    _tituloController = TextEditingController(text: r?.tituloAlerta ?? '');

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
    _tituloController.dispose();
    super.dispose();
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
        _horarios.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      isEditing ? 'EDITAR ALERTA' : 'ADICIONAR NOVO ALERTA',
                      style: const TextStyle(
                        fontSize: 15,
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

              const Icon(Icons.alarm_outlined, size: 100, color: Color(0xFF9C72AD)),
              const SizedBox(height: 10),
              const Text(
                'ALERTA / ALARME',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'serif',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _tituloController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'TÍTULO DO ALERTA (OPCIONAL):',
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
              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'HORÁRIOS',
                  style: TextStyle(
                    color: Color(0xFF9C72AD),
                    fontSize: 16,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._horarios.map((t) => Chip(
                        label: Text(
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _horarios.remove(t);
                          });
                        },
                        backgroundColor: Colors.white,
                      )),
                  InkWell(
                    onTap: _addTime,
                    child: const Icon(Icons.add_circle, color: Color(0xFF9C72AD), size: 40),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final titulo = _tituloController.text.trim();
                    if (_horarios.isEmpty && titulo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, adicione pelo menos um horário ou título.'),
                        ),
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
                      type: ReminderType.alerta,
                      tituloAlerta: titulo.isNotEmpty ? titulo : 'Alerta',
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
                    isEditing ? 'Atualizar Alerta' : 'Salvar Alerta',
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
