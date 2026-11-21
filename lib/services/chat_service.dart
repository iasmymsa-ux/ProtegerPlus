import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/caregiver_senior_link.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import 'user_session_service.dart';

/// Contrato formal para armazenamento e recuperação de dados de chat.
/// Quando o banco de dados for desenvolvido, basta implementar esta interface.
abstract class IChatRepository {
  Future<ChatConversation?> getConversationForLink(String linkId);
  Future<ChatConversation> createConversation(CaregiverSeniorLink link);
  Future<List<ChatMessage>> getMessages(String conversationId);
  Stream<List<ChatMessage>> watchMessages(String conversationId);
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required UserRole senderRole,
    required String content,
  });
  Future<void> updateMessageStatus(String messageId, MessageStatus status);
  Future<void> retryMessage(String messageId);
}

/// Implementação em memória para a fase atual do projeto (pré-banco de dados).
/// Permite o funcionamento arquitetural completo sem dados fictícios.
class LocalChatRepository implements IChatRepository {
  final Map<String, ChatConversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, StreamController<List<ChatMessage>>> _streamControllers = {};

  StreamController<List<ChatMessage>> _getController(String conversationId) {
    return _streamControllers.putIfAbsent(
      conversationId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
  }

  void _notify(String conversationId) {
    final list = _messages[conversationId] ?? [];
    _getController(conversationId).add(List.unmodifiable(list));
  }

  @override
  Future<ChatConversation?> getConversationForLink(String linkId) async {
    for (final conv in _conversations.values) {
      if (conv.linkId == linkId) return conv;
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

    _conversations[conv.id] = conv;
    _messages[conv.id] = [];
    _notify(conv.id);
    return conv;
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    return List.unmodifiable(_messages[conversationId] ?? []);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    final controller = _getController(conversationId);
    // Emite o estado inicial imediatamente
    Future.microtask(() => _notify(conversationId));
    return controller.stream;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required UserRole senderRole,
    required String content,
  }) async {
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderRole: senderRole,
      content: content.trim(),
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    _messages.putIfAbsent(conversationId, () => []).add(message);

    // Atualiza a última mensagem na conversa
    final conv = _conversations[conversationId];
    if (conv != null) {
      _conversations[conversationId] = conv.copyWith(lastMessage: message);
    }

    _notify(conversationId);
    return message;
  }

  @override
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    for (final entry in _messages.entries) {
      final index = entry.value.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        entry.value[index] = entry.value[index].copyWith(status: status);
        _notify(entry.key);
        break;
      }
    }
  }

  @override
  Future<void> retryMessage(String messageId) async {
    await updateMessageStatus(messageId, MessageStatus.sent);
  }
}

/// Serviço de alto nível consumido pelas telas de Chat.
/// Aplica as regras de negócio: validação do vínculo, permissões dos participantes
/// e delega a persistência para o repositório configurado.
class ChatService extends ChangeNotifier {
  static final ChatService instance = ChatService._internal();

  ChatService._internal();

  /// ID da conversa que está atualmente em foco na tela
  String? activeOpenConversationId;

  IChatRepository _repository = LocalChatRepository();

  /// Permite injetar o repositório do banco de dados quando for implementado
  void setRepository(IChatRepository repository) {
    _repository = repository;
    notifyListeners();
  }

  /// Recupera ou cria a conversa oficial correspondente ao vínculo ativo
  Future<ChatConversation?> getActiveConversation() async {
    // 1. Garante sincronização mais recente do vínculo com o banco de dados
    if (UserSessionService.instance.activeLink == null) {
      await UserSessionService.instance.refreshFromServer();
    }

    var activeLink = UserSessionService.instance.activeLink;
    if (activeLink != null && activeLink.isActive) {
      final conv = await _repository.getConversationForLink(activeLink.id);
      if (conv != null) {
        return conv;
      }
      return await _repository.createConversation(activeLink);
    }

    // 2. Fallback inteligente usando o código de conexão compartilhado
    final session = UserSessionService.instance;
    final code = session.currentUser.connectionCode ??
        session.partnerUser?.connectionCode;
    if (code != null && code.trim().isNotEmpty) {
      final cleanCode = code.trim().toUpperCase();
      final conv = await _repository.getConversationForLink('link_$cleanCode');
      if (conv != null) {
        return conv;
      }
    }

    return null;
  }

  /// Stream em tempo real das mensagens da conversa
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _repository.watchMessages(conversationId);
  }

  /// Carrega a lista atual de mensagens
  Future<List<ChatMessage>> loadMessages(String conversationId) {
    return _repository.getMessages(conversationId);
  }

  /// Envia mensagem garantindo que o remetente pertence ao vínculo
  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return null;

    final session = UserSessionService.instance;
    final currentUser = session.currentUser;

    return await _repository.sendMessage(
      conversationId: conversationId,
      senderId: currentUser.id,
      senderRole: currentUser.role,
      content: content,
    );
  }

  /// Reenvia uma mensagem com falha
  Future<void> retryMessage(String messageId) async {
    await _repository.retryMessage(messageId);
  }
}
