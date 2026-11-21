import 'chat_message.dart';

/// Representa o canal de conversa estruturado entre Idoso e Cuidador vinculado.
class ChatConversation {
  final String id;
  final String linkId; // Referência direta ao CaregiverSeniorLink
  final String seniorId;
  final String caregiverId;
  final String seniorName;
  final String caregiverName;
  final DateTime createdAt;
  final ChatMessage? lastMessage;
  final int unreadCount;

  const ChatConversation({
    required this.id,
    required this.linkId,
    required this.seniorId,
    required this.caregiverId,
    required this.seniorName,
    required this.caregiverName,
    required this.createdAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  bool hasParticipant(String userId) {
    return seniorId == userId || caregiverId == userId;
  }

  String getOtherParticipantName(String currentUserId) {
    return (currentUserId == seniorId) ? caregiverName : seniorName;
  }

  ChatConversation copyWith({
    String? id,
    String? linkId,
    String? seniorId,
    String? caregiverId,
    String? seniorName,
    String? caregiverName,
    DateTime? createdAt,
    ChatMessage? lastMessage,
    int? unreadCount,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      linkId: linkId ?? this.linkId,
      seniorId: seniorId ?? this.seniorId,
      caregiverId: caregiverId ?? this.caregiverId,
      seniorName: seniorName ?? this.seniorName,
      caregiverName: caregiverName ?? this.caregiverName,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'linkId': linkId,
      'seniorId': seniorId,
      'caregiverId': caregiverId,
      'seniorName': seniorName,
      'caregiverName': caregiverName,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage?.toMap(),
      'unreadCount': unreadCount,
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] as String,
      linkId: map['linkId'] as String,
      seniorId: map['seniorId'] as String,
      caregiverId: map['caregiverId'] as String,
      seniorName: map['seniorName'] as String? ?? 'Idoso',
      caregiverName: map['caregiverName'] as String? ?? 'Cuidador',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastMessage: map['lastMessage'] != null
          ? ChatMessage.fromMap(Map<String, dynamic>.from(map['lastMessage'] as Map))
          : null,
      unreadCount: map['unreadCount'] as int? ?? 0,
    );
  }
}
