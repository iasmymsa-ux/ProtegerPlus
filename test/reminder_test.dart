import 'package:flutter_test/flutter_test.dart';
import 'package:proteger_plus/models/reminder_model.dart';
import 'package:proteger_plus/services/reminder_service.dart';

void main() {
  group('ReminderService & ReminderModel Tests', () {
    late ReminderService reminderService;

    setUp(() {
      reminderService = ReminderService();
      // Clear all existing reminders before each test
      final currentList = List<ReminderModel>.from(reminderService.reminders);
      for (final r in currentList) {
        reminderService.removeReminder(r.id);
      }
    });

    test('Create Medicamento reminder with specific fields', () {
      final model = ReminderModel(
        id: '1',
        type: ReminderType.medicamento,
        nomeMedicamento: 'Paracetamol 750mg',
        quantidadeMedicamento: '1 comprimido',
        horarios: ['08:00', '20:00'],
      );

      reminderService.addReminder(model);

      expect(reminderService.reminders.length, 1);
      final saved = reminderService.getReminderById('1');
      expect(saved, isNotNull);
      expect(saved!.title, 'Paracetamol 750mg');
      expect(saved.categoryLabel, 'MEDICAMENTO');
      expect(saved.quantidadeMedicamento, '1 comprimido');
      expect(saved.horarios, ['08:00', '20:00']);
    });

    test('Create Consulta reminder with specific fields', () {
      final model = ReminderModel(
        id: '2',
        type: ReminderType.consulta,
        profissionalConsulta: 'Dr. Roberto',
        horarioConsulta: '14:30',
        localConsulta: 'Hospital Central',
        acompanhanteConsulta: 'Maria',
        motivoConsulta: 'Rotina de Cardiologia',
      );

      reminderService.addReminder(model);

      expect(reminderService.reminders.length, 1);
      final saved = reminderService.getReminderById('2');
      expect(saved, isNotNull);
      expect(saved!.title, 'Consulta com Dr. Roberto');
      expect(saved.categoryLabel, 'CONSULTA MÉDICA');
      expect(saved.localConsulta, 'Hospital Central');
      expect(saved.motivoConsulta, 'Rotina de Cardiologia');
      expect(saved.acompanhanteConsulta, 'Maria');
    });

    test('Create Tarefa reminder with specific fields', () {
      final model = ReminderModel(
        id: '3',
        type: ReminderType.tarefa,
        nomeTarefa: 'Caminhada no parque',
        especificacaoTarefa: '30 minutos no ritmo leve',
        horarios: ['07:00'],
      );

      reminderService.addReminder(model);

      expect(reminderService.reminders.length, 1);
      final saved = reminderService.getReminderById('3');
      expect(saved, isNotNull);
      expect(saved!.title, 'Caminhada no parque');
      expect(saved.categoryLabel, 'TAREFA');
      expect(saved.especificacaoTarefa, '30 minutos no ritmo leve');
      expect(saved.horarios, ['07:00']);
    });

    test('Create Alerta reminder with specific fields', () {
      final model = ReminderModel(
        id: '4',
        type: ReminderType.alerta,
        tituloAlerta: 'Beber água',
        horarios: ['10:00', '15:00', '18:00'],
      );

      reminderService.addReminder(model);

      expect(reminderService.reminders.length, 1);
      final saved = reminderService.getReminderById('4');
      expect(saved, isNotNull);
      expect(saved!.title, 'Beber água');
      expect(saved.categoryLabel, 'ALERTA');
      expect(saved.horarios, ['10:00', '15:00', '18:00']);
    });

    test('Multiple reminders can exist simultaneously without overwriting', () {
      final r1 = ReminderModel(id: '10', type: ReminderType.medicamento, nomeMedicamento: 'Dipirona');
      final r2 = ReminderModel(id: '11', type: ReminderType.consulta, profissionalConsulta: 'Dra. Ana');
      final r3 = ReminderModel(id: '12', type: ReminderType.tarefa, nomeTarefa: 'Medição de pressão');
      final r4 = ReminderModel(id: '13', type: ReminderType.alerta, tituloAlerta: 'Hora do descanso');

      reminderService.addReminder(r1);
      reminderService.addReminder(r2);
      reminderService.addReminder(r3);
      reminderService.addReminder(r4);

      expect(reminderService.reminders.length, 4);
      expect(reminderService.getReminderById('10')!.title, 'Dipirona');
      expect(reminderService.getReminderById('11')!.title, 'Consulta com Dra. Ana');
      expect(reminderService.getReminderById('12')!.title, 'Medição de pressão');
      expect(reminderService.getReminderById('13')!.title, 'Hora do descanso');
    });

    test('Editing a reminder updates existing item without creating duplicate', () {
      final initial = ReminderModel(
        id: '50',
        type: ReminderType.medicamento,
        nomeMedicamento: 'Vitamina C',
        quantidadeMedicamento: '1 efervescente',
        horarios: ['09:00'],
      );
      reminderService.addReminder(initial);

      expect(reminderService.reminders.length, 1);

      final updated = initial.copyWith(
        nomeMedicamento: 'Vitamina C 1000mg',
        quantidadeMedicamento: '2 efervescentes',
        horarios: ['09:00', '21:00'],
      );
      reminderService.updateReminder(updated);

      expect(reminderService.reminders.length, 1);
      final current = reminderService.getReminderById('50');
      expect(current!.nomeMedicamento, 'Vitamina C 1000mg');
      expect(current.quantidadeMedicamento, '2 efervescentes');
      expect(current.horarios, ['09:00', '21:00']);
    });

    test('Deleting a reminder removes it completely from service', () {
      final r1 = ReminderModel(id: '100', type: ReminderType.tarefa, nomeTarefa: 'Regar plantas');
      final r2 = ReminderModel(id: '101', type: ReminderType.alerta, tituloAlerta: 'Tomar sol');

      reminderService.addReminder(r1);
      reminderService.addReminder(r2);
      expect(reminderService.reminders.length, 2);

      reminderService.removeReminder('100');

      expect(reminderService.reminders.length, 1);
      expect(reminderService.getReminderById('100'), isNull);
      expect(reminderService.getReminderById('101'), isNotNull);
    });
  });
}
