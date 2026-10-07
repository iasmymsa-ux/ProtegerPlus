import 'package:flutter_test/flutter_test.dart';
import 'package:proteger_plus/services/golpe_analyzer_service.dart';

void main() {
  group('GolpeAnalyzerService - Tests for Link/URL Analysis', () {
    test('1 & 2. Invalid or empty text returns null validation', () {
      expect(GolpeAnalyzerService.validarEFormatarUrl(''), isNull);
      expect(GolpeAnalyzerService.validarEFormatarUrl('   '), isNull);
      expect(GolpeAnalyzerService.validarEFormatarUrl('texto qualquer sem ponto'), isNull);
    });

    test('3. Valid URL without protocol gets formatted with https', () {
      final formatted = GolpeAnalyzerService.validarEFormatarUrl('google.com');
      expect(formatted, 'https://google.com');
    });

    test('4. HTTP URL triggers non-HTTPS warning', () {
      final result = GolpeAnalyzerService.analisarHeuristicaUrl('http://meusite.com');
      expect(result.status, ResultadoAnalise.suspeito);
      expect(result.alertasEncontrados.any((a) => a.contains('HTTPS')), isTrue);
    });

    test('5. Shortened URL triggers shortener warning', () {
      final result = GolpeAnalyzerService.analisarHeuristicaUrl('https://bit.ly/12345');
      expect(result.status, ResultadoAnalise.suspeito);
      expect(result.alertasEncontrados.any((a) => a.contains('encurtado')), isTrue);
    });

    test('6. Known official domain returns SEGURO status', () {
      final result = GolpeAnalyzerService.analisarHeuristicaUrl('https://bradesco.com.br');
      expect(result.status, ResultadoAnalise.seguro);
      expect(result.explicacao, contains('oficial'));
    });

    test('7. Brand impersonation on suspicious TLD returns NAO_SEGURO', () {
      final result = GolpeAnalyzerService.analisarHeuristicaUrl('https://bancobradesco-recadastro.xyz');
      expect(result.status, ResultadoAnalise.naoSeguro);
      expect(result.alertasEncontrados.any((a) => a.contains('imitar')), isTrue);
    });

    test('8. IP address hostname returns NAO_SEGURO', () {
      final result = GolpeAnalyzerService.analisarHeuristicaUrl('http://192.168.1.1/login');
      expect(result.status, ResultadoAnalise.naoSeguro);
      expect(result.alertasEncontrados.any((a) => a.contains('IP')), isTrue);
    });
  });
}
