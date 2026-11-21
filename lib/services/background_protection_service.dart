import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundProtectionTaskHandler());
}

class BackgroundProtectionTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('Serviço de proteção contínua em segundo plano iniciado.');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Mantém a execução em segundo plano ativa
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('Serviço de proteção contínua em segundo plano encerrado.');
  }
}

class BackgroundProtectionService {
  BackgroundProtectionService._();
  static final BackgroundProtectionService instance = BackgroundProtectionService._();

  static const String _keyEnabled = 'background_protection_enabled';

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'proteger_plus_protection_channel',
        channelName: 'Proteger+ Proteção Ativa',
        channelDescription: 'Mantém a detecção de queda e alertas ativos fora do app.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? true;
  }

  Future<bool> isRunning() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return await FlutterForegroundTask.isRunningService;
  }

  Future<void> start() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final enabled = await isEnabled();
    if (!enabled) return;

    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    try {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Proteger+ • Proteção Ativa',
        notificationText: 'Monitorando detecção de quedas e alertas em segundo plano.',
        callback: startForegroundTaskCallback,
      );
    } catch (e) {
      debugPrint('Aviso ao iniciar foreground service: $e');
    }
  }

  Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<bool> toggle() async {
    final currentlyEnabled = await isEnabled();
    final newStatus = !currentlyEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, newStatus);

    if (newStatus) {
      await start();
    } else {
      await stop();
    }
    return newStatus;
  }

  /// Verifica se o app já tem permissão para ignorar otimizações de bateria
  Future<bool> isBatteryOptimizationIgnored() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      return await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    } catch (e) {
      debugPrint('Erro ao verificar otimização de bateria: $e');
      return false;
    }
  }

  /// Solicita ao usuário a isenção de otimização de bateria (essencial para tela bloqueada)
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final isIgnored = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      if (!isIgnored) {
        return await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao solicitar ignorar otimização de bateria: $e');
      return false;
    }
  }

  /// Acorda a tela do dispositivo em situações de alerta/emergência
  Future<void> wakeUpScreen() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      FlutterForegroundTask.wakeUpScreen();
    } catch (e) {
      debugPrint('Aviso ao acordar a tela: $e');
    }
  }
}
