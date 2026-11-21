import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medical_exam_model.dart';
import 'api_config.dart';

/// Serviço que gerencia o armazenamento local e em nuvem (MySQL) dos exames do idoso.
class MedicalExamService {
  MedicalExamService._();
  static final MedicalExamService instance = MedicalExamService._();

  static const String _prefPrefix = 'pp_saved_exams_';

  String _getKey(String seniorId, String code) {
    final clean = (code.isNotEmpty ? code : seniorId).trim().toUpperCase();
    return '$_prefPrefix$clean';
  }

  /// Recupera exames do armazenamento local e tenta sincronizar com o MySQL em background
  Future<List<MedicalExamModel>> getExams({
    required String seniorId,
    required String connectionCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(seniorId, connectionCode);

    // 1. Carrega primeiro do armazenamento local (rápido e offline)
    List<MedicalExamModel> localExams = [];
    final raw = prefs.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        localExams = decoded
            .map((item) => MedicalExamModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[MedicalExamService] Erro ao carregar exames locais: $e');
      }
    }

    // 2. Busca do servidor MySQL em tempo real
    try {
      final baseUrl = ApiConfig.instance.baseUrl;
      final queryParam = connectionCode.isNotEmpty
          ? 'codigo=${Uri.encodeComponent(connectionCode)}'
          : 'senior_id=${Uri.encodeComponent(seniorId)}';

      final uri = Uri.parse('$baseUrl/exames.php?$queryParam');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['sucesso'] == true && data['exames'] is List) {
          final serverList = (data['exames'] as List)
              .map((item) => MedicalExamModel.fromMap(item as Map<String, dynamic>))
              .toList();

          // Mescla com dados locais caso haja fotos locais ainda não sincronizadas
          final Map<String, MedicalExamModel> mergedMap = {};
          for (final e in localExams) {
            mergedMap[e.id] = e;
          }
          for (final s in serverList) {
            if (mergedMap.containsKey(s.id)) {
              // Mantém o path local se o servidor tiver apenas base64
              final existing = mergedMap[s.id]!;
              mergedMap[s.id] = MedicalExamModel(
                id: s.id,
                seniorId: s.seniorId,
                codigoVinculo: s.codigoVinculo,
                titulo: s.titulo,
                categoria: s.categoria,
                dataExame: s.dataExame,
                medicoLaboratorio: s.medicoLaboratorio,
                observacoes: s.observacoes,
                imagemBase64: s.imagemBase64 ?? existing.imagemBase64,
                imageLocalPath: existing.imageLocalPath,
                criadoEm: s.criadoEm,
              );
            } else {
              mergedMap[s.id] = s;
            }
          }

          final finalList = mergedMap.values.toList()
            ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

          // Atualiza o cache local
          await prefs.setString(
            key,
            jsonEncode(finalList.map((e) => e.toMap()).toList()),
          );

          return finalList;
        }
      }
    } catch (e) {
      debugPrint('[MedicalExamService] Servidor inacessível, usando dados locais: $e');
    }

    return localExams;
  }

  /// Salva um novo exame (ou atualiza) localmente e no MySQL
  Future<bool> saveExam(MedicalExamModel exam) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(exam.seniorId, exam.codigoVinculo);

    // 1. Processa a imagem para Base64 se for um arquivo local
    String? base64Img = exam.imagemBase64;
    if ((base64Img == null || base64Img.isEmpty) && exam.imageLocalPath != null) {
      try {
        final file = File(exam.imageLocalPath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          base64Img = base64Encode(bytes);
        }
      } catch (e) {
        debugPrint('[MedicalExamService] Erro ao converter imagem para base64: $e');
      }
    }

    final examToSave = MedicalExamModel(
      id: exam.id,
      seniorId: exam.seniorId,
      codigoVinculo: exam.codigoVinculo,
      titulo: exam.titulo,
      categoria: exam.categoria,
      dataExame: exam.dataExame,
      medicoLaboratorio: exam.medicoLaboratorio,
      observacoes: exam.observacoes,
      imagemBase64: base64Img,
      imageLocalPath: exam.imageLocalPath,
      criadoEm: exam.criadoEm,
    );

    // 2. Salva localmente primeiro
    try {
      final currentList = await getExams(
        seniorId: exam.seniorId,
        connectionCode: exam.codigoVinculo,
      );

      final index = currentList.indexWhere((e) => e.id == examToSave.id);
      if (index >= 0) {
        currentList[index] = examToSave;
      } else {
        currentList.insert(0, examToSave);
      }

      await prefs.setString(
        key,
        jsonEncode(currentList.map((e) => e.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('[MedicalExamService] Erro ao persistir exame no SharedPreferences: $e');
    }

    // 3. Envia para o MySQL em background
    try {
      final baseUrl = ApiConfig.instance.baseUrl;
      final uri = Uri.parse('$baseUrl/exames.php');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'acao': 'salvar',
              'id': examToSave.id,
              'senior_id': examToSave.seniorId,
              'codigo_vinculo': examToSave.codigoVinculo,
              'titulo': examToSave.titulo,
              'categoria': examToSave.categoria,
              'data_exame': examToSave.dataExame,
              'medico_laboratorio': examToSave.medicoLaboratorio,
              'observacoes': examToSave.observacoes,
              'imagem_base64': examToSave.imagemBase64 ?? '',
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['sucesso'] == true;
      }
    } catch (e) {
      debugPrint('[MedicalExamService] Erro ao sincronizar exame com MySQL: $e');
    }

    return true; // Retorna true pois foi salvo localmente com sucesso
  }

  /// Exclui um exame localmente e no MySQL
  Future<bool> deleteExam(
    String examId, {
    required String seniorId,
    required String connectionCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(seniorId, connectionCode);

    // 1. Remove localmente
    try {
      final currentList = await getExams(
        seniorId: seniorId,
        connectionCode: connectionCode,
      );
      currentList.removeWhere((e) => e.id == examId);

      await prefs.setString(
        key,
        jsonEncode(currentList.map((e) => e.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('[MedicalExamService] Erro ao excluir do cache local: $e');
    }

    // 2. Remove do MySQL
    try {
      final baseUrl = ApiConfig.instance.baseUrl;
      final uri = Uri.parse('$baseUrl/exames.php');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'acao': 'excluir',
              'id': examId,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    return true;
  }
}

