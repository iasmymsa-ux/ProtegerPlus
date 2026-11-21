import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder_model.dart';
import 'api_config.dart';
import 'user_session_service.dart';

/// Serviço responsável pelo gerenciamento de lembretes, sincronização compartilhada
/// (Idoso <-> Cuidador) e agendamento de alarmes sonoros com vibração forte no dispositivo.
class ReminderService extends ChangeNotifier {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal() {
    _loadFromPrefs();
  }

  // Canal de notificação com som de alarme alto e vibração intensa
  static const String _channelId = 'lembretes_alarme_proteger_v30';
  static const String _channelName = 'Alarmes e Lembretes Proteger+';
  static const String _channelDescription =
      'Canal de alarmes de alta prioridade com som audível e vibração forte para medicamentos, consultas e tarefas';

  final FlutterTts _tts = FlutterTts();
  final List<ReminderModel> _reminders = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _syncTimer;
  bool _isSyncing = false;

  List<ReminderModel> get reminders => List.unmodifiable(_reminders);

  // ── INICIALIZAÇÃO DE NOTIFICAÇÕES E CANAL DE ALARME ────────────────────────

  Future<void> initNotifications() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notificationsPlugin.initialize(settings: initSettings);

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Solicita permissões necessárias do Android (Notificações e Alarmes Exatos)
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();

      // Remove canais antigos obsoletos para garantir atualização das permissões de som e vibração
      final oldChannels = [
        'lembretes_alarme_sonoro_v21',
        'lembretes_alarme_alto_v10',
        'lembretes_alarme_sonoro_v6',
        'lembretes_alarme_sonoro',
        'lembretes_alarme',
      ];
      for (final oldId in oldChannels) {
        try {
          await androidPlugin?.deleteNotificationChannel(channelId: oldId);
        } catch (_) {}
      }

      // Configura o canal oficial com som audível de alarme e padrão de vibração contínuo
      const sound = RawResourceAndroidNotificationSound('alarme');
      final vibrationPattern = Int64List.fromList([
        0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000
      ]);

