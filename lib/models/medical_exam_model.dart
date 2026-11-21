import 'dart:convert';

/// Representa um exame médico anexado para o idoso monitorado.
class MedicalExamModel {
  final String id;
  final String seniorId;
  final String codigoVinculo;
  final String titulo;
  final String categoria;
  final String dataExame;
  final String medicoLaboratorio;
  final String observacoes;
  final String? imagemBase64;
  final String? imageLocalPath;
  final DateTime criadoEm;

  const MedicalExamModel({
    required this.id,
    required this.seniorId,
    required this.codigoVinculo,
    required this.titulo,
    this.categoria = 'Geral',
    required this.dataExame,
    this.medicoLaboratorio = '',
    this.observacoes = '',
    this.imagemBase64,
    this.imageLocalPath,
    required this.criadoEm,
  });

  bool get hasImage => (imagemBase64 != null && imagemBase64!.isNotEmpty) ||
      (imageLocalPath != null && imageLocalPath!.isNotEmpty);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senior_id': seniorId,
      'codigo_vinculo': codigoVinculo,
      'titulo': titulo,
      'categoria': categoria,
      'data_exame': dataExame,
      'medico_laboratorio': medicoLaboratorio,
      'observacoes': observacoes,
      'imagem_base64': imagemBase64,
      'image_local_path': imageLocalPath,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  factory MedicalExamModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      parsedDate = map['criado_em'] != null
          ? DateTime.parse(map['criado_em'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return MedicalExamModel(
      id: (map['id'] ?? '').toString(),
      seniorId: (map['senior_id'] ?? map['seniorId'] ?? '').toString(),
      codigoVinculo: (map['codigo_vinculo'] ?? map['codigoVinculo'] ?? '').toString(),
      titulo: (map['titulo'] ?? map['title'] ?? 'Exame').toString(),
      categoria: (map['categoria'] ?? map['category'] ?? 'Geral').toString(),
      dataExame: (map['data_exame'] ?? map['dataExame'] ?? '').toString(),
      medicoLaboratorio: (map['medico_laboratorio'] ?? map['medicoLaboratorio'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? map['notes'] ?? '').toString(),
      imagemBase64: map['imagem_base64']?.toString(),
      imageLocalPath: map['image_local_path']?.toString(),
      criadoEm: parsedDate,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MedicalExamModel.fromJson(String source) =>
      MedicalExamModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

