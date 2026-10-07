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
  late final TextEditingController _horarioController;
  late final TextEditingController _localController;
  late final TextEditingController _profissionalController;
  late final TextEditingController _acompanhanteController;
  late final TextEditingController _motivoController;

  @override
  void initState() {
    super.initState();
    final r = widget.reminderToEdit;
    _horarioController = TextEditingController(text: r?.horarioConsulta ?? '');
    _localController = TextEditingController(text: r?.localConsulta ?? '');
    _profissionalController = TextEditingController(text: r?.profissionalConsulta ?? '');
    _acompanhanteController = TextEditingController(text: r?.acompanhanteConsulta ?? '');
    _motivoController = TextEditingController(text: r?.motivoConsulta ?? '');
  }

  @override
  void dispose() {
    _horarioController.dispose();
    _localController.dispose();
    _profissionalController.dispose();
    _acompanhanteController.dispose();
    _motivoController.dispose();
    super.dispose();
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
              const SizedBox(height: 15),
              const Text(
                'DIGITE DE ACORDO COM A CONSULTA',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              _buildTextField('HORÁRIO:', _horarioController),
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
                    final horario = _horarioController.text.trim();
                    final local = _localController.text.trim();
                    final acompanhante = _acompanhanteController.text.trim();
                    final motivo = _motivoController.text.trim();

                    if (profissional.isEmpty && motivo.isEmpty && local.isEmpty && horario.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, preencha as informações da consulta.'),
                        ),
                      );
                      return;
                    }

                    final id = isEditing
                        ? widget.reminderToEdit!.id
                        : DateTime.now().millisecondsSinceEpoch.toString();

                    final reminder = ReminderModel(
                      id: id,
                      type: ReminderType.consulta,
                      profissionalConsulta: profissional,
                      horarioConsulta: horario,
                      localConsulta: local,
                      acompanhanteConsulta: acompanhante,
                      motivoConsulta: motivo,
                      horarios: horario.isNotEmpty ? [horario] : const [],
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
