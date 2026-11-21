import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Configuração central da API do servidor Proteger Plus.
class ApiConfig {
  ApiConfig._();
  static final ApiConfig instance = ApiConfig._();

  static const String _keyCustomBaseUrl = 'custom_api_base_url';

  // URL pública HTTPS (Cloudflare Tunnel ativo agora)
  static const String defaultPublicUrl =
      'https://prayers-served-premiere-restructuring.trycloudflare.com/proteger_plus_api';

  // IPs comuns da máquina para teste local / Wi-Fi
  static const String defaultLocalIp = '192.168.1.6';
  static const String fallbackLocalIp = '200.131.247.15';

  String _baseUrl = defaultPublicUrl;

  String get baseUrl => _baseUrl;

  static const String _remoteEndpointConfigUrl =
      'https://raw.githubusercontent.com/iasmymsa-ux/ProtegerPlus/main/api_endpoint.json';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString(_keyCustomBaseUrl);
      if (custom != null && custom.isNotEmpty) {
        if (custom.contains('broadway-hat') ||
            custom.contains('duty-alice') ||
            custom.contains('towers-mild') ||
            custom.contains('thumbzilla') ||
            custom.contains('curves-adds') ||
            custom.contains('plugins-ontario') ||
            custom.contains('heath-korean') ||
            custom.contains('medieval-vcr') ||
            custom.contains('mazda-prepaid')) {
          _baseUrl = defaultPublicUrl;
          await prefs.setString(_keyCustomBaseUrl, defaultPublicUrl);
        } else {
          _baseUrl = custom.trim();
        }
      } else {
        if (kIsWeb) {
          _baseUrl = 'http://localhost/proteger_plus_api';
        } else {
          _baseUrl = defaultPublicUrl;
        }
      }

      // Tenta obter dinamicamente a URL pública mais recente em background
      if (!kIsWeb) {
        _fetchRemoteEndpoint();
      }
    } catch (e) {
      debugPrint('[ApiConfig] Erro ao carregar URL da API: $e');
    }
  }

  /// Consulta automaticamente o repositório para obter o endereço público ativo se disponível
  Future<void> _fetchRemoteEndpoint() async {
    try {
      final res = await http
          .get(Uri.parse(_remoteEndpointConfigUrl))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final remoteUrl = data['api_url']?.toString().trim();
        if (remoteUrl != null && remoteUrl.startsWith('http')) {
          _baseUrl = remoteUrl;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyCustomBaseUrl, _baseUrl);
          debugPrint('[ApiConfig] Endpoint atualizado automaticamente: $_baseUrl');
        }
      }
    } catch (e) {
      debugPrint('[ApiConfig] Mantendo endpoint atual: $e');
    }
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomBaseUrl, _baseUrl);
  }

  static List<String> get candidateUrls => [
        defaultPublicUrl,
        'http://$defaultLocalIp/proteger_plus_api',
        'http://$fallbackLocalIp/proteger_plus_api',
        'http://10.0.2.2/proteger_plus_api',
        'http://localhost/proteger_plus_api',
      ];

  /// Encontra o primeiro endpoint funcional testando os servidores alternativos rapidamente
  Future<String> findWorkingBaseUrl() async {
    // 1. Testa o endpoint configurado atualmente
    if (await testConnection(_baseUrl)) {
      return _baseUrl;
    }

    // 2. Testa candidatos com timeout curto
    for (final candidate in candidateUrls) {
      if (candidate != _baseUrl && await testConnection(candidate)) {
        await setBaseUrl(candidate);
        debugPrint('[ApiConfig] Endpoint recuperado: $candidate');
        return candidate;
      }
    }

    return _baseUrl;
  }

  /// Testa se a URL da API está respondendo corretamente
  Future<bool> testConnection([String? urlToTest]) async {
    final target = (urlToTest ?? _baseUrl).trim();
    try {
      final uri = Uri.parse('$target/usuarios.php?acao=test');
      final res = await http.get(uri).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['sucesso'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
