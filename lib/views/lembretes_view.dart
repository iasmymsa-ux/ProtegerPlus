import 'package:flutter/material.dart';
import 'category_selection_view.dart';
import 'add_remedio_view.dart';
import 'add_consulta_view.dart';
import 'add_tarefa_view.dart';
import 'add_alarm_view.dart';
import '../services/reminder_service.dart';
import '../models/reminder_model.dart';

class LembretesView extends StatefulWidget {
  const LembretesView({super.key});

  @override
  State<LembretesView> createState() => _LembretesViewState();
}

class _LembretesViewState extends State<LembretesView> {
  final _reminderService = ReminderService();

  @override
  void initState() {
    super.initState();
    _reminderService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _reminderService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _editReminder(ReminderModel reminder) async {
    Widget editView;
    switch (reminder.type) {
      case ReminderType.medicamento:
        editView = AddRemedioView(reminderToEdit: reminder);
        break;
      case ReminderType.consulta:
        editView = AddConsultaView(reminderToEdit: reminder);
        break;
      case ReminderType.tarefa:
        editView = AddTarefaView(reminderToEdit: reminder);
        break;
      case ReminderType.alerta:
        editView = AddAlarmView(reminderToEdit: reminder);
        break;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => editView),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lembrete atualizado com sucesso!')),
      );
    }
  }

  void _confirmDelete(ReminderModel reminder) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Excluir Lembrete'),
          content: Text('Tem certeza de que deseja excluir o lembrete "${reminder.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _reminderService.removeReminder(reminder.id);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lembrete excluído com sucesso!')),
                );
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDetails(ReminderModel reminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(reminder.categoryIcon, color: const Color(0xFF9C72AD), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reminder.categoryLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9C72AD),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                reminder.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              if (reminder.type == ReminderType.medicamento) ...[
                if (reminder.quantidadeMedicamento != null &&
                    reminder.quantidadeMedicamento!.isNotEmpty)
                  _detailRow('Quantidade:', reminder.quantidadeMedicamento!),
                if (reminder.horarios.isNotEmpty)
                  _detailRow('Horários:', reminder.horarios.join(', ')),
              ] else if (reminder.type == ReminderType.consulta) ...[
                if (reminder.profissionalConsulta != null &&
                    reminder.profissionalConsulta!.isNotEmpty)
                  _detailRow('Profissional:', reminder.profissionalConsulta!),
                if (reminder.horarioConsulta != null && reminder.horarioConsulta!.isNotEmpty)
                  _detailRow('Horário:', reminder.horarioConsulta!),
                if (reminder.localConsulta != null && reminder.localConsulta!.isNotEmpty)
                  _detailRow('Local:', reminder.localConsulta!),
                if (reminder.acompanhanteConsulta != null &&
                    reminder.acompanhanteConsulta!.isNotEmpty)
                  _detailRow('Acompanhante:', reminder.acompanhanteConsulta!),
                if (reminder.motivoConsulta != null && reminder.motivoConsulta!.isNotEmpty)
                  _detailRow('Motivo:', reminder.motivoConsulta!),
              ] else if (reminder.type == ReminderType.tarefa) ...[
                if (reminder.especificacaoTarefa != null &&
                    reminder.especificacaoTarefa!.isNotEmpty)
                  _detailRow('Especificação:', reminder.especificacaoTarefa!),
                if (reminder.horarios.isNotEmpty)
                  _detailRow('Horários:', reminder.horarios.join(', ')),
              ] else if (reminder.type == ReminderType.alerta) ...[
                if (reminder.horarios.isNotEmpty)
                  _detailRow('Horários:', reminder.horarios.join(', ')),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editReminder(reminder);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(reminder);
                    },
                    icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                    label: const Text('Excluir', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = _reminderService.reminders;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Lembretes',
                      style: TextStyle(
                        fontSize: 22,
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

              Row(
                children: const [
                  Icon(Icons.alarm_outlined, color: Color(0xFFC18AD1), size: 40),
                  SizedBox(width: 10),
                  Text(
                    'Definir um novo lembrete',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC18AD1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Clique aqui para adicionar um novo lembrete',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CategorySelectionView()),
                    );
                  },
                  icon: const Icon(Icons.add_circle, color: Color(0xFF9C72AD), size: 56),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: const [
                  Icon(Icons.calendar_today_outlined, color: Color(0xFFC18AD1), size: 40),
                  SizedBox(width: 10),
                  Text(
                    'Seus Lembretes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC18AD1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (reminders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      'Nenhum lembrete cadastrado no momento.',
                      style: TextStyle(fontSize: 16, color: Colors.black54, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...reminders.map((r) => _buildReminderCard(r)),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    String subtitle = '';
    if (reminder.type == ReminderType.medicamento) {
      if (reminder.quantidadeMedicamento != null && reminder.quantidadeMedicamento!.isNotEmpty) {
        subtitle += 'Qtd: ${reminder.quantidadeMedicamento}';
      }
      if (reminder.horarios.isNotEmpty) {
        if (subtitle.isNotEmpty) subtitle += ' • ';
        subtitle += 'Horário: ${reminder.horarios.join(', ')}';
      }
    } else if (reminder.type == ReminderType.consulta) {
      if (reminder.horarioConsulta != null && reminder.horarioConsulta!.isNotEmpty) {
        subtitle += 'Horário: ${reminder.horarioConsulta}';
      }
      if (reminder.localConsulta != null && reminder.localConsulta!.isNotEmpty) {
        if (subtitle.isNotEmpty) subtitle += ' • ';
        subtitle += 'Local: ${reminder.localConsulta}';
      }
    } else if (reminder.type == ReminderType.tarefa) {
      if (reminder.horarios.isNotEmpty) {
        subtitle += 'Horário: ${reminder.horarios.join(', ')}';
      } else if (reminder.especificacaoTarefa != null && reminder.especificacaoTarefa!.isNotEmpty) {
        subtitle += reminder.especificacaoTarefa!;
      }
    } else if (reminder.type == ReminderType.alerta) {
      if (reminder.horarios.isNotEmpty) {
        subtitle += 'Horário: ${reminder.horarios.join(', ')}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(reminder.categoryIcon, color: const Color(0xFFC18AD1), size: 28),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1DBED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reminder.categoryLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9C72AD),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF9C72AD), size: 22),
                  onPressed: () => _editReminder(reminder),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  onPressed: () => _confirmDelete(reminder),
                  tooltip: 'Excluir',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reminder.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _showDetails(reminder),
                child: const Text(
                  'ver detalhes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9C72AD),
                    decoration: TextDecoration.underline,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
