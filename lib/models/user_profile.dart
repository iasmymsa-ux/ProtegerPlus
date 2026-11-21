enum UserRole {
  idoso,
  cuidador,
}

/// Representa o perfil de um usuário no Proteger+ (Idoso ou Cuidador).
/// Preparado para mapeamento direto com banco de dados MySQL e armazenamento local.
class UserProfile {
  final String id;
  final String name;
  final UserRole role;
  final String? login;
  final String? email;
  final String? phone;
  final String? emergencyPhone;
  final String? localidade;
  final String? dataNascimento;
  final String? doencasCronicas;
  final String? connectionCode; // Código de 6 caracteres gerado para idoso
  final String? caregiverName;  // Nome do cuidador informado no cadastro do idoso
  final String? caregiverPhone; // Telefone do cuidador informado no cadastro do idoso

  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    this.login,
    this.email,
    this.phone,
    this.emergencyPhone,
    this.localidade,
    this.dataNascimento,
    this.doencasCronicas,
    this.connectionCode,
    this.caregiverName,
    this.caregiverPhone,
  });

  bool get isSenior => role == UserRole.idoso;
  bool get isCaregiver => role == UserRole.cuidador;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'login': login,
      'email': email,
      'phone': phone,
      'emergencyPhone': emergencyPhone,
      'localidade': localidade,
      'dataNascimento': dataNascimento,
      'doencasCronicas': doencasCronicas,
      'connectionCode': connectionCode,
      'caregiverName': caregiverName,
      'caregiverPhone': caregiverPhone,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final rawRole = (map['role'] ?? map['papel'] ?? 'idoso').toString().toLowerCase();
    return UserProfile(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? map['nome'] ?? 'Usuário').toString(),
      role: rawRole == 'cuidador' ? UserRole.cuidador : UserRole.idoso,
      login: map['login']?.toString(),
      email: (map['email'] ?? map['login'])?.toString(),
      phone: (map['phone'] ?? map['telefone'])?.toString(),
      emergencyPhone: (map['emergencyPhone'] ?? map['telefone_emergencia'])?.toString(),
      localidade: map['localidade']?.toString(),
      dataNascimento: (map['dataNascimento'] ?? map['data_nascimento'])?.toString(),
      doencasCronicas: (map['doencasCronicas'] ?? map['doencas_cronicas'])?.toString(),
      connectionCode: (map['connectionCode'] ?? map['codigo_vinculo'])?.toString(),
      caregiverName: (map['caregiverName'] ?? map['nome_cuidador'] ?? map['caregiver_name'])?.toString(),
      caregiverPhone: (map['caregiverPhone'] ?? map['telefone_cuidador'] ?? map['caregiver_phone'])?.toString(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? login,
    String? email,
    String? phone,
    String? emergencyPhone,
    String? localidade,
    String? dataNascimento,
    String? doencasCronicas,
    String? connectionCode,
    String? caregiverName,
    String? caregiverPhone,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      login: login ?? this.login,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      localidade: localidade ?? this.localidade,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      doencasCronicas: doencasCronicas ?? this.doencasCronicas,
      connectionCode: connectionCode ?? this.connectionCode,
      caregiverName: caregiverName ?? this.caregiverName,
      caregiverPhone: caregiverPhone ?? this.caregiverPhone,
    );
  }
}
