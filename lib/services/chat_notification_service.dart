import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Serviço responsável por disparar notificações sonoras e visuais
/// quando chegam novas mensagens de chat de outro usuário.
class ChatNotificationService {
  ChatNotificationService._internal();
  static final ChatNotificationService instance = ChatNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _channelId = 'chat_messages_channel_v1';
  static const String _channelName = 'Mensagens do Chat';

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notificationsPlugin.initialize(settings: initSettings);

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      final channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Notificações de novas mensagens recebidas no chat',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 200, 250]),
      );
      await androidPlugin?.createNotificationChannel(channel);
      _isInitialized = true;
      debugPrint('[ChatNotificationService] Inicializado com sucesso.');
    } catch (e) {
      debugPrint('[ChatNotificationService] Erro ao inicializar notificações: $e');
    }
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    if (!_isInitialized) await init();

    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Notificações de novas mensagens do chat',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          message,
          contentTitle: senderName,
          summaryText: 'Nova mensagem',
        ),
      );

      final notificationDetails = NotificationDetails(android: androidDetails);
      final id = (DateTime.now().millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF;

      await _notificationsPlugin.show(
        id: id,
        title: senderName,
        body: message,
        notificationDetails: notificationDetails,
      );
      debugPrint('[ChatNotificationService] Notificação enviada para: $senderName');
    } catch (e) {
      debugPrint('[ChatNotificationService] Erro ao exibir notificação de chat: $e');
    }
  }
}