      final channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: sound,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableLights: true,
        ledColor: const Color(0xFFF97316),
      );
      await androidPlugin?.createNotificationChannel(channel);

      try {
        await _tts.setLanguage('pt-BR');
        await _tts.setSpeechRate(0.5);
        await _tts.setVolume(1.0);
      } catch (_) {}

      // Carrega do cache local e agenda alarmes
      await _loadFromPrefs();
      for (final reminder in _reminders) {
        await _scheduleAlarmsForReminder(reminder);
      }

      // Sincroniza lembretes mais recentes do servidor MySQL
      await syncFromServer();
      _startSyncTimer();
      debugPrint('[ReminderService] Notificações e alarmes inicializados com sucesso.');
    } catch (e) {
      debugPrint('[ReminderService] Erro ao inicializar notificações: $e');
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      syncFromServer();
    });
  }

  void cancelSyncTimer() {
    _syncTimer?.cancel();
  }

  // ── DETALHES DE NOTIFICAÇÃO DO CANAL DE ALARME ─────────────────────────────

  AndroidNotificationDetails _buildAlarmDetails({
    String? title,
    String? body,
    String? subText,
  }) {
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: const RawResourceAndroidNotificationSound('alarme'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([
        0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000
      ]),
      // FLAG_INSISTENT: repete o som do alarme audível continuamente até o usuário interagir
      additionalFlags: Int32List.fromList(<int>[4]),
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      styleInformation: body != null
          ? BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: subText ?? 'Lembrete do Proteger+',
            )
          : null,
      timeoutAfter: 60000, // Toca por até 60 segundos se não dispensado
      ongoing: false,
      autoCancel: true,
    );
  }

  /// Dispara um teste imediato do alarme sonoro com vibração para validação do usuário
  Future<void> testAlarmNow() async {
    final androidDetails = _buildAlarmDetails(
      title: 'Teste de Alarme Sonoro',
      body: 'O alarme do Proteger+ está tocando com som alto e vibração forte!',
      subText: 'PROTEGER+ ALARME',
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 999999,
      title: 'Teste de Alarme Sonoro',
      body: 'O alarme do Proteger+ está tocando com som alto e vibração forte!',
      notificationDetails: notificationDetails,
    );

    try {
      await _tts.speak('Atenção! Teste de alarme sonoro do Proteger Plus! O som e a vibração estão funcionando.');
    } catch (_) {}
  }

  // ── AGENDAMENTO DE ALARMES NO DISPOSITIVO ──────────────────────────────────

  Future<void> _scheduleAlarmsForReminder(ReminderModel reminder) async {
    // 1. Cancela alarmes anteriores deste mesmo lembrete para evitar duplicidade
    await _cancelAlarmsForReminder(reminder.id);

    // 2. Prepara título e corpo detalhados conforme o tipo de lembrete
    String title = reminder.title;
    String body;
    String subText;

    switch (reminder.type) {
      case ReminderType.medicamento:
        subText = 'Hora do Remédio';
        final nome = reminder.nomeMedicamento ?? 'Medicamento';
        final qtd = (reminder.quantidadeMedicamento != null &&
                reminder.quantidadeMedicamento!.isNotEmpty)
            ? ' - Dose: ${reminder.quantidadeMedicamento}'
            : '';
        final freq = (reminder.frequenciaMedicamento != null &&
                reminder.frequenciaMedicamento!.isNotEmpty)
            ? ' (${reminder.frequenciaMedicamento})'
            : '';
        body = 'Tome agora: $nome$qtd$freq';
        break;

      case ReminderType.consulta:
        subText = 'Consulta Médica';
        final prof = reminder.profissionalConsulta ?? 'Médico';
        final hor = reminder.horarioConsulta ?? '';
        final loc = (reminder.localConsulta != null &&
                reminder.localConsulta!.isNotEmpty)
            ? ' no local: ${reminder.localConsulta}'
            : '';
        final mot = (reminder.motivoConsulta != null &&
                reminder.motivoConsulta!.isNotEmpty)
            ? '\nMotivo: ${reminder.motivoConsulta}'
            : '';
        body = 'Consulta com $prof às $hor$loc$mot';
        break;

      case ReminderType.tarefa:
        subText = 'Tarefa Agendada';
        final nome = reminder.nomeTarefa ?? reminder.title;
        final esp = (reminder.especificacaoTarefa != null &&
                reminder.especificacaoTarefa!.isNotEmpty)
            ? ': ${reminder.especificacaoTarefa}'
            : '';
        body = 'Realizar tarefa: $nome$esp';
        break;

      case ReminderType.alerta:
        subText = 'Alarme Programado';
        final tit = reminder.tituloAlerta ?? reminder.title;
        body = 'Alerta programado: $tit';
        break;
    }

    final androidDetails = _buildAlarmDetails(
      title: title,
      body: body,
      subText: subText,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    // Agendamento para Consultas (data e horário específicos)
    if (reminder.type == ReminderType.consulta) {
      if (reminder.dataConsulta != null &&
          reminder.dataConsulta!.isNotEmpty &&
          reminder.horarioConsulta != null &&
          reminder.horarioConsulta!.isNotEmpty) {
        try {
          final dateParts = reminder.dataConsulta!.split('/');
          final timeParts = reminder.horarioConsulta!.split(':');
          if (dateParts.length == 3 && timeParts.length == 2) {
            final scheduledDate = tz.TZDateTime(
              tz.local,
              int.parse(dateParts[2]),
              int.parse(dateParts[1]),
              int.parse(dateParts[0]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
            final now = tz.TZDateTime.now(tz.local);
            if (scheduledDate.isAfter(now)) {
              // ID positivo de 32 bits seguro
              final alarmId = (reminder.id.hashCode.abs()) & 0x7FFFFFFF;

              // Aviso sonoro 1 hora antes da consulta
              final umaHoraAntes = scheduledDate.subtract(const Duration(hours: 1));
              if (umaHoraAntes.isAfter(now)) {
                final warningDetails = _buildAlarmDetails(
                  title: 'Aviso: Consulta em 1 Hora',
                  body: 'Sua consulta médica começa em 1 hora (${reminder.horarioConsulta})',
                  subText: 'Consulta Médica',
                );
                await _notificationsPlugin.zonedSchedule(
                  id: (alarmId + 9000) & 0x7FFFFFFF,
                  title: 'Aviso: Consulta em 1 Hora',
                  body: 'Sua consulta médica começa em 1 hora (${reminder.horarioConsulta})',
                  scheduledDate: umaHoraAntes,
                  notificationDetails: NotificationDetails(android: warningDetails),
                  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                );
              }

              // Alarme no horário exato da consulta
              await _notificationsPlugin.zonedSchedule(
                id: alarmId,
                title: 'Hora da Consulta Médica!',
                body: body,
                scheduledDate: scheduledDate,
                notificationDetails: notificationDetails,
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              );
              debugPrint('[ReminderService] Consulta agendada com alarme sonoro para: $scheduledDate');
            }
          }
        } catch (e) {
          debugPrint('[ReminderService] Aviso ao agendar consulta: $e');
        }
      }
      return;
    }

    // Agendamento para Medicamentos, Tarefas e Alarmes diários
    for (int i = 0; i < reminder.horarios.length; i++) {
      final horarioStr = reminder.horarios[i];
      final parts = horarioStr.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      try {
        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // Se o horário de hoje já passou, agenda para amanhã
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        // Garante identificador inteiro positivo de 32 bits seguro e determinístico
        final alarmId = (reminder.id.hashCode.abs() + i) & 0x7FFFFFFF;

        await _notificationsPlugin.zonedSchedule(
          id: alarmId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('[ReminderService] Alarme sonoro agendado: "$title" para $horarioStr (ID: $alarmId)');
      } catch (e) {
        debugPrint('[ReminderService] Aviso ao agendar alarme: $e');
      }
    }
  }

  Future<void> _cancelAlarmsForReminder(String id) async {
    final baseHash = id.hashCode.abs();
    for (int i = 0; i < 20; i++) {
      try {
        await _notificationsPlugin.cancel(id: (baseHash + i) & 0x7FFFFFFF);
      } catch (_) {}
    }
    try {
      await _notificationsPlugin.cancel(id: (baseHash + 9000) & 0x7FFFFFFF);
    } catch (_) {}
  }

  // ── PERSISTÊNCIA LOCAL (SharedPreferences) ────────────────────────────────

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('reminders_key');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _reminders.clear();
        _reminders.addAll(jsonList.map((j) => ReminderModel.fromJson(j)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ReminderService] Erro ao carregar lembretes locais: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString =
          jsonEncode(_reminders.map((r) => r.toJson()).toList());
      await prefs.setString('reminders_key', jsonString);
    } catch (e) {
      debugPrint('[ReminderService] Erro ao salvar lembretes locais: $e');
    }
  }

  // ── SINCRONIZAÇÃO COMPARTILHADA COM MYSQL (Idoso <-> Cuidador) ─────────────

  /// Sincroniza lembretes do servidor (inclui lembretes cadastrados pelo parceiro vinculado)
  Future<void> syncFromServer() async {
    if (_isSyncing) return;
    final session = UserSessionService.instance;
    final userId = session.currentUser.id;
    if (userId == 'user_local_01') return;

    _isSyncing = true;
    try {
      final uri = Uri.parse(
        '${ApiConfig.instance.baseUrl}/lembretes.php?usuario_id=$userId',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['sucesso'] == true && data['lembretes'] is List) {
          final List serverList = data['lembretes'];
          final serverReminders = serverList
              .map((j) => ReminderModel.fromJson(j as Map<String, dynamic>))
              .toList();

          bool changed = false;

          // 1. Adiciona novos lembretes ou atualiza lembretes alterados no servidor
          for (final sr in serverReminders) {
            final idx = _reminders.indexWhere((r) => r.id == sr.id);
            if (idx == -1) {
              _reminders.add(sr);
              await _scheduleAlarmsForReminder(sr);
              changed = true;
            } else {
              // Verifica se houve alteração em horários ou títulos
              final localJson = jsonEncode(_reminders[idx].toJson());
              final serverJson = jsonEncode(sr.toJson());
              if (localJson != serverJson) {
                _reminders[idx] = sr;
                await _scheduleAlarmsForReminder(sr);
                changed = true;
              }
            }
          }

          // 2. Remove lembretes locais que foram excluídos no servidor
          final serverIds = serverReminders.map((r) => r.id).toSet();
          final toRemove =
              _reminders.where((r) => !serverIds.contains(r.id)).toList();
          for (final r in toRemove) {
            _reminders.remove(r);
            await _cancelAlarmsForReminder(r.id);
            changed = true;
          }

          if (changed) {
            await _saveToPrefs();
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('[ReminderService] Erro ao sincronizar lembretes com servidor: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Salva lembrete no servidor MySQL
  Future<void> _saveToServer(ReminderModel reminder) async {
    final session = UserSessionService.instance;
    final userId = session.currentUser.id;
    if (userId == 'user_local_01') return;

    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/lembretes.php');
      final payload = reminder.toJson();
      payload['usuario_id'] = userId;
      payload['acao'] = 'salvar';

      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));
      debugPrint('[ReminderService] Lembrete ${reminder.id} gravado no servidor.');
    } catch (e) {
      debugPrint('[ReminderService] Erro ao salvar lembrete no servidor: $e');
    }
  }

  /// Exclui lembrete do servidor MySQL
  Future<void> _deleteFromServer(String id) async {
    final session = UserSessionService.instance;
    final userId = session.currentUser.id;
    if (userId == 'user_local_01') return;

    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/lembretes.php');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'acao': 'excluir', 'id': id, 'usuario_id': userId}),
          )
          .timeout(const Duration(seconds: 5));
      debugPrint('[ReminderService] Lembrete $id excluído do servidor.');
    } catch (e) {
      debugPrint('[ReminderService] Erro ao excluir lembrete no servidor: $e');
    }
  }

  // ── OPERAÇÕES CRUD COM AGENDAMENTO E VÍNCULO AUTOMÁTICO ────────────────────

  void addReminder(ReminderModel reminder) {
    _reminders.add(reminder);
    _saveToPrefs();
    _scheduleAlarmsForReminder(reminder);
    _saveToServer(reminder);
    notifyListeners();
  }

  void updateReminder(ReminderModel updatedReminder) {
    final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      _reminders[index] = updatedReminder;
      _saveToPrefs();
      _scheduleAlarmsForReminder(updatedReminder);
      _saveToServer(updatedReminder);
      notifyListeners();
    }
  }

  void removeReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    _saveToPrefs();
    _cancelAlarmsForReminder(id);
    _deleteFromServer(id);
    notifyListeners();
  }

  ReminderModel? getReminderById(String id) {
    try {
      return _reminders.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
