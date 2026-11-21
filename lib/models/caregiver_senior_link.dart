enum LinkStatus {
  pending,
  active,
  revoked,
}

/// Representa o vínculo oficial entre uma conta de Idoso e uma conta de Cuidador.
/// A conexão é estabelecida exclusivamente por código de vinculação.
class CaregiverSeniorLink {
  final String id;
  final String seniorId;
  final String caregiverId;
  final String seniorName;
  final String caregiverName;
  final String connectionCode;
  final LinkStatus status;
  final DateTime createdAt;

  const CaregiverSeniorLink({
    required this.id,
    required this.seniorId,
    required this.caregiverId,
    required this.seniorName,
    required this.caregiverName,
    required this.connectionCode,
    this.status = LinkStatus.active,
    required this.createdAt,
  });

  bool get isActive => status == LinkStatus.active;

  /// Verifica se o usuário informado faz parte deste vínculo
  bool hasParticipant(String userId) {
    return seniorId == userId || caregiverId == userId;
  }

  /// Retorna o nome do outro participante a partir do ID do usuário atual
  String getOtherParticipantName(String currentUserId) {
    if (currentUserId == seniorId) {
      return caregiverName;
    }
    return seniorName;
  }

  /// Retorna o ID do outro participante a partir do ID do usuário atual
  String getOtherParticipantId(String currentUserId) {
    if (currentUserId == seniorId) {
      return caregiverId;
    }
    return seniorId;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seniorId': seniorId,
      'caregiverId': caregiverId,
      'seniorName': seniorName,
      'caregiverName': caregiverName,
      'connectionCode': connectionCode,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CaregiverSeniorLink.fromMap(Map<String, dynamic> map) {
    return CaregiverSeniorLink(
      id: (map['id'] ?? '').toString(),
      seniorId: (map['seniorId'] ?? map['senior_id'] ?? '').toString(),
      caregiverId: (map['caregiverId'] ?? map['cuidador_id'] ?? map['caregiver_id'] ?? '').toString(),
      seniorName: (map['seniorName'] ?? map['senior_nome'] ?? 'Idoso').toString(),
      caregiverName: (map['caregiverName'] ?? map['cuidador_nome'] ?? map['caregiver_nome'] ?? 'Cuidador').toString(),
      connectionCode: (map['connectionCode'] ?? map['codigo_vinculo'] ?? '').toString(),
      status: LinkStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LinkStatus.active,
      ),
      createdAt: DateTime.tryParse((map['createdAt'] ?? map['criado_em']) as String? ?? '') ?? DateTime.now(),
    );
  }
}
