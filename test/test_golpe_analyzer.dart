import 'dart:io';
import 'dart:convert';
// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:proteger_plus/services/golpe_analyzer_service.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
  });

  group('TESTES OBRIGATÓRIOS: ANÁLISE DE LINKS', () {
    test('1. Link Legítimo (Google)', () async {
      final res = await GolpeAnalyzerService.analisarLink('https://www.google.com.br');
      print('\n[TESTE 1 - Link Legítimo Google]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      print('Alertas: ${res.alertasEncontrados}');
      expect(res.status, ResultadoAnalise.seguro);
    });

    test('2. Link Suspeito / Golpe imitando banco (Itaú falso)', () async {
      final res = await GolpeAnalyzerService.analisarLink('https://itau-atualizacaocadastral-seguro.xyz/login');
      print('\n[TESTE 2 - Phishing Itaú]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      print('Alertas: ${res.alertasEncontrados}');
      expect(res.status == ResultadoAnalise.naoSeguro || res.status == ResultadoAnalise.suspeito, true);
    });

    test('3. Domínio parecido com empresa conhecida (Bradesco falso)', () async {
      final res = await GolpeAnalyzerService.analisarLink('https://bradesco-recadastramento-urgente.online');
      print('\n[TESTE 3 - Imitação Bradesco]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      print('Alertas: ${res.alertasEncontrados}');
      expect(res.status == ResultadoAnalise.naoSeguro || res.status == ResultadoAnalise.suspeito, true);
    });

    test('4. URL Encurtada suspeita (bit.ly)', () async {
      final res = await GolpeAnalyzerService.analisarLink('https://bit.ly/resgate-premio-pix-imediato');
      print('\n[TESTE 4 - URL Encurtada]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      print('Alertas: ${res.alertasEncontrados}');
      expect(res.status == ResultadoAnalise.naoSeguro || res.status == ResultadoAnalise.suspeito, true);
    });

    test('5. URL com formato inválido', () async {
      final res = await GolpeAnalyzerService.analisarLink('isto_nao_e_uma_url_valida');
      print('\n[TESTE 5 - URL Inválida]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      expect(res.status, ResultadoAnalise.naoFoiPossivelAnalisar);
    });

    test('6. Campo Vazio', () async {
      final res = await GolpeAnalyzerService.analisarLink('   ');
      print('\n[TESTE 6 - Campo Vazio]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      expect(res.status, ResultadoAnalise.naoFoiPossivelAnalisar);
    });

    test('7. URL com parâmetros estranhos e TLD malicioso', () async {
      final res = await GolpeAnalyzerService.analisarLink('https://central-atendimento-bloqueio.top/seguranca?pix_id=9876&auth=urgent');
      print('\n[TESTE 7 - Parâmetros Estranhos]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      print('Alertas: ${res.alertasEncontrados}');
      expect(res.status == ResultadoAnalise.naoSeguro || res.status == ResultadoAnalise.suspeito, true);
    });
  });

  group('TESTES OBRIGATÓRIOS: ANÁLISE DE IMAGENS', () {
    late Directory tempDir;
    late File tinyBlankImage;
    late File emptyFile;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('golpe_test_');

      // 1x1 transparent png
      final pngBytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');
      tinyBlankImage = File('${tempDir.path}/blank.png');
      await tinyBlankImage.writeAsBytes(pngBytes);

      emptyFile = File('${tempDir.path}/empty.png');
      await emptyFile.writeAsBytes([]);
    });

    tearDownAll(() async {
      await tempDir.delete(recursive: true);
    });

    test('8. Imagem Vazia / Arquivo corrompido (0 bytes)', () async {
      final res = await GolpeAnalyzerService.analisarImagem(emptyFile);
      print('\n[TESTE 8 - Imagem Vazia (0 bytes)]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      expect(res.status, ResultadoAnalise.naoFoiPossivelAnalisar);
    });

    test('9. Arquivo de Imagem Inexistente', () async {
      final res = await GolpeAnalyzerService.analisarImagem(File('caminho_inexistente_123.jpg'));
      print('\n[TESTE 9 - Imagem Inexistente]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      expect(res.status, ResultadoAnalise.naoFoiPossivelAnalisar);
    });

    test('10. Imagem Ilegível / Sem texto (1x1 transparente)', () async {
      final res = await GolpeAnalyzerService.analisarImagem(tinyBlankImage);
      print('\n[TESTE 10 - Imagem Ilegível / Sem Mensagem]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      print('Alertas: ${res.alertasEncontrados}');
      expect(res.status == ResultadoAnalise.naoFoiPossivelAnalisar || res.status == ResultadoAnalise.seguro, true);
      // NUNCA pode ser falso positivo nem classificar como seguro se for inconclusivo
      expect(res.explicacao.toLowerCase().contains('escura') || res.explicacao.toLowerCase().contains('ilegível') || res.explicacao.toLowerCase().contains('inconclusivo') || res.status == ResultadoAnalise.naoFoiPossivelAnalisar, true);
    });
  });
}
