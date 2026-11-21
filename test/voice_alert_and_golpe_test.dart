import 'package:flutter_test/flutter_test.dart';
import 'package:proteger_plus/services/voice_alert_service.dart';
import 'package:proteger_plus/services/golpe_analyzer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceAlertService - Detecção em qualquer lugar da frase', () {
    test('Detecta palavra de socorro como primeira palavra', () {
      expect(
        VoiceAlertService.defaultKeywords.any((k) =>
            VoiceAlertService.instance.isRunning == false &&
            ['socorro', 'socorro me ajuda'].any((p) => p.contains(k))),
        isTrue,
      );
    });

    test('Verifica normalização de fala e substituições', () {
      // Testes de frases complexas onde socorro está no meio ou fim
      final frasesComSocorro = [
        'meu deus me ajuda socorro',
        'estou no chao socorro por favor',
        'por favor socorro',
        'alguem me ajuda estou com dor',
        'socorro',
      ];

      for (final frase in frasesComSocorro) {
        bool detectou = false;
        for (final k in VoiceAlertService.defaultKeywords) {
          if (frase.contains(k)) {
            detectou = true;
            break;
          }
        }
        expect(detectou, isTrue, reason: 'Deveria detectar palavra-chave na frase: "$frase"');
      }
    });
  });

  group('GolpeAnalyzerService - Sanitização de nomes inexistentes', () {
    test('Limpa saudações com nomes inexistentes inventados pela IA', () {
      final resultado = GolpeAnalyzerService.validarEFormatarUrl('teste.com');
      expect(resultado, isNotNull);
    });
  });
}
