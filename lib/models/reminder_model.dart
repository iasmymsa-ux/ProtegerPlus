import 'package:flutter/material.dart';

enum ReminderType { medicamento, consulta, tarefa, alerta }

class ReminderModel {
  final String id;
  final ReminderType type;

  // Specific fields for Medicamento
  final String? nomeMedicamento;
  final String? quantidadeMedicamento;
  final List<String> horarios; // Format: "HH:mm"
  final String? fotoPath;

  // Specific fields for Consulta
  final String? profissionalConsulta;
  final String? horarioConsulta;
  final String? dataConsulta;
  final String? localConsulta;
  final String? acompanhanteConsulta;
  final String? motivoConsulta;

  // Specific fields for Tarefa
  final String? nomeTarefa;
  final String? especificacaoTarefa;

  // Specific fields for Alerta / Alarme
  final String? tituloAlerta;

  ReminderModel({
    required this.id,
    required this.type,
    this.nomeMedicamento,
    this.quantidadeMedicamento,
    this.horarios = const [],
    this.fotoPath,
    this.profissionalConsulta,
    this.horarioConsulta,
    this.dataConsulta,
    this.localConsulta,
    this.acompanhanteConsulta,
    this.motivoConsulta,
    this.nomeTarefa,
    this.especificacaoTarefa,
    this.tituloAlerta,
  });

  String get title {
    switch (type) {
      case ReminderType.medicamento:
        return (nomeMedicamento != null && nomeMedicamento!.isNotEmpty)
            ? nomeMedicamento!
            : 'Medicamento sem nome';
      case ReminderType.consulta:
        if (profissionalConsulta != null && profissionalConsulta!.isNotEmpty) {
          return 'Consulta com $profissionalConsulta';
        }
        if (motivoConsulta != null && motivoConsulta!.isNotEmpty) {
          return 'Consulta: $motivoConsulta';
        }
        return 'Consulta Médica';
      case ReminderType.tarefa:
        return (nomeTarefa != null && nomeTarefa!.isNotEmpty)
            ? nomeTarefa!
            : 'Tarefa sem nome';
      case ReminderType.alerta:
        if (tituloAlerta != null && tituloAlerta!.isNotEmpty) {
          return tituloAlerta!;
        }
        if (horarios.isNotEmpty) {
          return 'Alerta para as ${horarios.join(', ')}';
        }
        return 'Alerta';
    }
  }

  String get categoryLabel {
    switch (type) {
      case ReminderType.medicamento:
        return 'MEDICAMENTO';
      case ReminderType.consulta:
        return 'CONSULTA MÉDICA';
      case ReminderType.tarefa:
        return 'TAREFA';
      case ReminderType.alerta:
        return 'ALERTA';
    }
  }

  IconData get categoryIcon {
    switch (type) {
      case ReminderType.medicamento:
        return Icons.medication_outlined;
      case ReminderType.consulta:
        return Icons.local_hospital_outlined;
      case ReminderType.tarefa:
        return Icons.content_paste_outlined;
      case ReminderType.alerta:
        return Icons.alarm_outlined;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'nomeMedicamento': nomeMedicamento,
      'quantidadeMedicamento': quantidadeMedicamento,
      'horarios': horarios,
      'fotoPath': fotoPath,
      'profissionalConsulta': profissionalConsulta,
      'horarioConsulta': horarioConsulta,
      'dataConsulta': dataConsulta,
      'localConsulta': localConsulta,
      'acompanhanteConsulta': acompanhanteConsulta,
      'motivoConsulta': motivoConsulta,
      'nomeTarefa': nomeTarefa,
      'especificacaoTarefa': especificacaoTarefa,
      'tituloAlerta': tituloAlerta,
    };
  }

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReminderType.medicamento,
      ),
      nomeMedicamento: json['nomeMedicamento'] as String?,
      quantidadeMedicamento: json['quantidadeMedicamento'] as String?,
      horarios: (json['horarios'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      fotoPath: json['fotoPath'] as String?,
      profissionalConsulta: json['profissionalConsulta'] as String?,
      horarioConsulta: json['horarioConsulta'] as String?,
      dataConsulta: json['dataConsulta'] as String?,
      localConsulta: json['localConsulta'] as String?,
      acompanhanteConsulta: json['acompanhanteConsulta'] as String?,
      motivoConsulta: json['motivoConsulta'] as String?,
      nomeTarefa: json['nomeTarefa'] as String?,
      especificacaoTarefa: json['especificacaoTarefa'] as String?,
      tituloAlerta: json['tituloAlerta'] as String?,
    );
  }

  ReminderModel copyWith({
    String? id,
    ReminderType? type,
    String? nomeMedicamento,
    String? quantidadeMedicamento,
    List<String>? horarios,
    String? fotoPath,
    String? profissionalConsulta,
    String? horarioConsulta,
    String? dataConsulta,
    String? localConsulta,
    String? acompanhanteConsulta,
    String? motivoConsulta,
    String? nomeTarefa,
    String? especificacaoTarefa,
    String? tituloAlerta,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      type: type ?? this.type,
      nomeMedicamento: nomeMedicamento ?? this.nomeMedicamento,
      quantidadeMedicamento: quantidadeMedicamento ?? this.quantidadeMedicamento,
      horarios: horarios ?? this.horarios,
      fotoPath: fotoPath ?? this.fotoPath,
      profissionalConsulta: profissionalConsulta ?? this.profissionalConsulta,
      horarioConsulta: horarioConsulta ?? this.horarioConsulta,
      dataConsulta: dataConsulta ?? this.dataConsulta,
      localConsulta: localConsulta ?? this.localConsulta,
      acompanhanteConsulta: acompanhanteConsulta ?? this.acompanhanteConsulta,
      motivoConsulta: motivoConsulta ?? this.motivoConsulta,
      nomeTarefa: nomeTarefa ?? this.nomeTarefa,
      especificacaoTarefa: especificacaoTarefa ?? this.especificacaoTarefa,
      tituloAlerta: tituloAlerta ?? this.tituloAlerta,
    );
  }
}
