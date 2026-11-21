import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user_session_service.dart';

/// Modelo de alerta recebido do servidor
class EmergencyAlertItem {
  final String id;
  final String usuarioId;
  final String codigoVinculo;
  final String tipoAlerta; // 'queda', 'voz', 'botao_panico', 'samu'
  final String detalhes;
  final String telefoneDestino;
  final bool visto;
  final DateTime dataHora;
  final String seniorNome;

  EmergencyAlertItem({
    required this.id,
    required this.usuarioId,
    required this.codigoVinculo,
    required this.tipoAlerta,
    required this.detalhes,
    required this.telefoneDestino,
    required this.visto,
    required this.dataHora,
    required this.seniorNome,
  });

  factory EmergencyAlertItem.fromMap(Map<String, dynamic> map) {
    return EmergencyAlertItem(
      id: map['id']?.toString() ?? '',
      usuarioId: map['usuario_id']?.toString() ?? '',
      codigoVinculo: map['codigo_vinculo']?.toString() ?? '',
      tipoAlerta: map['tipo_alerta']?.toString() ?? 'queda',
      detalhes: map['detalhes']?.toString() ?? '',
      telefoneDestino: map['telefone_destino']?.toString() ?? '',
      visto: (map['visto'] == 1 || map['visto'] == '1' || map['visto'] == true),
      dataHora: DateTime.tryParse(map['data_hora']?.toString() ?? '') ?? DateTime.now(),
      seniorNome: map['senior_nome']?.toString() ?? 'Idoso Monitorado',
    );
  }
}

/// Serviço responsável por sincronizar alertas de emergência (queda, voz, botão de pânico)
/// e palavras de alerta entre Idoso, Cuidador e o Servidor MySQL.
class AlertSyncService {
  AlertSyncService._();
  static final AlertSyncService instance = AlertSyncService._();

  /// Registra um alerta de emergência no servidor MySQL
  Future<bool> registrarAlerta({
    required String tipo,
    required String detalhes,
    String? palavraChave,
    String? fraseDetectada,
    String? telefoneDestino,
  }) async {
    final session = UserSessionService.instance;
    final currentUser = session.currentUser;
    final codigo = currentUser.connectionCode ??
        session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        '';

    final payload = {
      'acao': 'criar',
      'tipo_alerta': tipo,
      'detalhes': detalhes,
      'codigo_vinculo': codigo,
      'usuario_id': currentUser.id,
      'senior_id': currentUser.id,
      'telefone_destino': telefoneDestino ?? currentUser.caregiverPhone ?? '',
      'sms_enviado': 1,
      if (palavraChave != null) 'palavra_chave': palavraChave,
      if (fraseDetectada != null) 'frase_detectada': fraseDetectada,
    };

    Future<bool> trySend(String baseUrl) async {
      try {
        final uri = Uri.parse('$baseUrl/alertas.php');
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['sucesso'] == true;
        }
      } catch (e) {
        debugPrint('[AlertSyncService] Erro ao enviar alerta para $baseUrl: $e');
      }
      return false;
    }

    bool ok = await trySend(ApiConfig.instance.baseUrl);
    if (!ok) {
      final alt = await ApiConfig.instance.findWorkingBaseUrl();
      if (alt != ApiConfig.instance.baseUrl) {
        ok = await trySend(alt);
      }
    }
    return ok;
  }

  /// Busca alertas no servidor para o cuidador monitorar o idoso
  Future<List<EmergencyAlertItem>> buscarAlertas({
    String? codigo,
    String? userId,
    bool apenasNaoVistos = false,
  }) async {
    final session = UserSessionService.instance;
    final effectiveCodigo = codigo ??
        session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.currentUser.connectionCode ??
        '';

    final effectiveUserId = userId ??
        session.partnerUser?.id ??
        (session.currentUser.isCaregiver ? '' : session.currentUser.id);

    Future<List<EmergencyAlertItem>?> tryFetch(String baseUrl) async {
      try {
        var query = 'acao=listar';
        if (effectiveCodigo.isNotEmpty) {
          query += '&codigo=${Uri.encodeComponent(effectiveCodigo)}';
        } else if (effectiveUserId.isNotEmpty) {
          query += '&user_id=${Uri.encodeComponent(effectiveUserId)}';
        }

        final uri = Uri.parse('$baseUrl/alertas.php?$query');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['sucesso'] == true && data['alertas'] is List) {
            final List list = data['alertas'];
            return list.map((a) => EmergencyAlertItem.fromMap(a)).toList();
          }
        }
      } catch (_) {}
      return null;
    }

    List<EmergencyAlertItem>? items = await tryFetch(ApiConfig.instance.baseUrl);
    if (items == null) {
      final alt = await ApiConfig.instance.findWorkingBaseUrl();
      if (alt != ApiConfig.instance.baseUrl) {
        items = await tryFetch(alt);
      }
    }

    if (items != null) {
      if (apenasNaoVistos) {
        return items.where((a) => !a.visto).toList();
      }
      return items;
    }
    return [];
  }

  /// Marca um alerta como atendido/visto no servidor
  Future<bool> marcarVisto(String alertaId) async {
    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/alertas.php');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'acao': 'marcar_visto',
              'alerta_id': alertaId,
            }),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['sucesso'] == true;
      }
    } catch (_) {}
    return false;
  }

  /// Obtém palavras de alerta salvas para o idoso
  Future<List<String>> obterPalavrasAlerta({String? codigo}) async {
    final session = UserSessionService.instance;
    final cod = codigo ??
        session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.currentUser.connectionCode ??
        '';

    if (cod.isEmpty) return [];

    try {
      final uri = Uri.parse(
          '${ApiConfig.instance.baseUrl}/alertas.php?acao=obter_palavras&codigo=${Uri.encodeComponent(cod)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['sucesso'] == true && data['palavras'] is List) {
          return List<String>.from(data['palavras']);
        }
      }
    } catch (_) {}
    return [];
  }

  /// Salva palavras de alerta configuradas pelo cuidador no servidor
  Future<bool> salvarPalavrasAlerta({
    required String codigo,
    required List<String> palavras,
    String? seniorId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/alertas.php');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'acao': 'salvar_palavras',
              'codigo': codigo.trim().toUpperCase(),
              'senior_id': seniorId ?? '',
              'palavras': palavras,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['sucesso'] == true;
      }
    } catch (e) {
      debugPrint('[AlertSyncService] Erro ao salvar palavras: $e');
    }
    return false;
  }
}
