import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

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

  @override
  void initState() {
    super.initState();
    final r = widget.reminderToEdit;
    _nomeController = TextEditingController(text: r?.nomeMedicamento ?? '');
    _quantidadeController = TextEditingController(text: r?.quantidadeMedicamento ?? '');

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

  Future<void> _addTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC18AD1),
            ),
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
                      isEditing ? 'EDITAR LEMBRETE' : 'ADICIONAR NOVO LEMBRETE',
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

              const Icon(Icons.medication_outlined, size: 100, color: Color(0xFFC18AD1)),
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
              const SizedBox(height: 30),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C72AD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, size: 64, color: Color(0xFFF1DBED)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Captura de foto da caixa do remédio selecionada.')),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        TextField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'NOME DO\nREMÉDIO:',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9C72AD),
                              fontFamily: 'serif',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FOTO DA CAIXA DO REMÉDIO',
                  style: TextStyle(color: Color(0xFF9C72AD), fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _quantidadeController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'QUANTIDADE:',
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
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final nome = _nomeController.text.trim();
                    if (nome.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, preencha o nome do remédio.'),
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
                      type: ReminderType.medicamento,
                      nomeMedicamento: nome,
                      quantidadeMedicamento: _quantidadeController.text.trim(),
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
