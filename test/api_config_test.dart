import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proteger_plus/services/api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiConfig endpoint discovery & BOM handling', () {
    test('parseRemoteEndpointBody strips UTF-8 BOM and parses valid payload', () {
      const withBom = '\uFEFF{"api_url":"https://live-tunnel.trycloudflare.com/proteger_plus_api/","local_ip":"192.168.1.10"}';
      final parsed = ApiConfig.parseRemoteEndpointBody(withBom);

      expect(parsed, isNotNull);
      expect(parsed!['api_url'], 'https://live-tunnel.trycloudflare.com/proteger_plus_api');
      expect(parsed['local_ip'], '192.168.1.10');
    });

    test('parseRemoteEndpointBody rejects invalid or non-http payloads', () {
      expect(ApiConfig.parseRemoteEndpointBody(''), isNull);
      expect(ApiConfig.parseRemoteEndpointBody('{"api_url":"ftp://bad"}'), isNull);
    });

    test('init fetches remote endpoint with BOM and updates stale trycloudflare cache', () async {
      SharedPreferences.setMockInitialValues({
        'custom_api_base_url': 'https://old-dead-tunnel.trycloudflare.com/proteger_plus_api',
        'custom_api_manual_override': false,
      });

      final mockClient = MockClient((request) async {
        final url = request.url.toString();
        if (url.contains('api.github.com/repos/iasmymsa-ux/ProtegerPlus/contents/api_endpoint.json')) {
          return http.Response.bytes(
            utf8.encode(
              '\uFEFF{"api_url":"https://fresh-tunnel-2026.trycloudflare.com/proteger_plus_api","local_ip":"192.168.1.55"}',
            ),
            200,
          );
        }
        if (url == 'https://fresh-tunnel-2026.trycloudflare.com/proteger_plus_api/usuarios.php?acao=test') {
          return http.Response('{"sucesso":true,"usuarios":[]}', 200);
        }
        return http.Response('error', 404);
      });

      await ApiConfig.instance.init(client: mockClient);

      expect(
        ApiConfig.instance.baseUrl,
        'https://fresh-tunnel-2026.trycloudflare.com/proteger_plus_api',
      );
    });

    test('findWorkingBaseUrl falls back to raw github endpoint when current tunnel fails', () async {
      await ApiConfig.instance.setBaseUrl(
        'https://broken-tunnel.trycloudflare.com/proteger_plus_api',
        manual: false,
      );

      final mockClient = MockClient((request) async {
        final url = request.url.toString();
        if (url.contains('broken-tunnel.trycloudflare.com')) {
          return http.Response('error code: 1033', 530);
        }
        if (url.contains('api.github.com')) {
          return http.Response('rate limited', 403);
        }
        if (url.contains('raw.githubusercontent.com/iasmymsa-ux/ProtegerPlus/main/api_endpoint.json')) {
          return http.Response(
            '{"api_url":"https://recovered-tunnel.trycloudflare.com/proteger_plus_api"}',
            200,
          );
        }
        if (url == 'https://recovered-tunnel.trycloudflare.com/proteger_plus_api/usuarios.php?acao=test') {
          return http.Response('{"sucesso":true}', 200);
        }
        return http.Response('not found', 404);
      });

      final resolved = await ApiConfig.instance.findWorkingBaseUrl(client: mockClient);
      expect(resolved, 'https://recovered-tunnel.trycloudflare.com/proteger_plus_api');
      expect(ApiConfig.instance.baseUrl, resolved);
    });
  });
}

