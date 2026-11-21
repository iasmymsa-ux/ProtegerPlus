import 'package:flutter_test/flutter_test.dart';
import 'package:proteger_plus/models/user_profile.dart';
import 'package:proteger_plus/models/caregiver_senior_link.dart';
import 'package:proteger_plus/models/chat_message.dart';
import 'package:proteger_plus/services/user_session_service.dart';
import 'package:proteger_plus/services/chat_service.dart';

void main() {
  group('Chat Models & Business Rules Tests', () {
    test('ChatMessage toMap and fromMap serialization', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 'msg_01',
        conversationId: 'conv_01',
        senderId: 'user_01',
        senderRole: UserRole.idoso,
        content: 'Olá, cuidador!',
        timestamp: now,
        status: MessageStatus.sent,
      );

      final map = msg.toMap();
      expect(map['id'], 'msg_01');
      expect(map['senderRole'], 'idoso');
      expect(map['content'], 'Olá, cuidador!');

      final restored = ChatMessage.fromMap(map);
      expect(restored.id, msg.id);
      expect(restored.conversationId, msg.conversationId);
      expect(restored.senderId, msg.senderId);
      expect(restored.senderRole, UserRole.idoso);
      expect(restored.content, msg.content);
      expect(restored.status, MessageStatus.sent);
    });

    test('CaregiverSeniorLink verification by code', () {
      final link = CaregiverSeniorLink(
        id: 'link_01',
        seniorId: 'senior_01',
        caregiverId: 'caregiver_01',
        seniorName: 'Dona Maria',
        caregiverName: 'Carlos',
        connectionCode: 'ABC123',
        status: LinkStatus.active,
        createdAt: DateTime.now(),
      );

      expect(link.isActive, true);
      expect(link.hasParticipant('senior_01'), true);
      expect(link.hasParticipant('caregiver_01'), true);
      expect(link.hasParticipant('stranger_01'), false);
      expect(link.getOtherParticipantName('senior_01'), 'Carlos');
      expect(link.getOtherParticipantName('caregiver_01'), 'Dona Maria');
    });

    test('UserSessionService starts without fake link and enforces link for chat', () async {
      final session = UserSessionService.instance;
      session.unlink();

      expect(session.hasActiveLink, false);
      expect(session.activeLink, isNull);

      final chatService = ChatService.instance;
      // Sem vínculo, a conversa ativa deve ser nula
      final conv = await chatService.getActiveConversation();
      expect(conv, isNull);

      // Sem vínculo, enviar mensagem deve lançar StateError
      expect(
        () => chatService.sendMessage(
          conversationId: 'conv_fake',
          content: 'Teste sem vínculo',
        ),
        throwsA(isA<StateError>()),
      );

      // Agora vincula via código
      final linkSuccess = await session.linkWithCode(
        code: 'K7M2X9',
        otherParticipantName: 'Carlos Cuidador',
      );
      expect(linkSuccess, true);
      expect(session.hasActiveLink, true);
      expect(session.activeLink!.connectionCode, 'K7M2X9');

      // Com vínculo ativo, a conversa é criada automaticamente
      final activeConv = await chatService.getActiveConversation();
      expect(activeConv, isNotNull);
      expect(activeConv!.linkId, session.activeLink!.id);

      // Envia uma mensagem com sucesso
      final sentMsg = await chatService.sendMessage(
        conversationId: activeConv.id,
        content: 'Tudo bem por aí?',
      );
      expect(sentMsg, isNotNull);
      expect(sentMsg!.content, 'Tudo bem por aí?');
      expect(sentMsg.status, MessageStatus.sent);

      // Recupera o histórico
      final history = await chatService.loadMessages(activeConv.id);
      expect(history.length, 1);
      expect(history.first.content, 'Tudo bem por aí?');

      // Limpa após o teste
      session.unlink();
      expect(session.hasActiveLink, false);
    });
  });
}
