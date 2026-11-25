import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Configuração central da API do servidor Proteger Plus.
class ApiConfig {
  ApiConfig._();
  static final ApiConfig instance = ApiConfig._();

  static const String _keyCustomBaseUrl = 'custom_api_base_url';
  static const String _keyManualOverride = 'custom_api_manual_override';

  // URL pública HTTPS (Cloudflare Tunnel ativo agora)
  static const String defaultPublicUrl =
      'https://supplies-respective-nail-scope.trycloudflare.com/proteger_plus_api';

  // IPs comuns da máquina para teste local / Wi-Fi
  static const String defaultLocalIp = '192.168.1.10';
  static const String fallbackLocalIp = '192.168.1.6';

  static const String _githubApiEndpointConfigUrl =
      'https://api.github.com/repos/iasmymsa-ux/ProtegerPlus/contents/api_endpoint.json';
  static const String _rawRemoteEndpointConfigUrl =
      'https://raw.githubusercontent.com/iasmymsa-ux/ProtegerPlus/main/api_endpoint.json';

  static const List<String> _knownExpiredTunnelTokens = [
    'broadway-hat',
    'duty-alice',
    'towers-mild',
    'thumbzilla',
    'curves-adds',
    'plugins-ontario',
    'heath-korean',
    'medieval-vcr',
    'mazda-prepaid',
    'prayers-served',
    'blackberry-governmental',
    'angeles-accent',
    'programmer-characterization',
    'undergraduate-economic',
  ];

  String _baseUrl = defaultPublicUrl;
  String? _discoveredLocalIp;

  String get baseUrl => _baseUrl;

  /// Normaliza URLs removendo espaços e barras finais.
  static String normalizeUrl(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '');

  /// Retorna true se a URL corresponder a um túnel conhecido como expirado.
  static bool isStaleTunnelUrl(String url) {
    final normalized = normalizeUrl(url);
    return _knownExpiredTunnelTokens.any(normalized.contains);
  }

  /// Faz parse do JSON remoto removendo eventual UTF-8 BOM inicial.
  static Map<String, String>? parseRemoteEndpointBody(String body) {
    final cleaned = body.replaceFirst(RegExp(r'^\uFEFF+'), '').trim();
    if (cleaned.isEmpty) return null;

    final dynamic data = jsonDecode(cleaned);
    if (data is! Map) return null;

    final normalizedUrl = normalizeUrl(data['api_url']?.toString() ?? '');
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      return null;
    }

