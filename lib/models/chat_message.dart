import 'user_profile.dart';

enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed,
}

/// Representa uma mensagem dentro da conversa entre Idoso e Cuidador.
/// Desacoplada de banco ou infraestrutura específica.
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final UserRole senderRole;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  bool get isPending => status == MessageStatus.pending;
  bool get isFailed => status == MessageStatus.failed;
  bool get isSent => status == MessageStatus.sent || status == MessageStatus.delivered || status == MessageStatus.read;

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    UserRole? senderRole,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderRole': senderRole.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      conversationId: map['conversationId'] as String,
      senderId: map['senderId'] as String,
      senderRole: (map['senderRole'] == 'cuidador') ? UserRole.cuidador : UserRole.idoso,
      content: map['content'] as String,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }
}
