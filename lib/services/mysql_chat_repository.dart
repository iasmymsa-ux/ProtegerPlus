import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/caregiver_senior_link.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import 'chat_service.dart';
import 'chat_notification_service.dart';
import 'user_session_service.dart';
import 'api_config.dart';

/// Implementação de IChatRepository conectada ao Apache + MySQL (XAMPP).
/// Todas as conversas e mensagens são gravadas no banco relacional `proteger_plus_db`.
class MySqlChatRepository implements IChatRepository {
  final Map<String, StreamController<List<ChatMessage>>> _streamControllers = {};
  final Map<String, List<ChatMessage>> _cache = {};
  final Set<String> _seenMessageIds = {};
  bool _firstPollCompleted = false;
  Timer? _pollTimer;

  MySqlChatRepository() {
    // Sincroniza periodicamente com o MySQL a cada 2.5 segundos para atualizar novas mensagens
    _pollTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _pollActiveConversations();
    });
  }

  void dispose() {
    _pollTimer?.cancel();
    for (final controller in _streamControllers.values) {
      controller.close();
    }
  }

  StreamController<List<ChatMessage>> _getController(String conversationId) {
    return _streamControllers.putIfAbsent(
      conversationId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
  }

  Future<void> _pollActiveConversations() async {
    final session = UserSessionService.instance;
    final activeLink = session.activeLink;
    final conversationsToPoll = <String>{..._streamControllers.keys};
    if (activeLink != null && activeLink.isActive) {
      conversationsToPoll.add('conv_${activeLink.id}');
    }

    final code = session.currentUser.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.activeLink?.connectionCode;
    if (code != null && code.trim().isNotEmpty) {
      final clean = code.trim().toUpperCase();
      conversationsToPoll.add('conv_link_$clean');
    }

    final currentUserId = session.currentUser.id;

    for (final convId in conversationsToPoll) {
      try {
        final messages = await getMessages(convId);
        _cache[convId] = messages;

        if (_firstPollCompleted) {
          for (final msg in messages) {
            // Se for mensagem recebida de outro participante e ainda não vista
            if (msg.senderId != currentUserId && !_seenMessageIds.contains(msg.id)) {
              _seenMessageIds.add(msg.id);

              // Só notifica se não estiver na tela exata desta conversa
              if (ChatService.instance.activeOpenConversationId != convId) {
                final senderName = UserSessionService.instance.partnerUser?.name.isNotEmpty == true
                    ? UserSessionService.instance.partnerUser!.name
                    : (UserSessionService.instance.currentUser.isCaregiver ? 'Idoso' : 'Cuidador');
                ChatNotificationService.instance.showMessageNotification(
                  senderName: senderName,
                  message: msg.content,
                  conversationId: convId,
                );
              }
            }
          }
        } else {
          // Na primeira execução, marca todas as mensagens existentes como conhecidas
          for (final msg in messages) {
            _seenMessageIds.add(msg.id);
          }
        }

        if (_streamControllers.containsKey(convId)) {
          _getController(convId).add(messages);
        }
      } catch (_) {
        // Ignora silenciosamente se o servidor estiver temporariamente ocupado
      }
    }
    _firstPollCompleted = true;
  }

  @override
  Future<ChatConversation?> getConversationForLink(String linkId) async {
    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/chat.php?link_id=$linkId');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sucesso'] == true && data['conversa'] != null) {
          final c = data['conversa'];
          return ChatConversation(
            id: c['id'],
            linkId: c['vinculo_id'],
            seniorId: c['senior_id'],
            caregiverId: c['cuidador_id'],
            seniorName: c['senior_nome'] ?? 'Idoso',
            caregiverName: c['cuidador_nome'] ?? 'Cuidador',
            createdAt: DateTime.tryParse(c['criada_em'] ?? '') ?? DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('[MySqlChatRepository] Conexão com Apache MySQL offline: $e');
    }

    return null;
  }

  @override
  Future<ChatConversation> createConversation(CaregiverSeniorLink link) async {
    final existing = await getConversationForLink(link.id);
    if (existing != null) return existing;

    final conv = ChatConversation(
      id: 'conv_${link.id}',
      linkId: link.id,
      seniorId: link.seniorId,
      caregiverId: link.caregiverId,
      seniorName: link.seniorName,
      caregiverName: link.caregiverName,
      createdAt: DateTime.now(),
    );

    _cache[conv.id] = [];
    return conv;
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/chat.php?conversa_id=$conversationId');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sucesso'] == true && data['mensagens'] is List) {
          final List list = data['mensagens'];
          final messages = list.map((m) => ChatMessage.fromMap(m)).toList();
          _cache[conversationId] = messages;
          return messages;
        }
      }
    } catch (e) {
      debugPrint('[MySqlChatRepository] Erro ao buscar mensagens no MySQL: $e');
    }

    return _cache[conversationId] ?? [];
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    final controller = _getController(conversationId);
    // Dispara busca inicial
    getMessages(conversationId).then((messages) {
      if (!controller.isClosed) controller.add(messages);
    });
    return controller.stream;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required UserRole senderRole,
    required String content,
  }) async {
    final localMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderRole: senderRole,
      content: content.trim(),
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    // Salva no cache local imediatamente para fluidez
    _cache.putIfAbsent(conversationId, () => []).add(localMsg);
    _getController(conversationId).add(_cache[conversationId]!);

    // Grava no banco de dados MySQL via Apache
    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/chat.php');
      final body = jsonEncode({
        'conversa_id': conversationId,
        'remetente_id': senderId,
        'papel_remetente': senderRole.name,
        'conteudo': content.trim(),
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['sucesso'] == true && data['dado'] != null) {
          return ChatMessage.fromMap(data['dado']);
        }
      }
    } catch (e) {
      debugPrint('[MySqlChatRepository] Erro ao gravar mensagem no MySQL: $e');
    }

    return localMsg;
  }

  @override
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    // Atualização local de status
    for (final entry in _cache.entries) {
      final index = entry.value.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        entry.value[index] = entry.value[index].copyWith(status: status);
        _getController(entry.key).add(entry.value);
        break;
      }
    }
  }

  @override
  Future<void> retryMessage(String messageId) async {
    await updateMessageStatus(messageId, MessageStatus.sent);
  }
}