    final result = <String, String>{'api_url': normalizedUrl};
    final localIp = data['local_ip']?.toString().trim() ?? '';
    if (localIp.isNotEmpty) {
      result['local_ip'] = localIp;
    }
    return result;
  }

  Future<void> init({http.Client? client}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString(_keyCustomBaseUrl);
      final isManual = prefs.getBool(_keyManualOverride) ?? false;

      if (kIsWeb) {
        _baseUrl = (custom != null && custom.isNotEmpty && isManual)
            ? normalizeUrl(custom)
            : 'http://localhost/proteger_plus_api';
        return;
      }

      if (custom != null && custom.isNotEmpty && !isStaleTunnelUrl(custom)) {
        _baseUrl = normalizeUrl(custom);
      } else {
        _baseUrl = defaultPublicUrl;
        if (custom != null && isStaleTunnelUrl(custom)) {
          await prefs.setString(_keyCustomBaseUrl, defaultPublicUrl);
          await prefs.setBool(_keyManualOverride, false);
        }
      }

      // Obtém e valida o endpoint remoto mais recente antes das chamadas de login/sync
      final shouldPreferRemote = !isManual ||
          custom == null ||
          custom.isEmpty ||
          _baseUrl.contains('.trycloudflare.com');
      if (shouldPreferRemote) {
        final remoteUrl =
            await refreshFromRemote(client: client, applyIfFound: false);
        if (remoteUrl != null &&
            remoteUrl != _baseUrl &&
            !isStaleTunnelUrl(remoteUrl)) {
          final remoteHealthy = await testConnection(remoteUrl, client);
          final currentHealthy =
              remoteHealthy ? false : await testConnection(_baseUrl, client);
          if (remoteHealthy || !currentHealthy) {
            await setBaseUrl(remoteUrl, manual: false);
            debugPrint('[ApiConfig] Endpoint atualizado automaticamente: $_baseUrl');
          }
        }
      }
    } catch (e) {
      debugPrint('[ApiConfig] Erro ao carregar URL da API: $e');
    }
  }

  /// Consulta o repositório para obter o endereço público ativo mais recente.
  Future<String?> refreshFromRemote({
    http.Client? client,
    bool applyIfFound = true,
  }) async {
    final ownClient = client == null;
    final httpClient = client ?? http.Client();
    try {
      final remote = await _fetchFromSources(httpClient);
      if (remote == null) return null;

      final remoteUrl = remote['api_url']!;
      final remoteLocalIp = remote['local_ip'];
      if (remoteLocalIp != null && remoteLocalIp.isNotEmpty) {
        _discoveredLocalIp = remoteLocalIp;
      }

      if (applyIfFound && !isStaleTunnelUrl(remoteUrl)) {
        await setBaseUrl(remoteUrl, manual: false);
        debugPrint('[ApiConfig] Endpoint atualizado automaticamente: $_baseUrl');
      }
      return remoteUrl;
    } catch (e) {
      debugPrint('[ApiConfig] Mantendo endpoint atual: $e');
      return null;
    } finally {
      if (ownClient) {
        httpClient.close();
      }
    }
  }

  Future<Map<String, String>?> _fetchFromSources(http.Client client) async {
    final rawCacheBuster =
        '$_rawRemoteEndpointConfigUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    final sources = <({Uri uri, Map<String, String>? headers})>[
      (
        uri: Uri.parse(_githubApiEndpointConfigUrl),
        headers: const {
          'Accept': 'application/vnd.github.raw+json',
          'User-Agent': 'ProtegerPlusApp',
        },
      ),
      (uri: Uri.parse(rawCacheBuster), headers: null),
    ];

    for (final src in sources) {
      try {
        final res = await client
            .get(src.uri, headers: src.headers)
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final bodyText = utf8.decode(res.bodyBytes, allowMalformed: true);
          final parsed = parseRemoteEndpointBody(bodyText);
          if (parsed != null) return parsed;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> setBaseUrl(String url, {bool? manual}) async {
    _baseUrl = normalizeUrl(url);
    final isManual = manual ?? !_baseUrl.contains('.trycloudflare.com');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomBaseUrl, _baseUrl);
    await prefs.setBool(_keyManualOverride, isManual);
  }

  static List<String> get candidateUrls => [
        defaultPublicUrl,
        'http://$defaultLocalIp/proteger_plus_api',
        'http://$fallbackLocalIp/proteger_plus_api',
        'http://10.0.2.2/proteger_plus_api',
        'http://localhost/proteger_plus_api',
      ];

  List<String> get _effectiveCandidateUrls {
    final list = <String>[
      if (_discoveredLocalIp != null && _discoveredLocalIp!.isNotEmpty)
        'http://$_discoveredLocalIp/proteger_plus_api',
      ...candidateUrls,
    ];
    return list.toSet().toList();
  }

  /// Encontra o primeiro endpoint funcional atualizando do remoto e testando alternativas locais.
  Future<String> findWorkingBaseUrl({http.Client? client}) async {
    // 1. Testa o endpoint configurado atualmente
    if (await testConnection(_baseUrl, client)) {
      return _baseUrl;
    }

    // 2. Consulta o endpoint publicado no GitHub caso o túnel tenha mudado
    if (!kIsWeb) {
      final remoteUrl =
          await refreshFromRemote(client: client, applyIfFound: false);
      if (remoteUrl != null &&
          remoteUrl != _baseUrl &&
          await testConnection(remoteUrl, client)) {
        await setBaseUrl(remoteUrl, manual: false);
        debugPrint('[ApiConfig] Endpoint remoto recuperado: $remoteUrl');
        return remoteUrl;
      }
    }

    // 3. Testa candidatos locais/padrão com timeout curto
    for (final candidate in _effectiveCandidateUrls) {
      if (candidate != _baseUrl &&
          await testConnection(candidate, client)) {
        await setBaseUrl(candidate, manual: false);
        debugPrint('[ApiConfig] Endpoint recuperado: $candidate');
        return candidate;
      }
    }

    return _baseUrl;
  }

  /// Testa se a URL da API está respondendo corretamente
  Future<bool> testConnection([String? urlToTest, http.Client? client]) async {
    final target = normalizeUrl(urlToTest ?? _baseUrl);
    if (target.isEmpty) return false;
    final ownClient = client == null;
    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse('$target/usuarios.php?acao=test');
      final res = await httpClient.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final bodyText = utf8.decode(res.bodyBytes, allowMalformed: true);
        final cleaned = bodyText.replaceFirst(RegExp(r'^\uFEFF+'), '').trim();
        final data = jsonDecode(cleaned);
        return data is Map && data['sucesso'] == true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      if (ownClient) {
        httpClient.close();
      }
    }
  }
}
