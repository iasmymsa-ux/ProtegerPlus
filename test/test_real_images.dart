import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:proteger_plus/services/golpe_analyzer_service.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = null; // Permite requisições de rede reais nos testes
  });

  group('TESTES OBRIGATÓRIOS: ANÁLISE DE IMAGENS REAIS COM IA GEMINI', () {
    test('1. Imagem com Golpe do Pix / Falso Filho (scam_pix.jpg)', () async {
      final file = File('test/fixtures/scam_pix.jpg');
      expect(file.existsSync(), isTrue);

      final bytes = await file.readAsBytes();
      final res = await GolpeAnalyzerService.analisarImagem(
        bytes,
        nomeArquivo: 'scam_pix.jpg',
      );

      print('\n======================================================');
      print('[TESTE IMAGEM 1 - Golpe do Pix / Falso Filho]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      print('Alertas: ${res.alertasEncontrados}');
      print('======================================================');

      expect(
        res.status == ResultadoAnalise.naoSeguro || res.status == ResultadoAnalise.suspeito,
        isTrue,
        reason: 'Mensagem de golpe do Pix deve ser classificada como risco ou suspeita',
      );
      expect(res.status, isNot(ResultadoAnalise.seguro));
    });

    test('2. Imagem com Falso Alerta de Banco / Pedido de Senha (scam_bank.jpg)', () async {
      final file = File('test/fixtures/scam_bank.jpg');
      expect(file.existsSync(), isTrue);

      final bytes = await file.readAsBytes();
      final res = await GolpeAnalyzerService.analisarImagem(
        bytes,
        nomeArquivo: 'scam_bank.jpg',
      );

      print('\n======================================================');
      print('[TESTE IMAGEM 2 - Falso Banco do Brasil / Senha]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      print('Alertas: ${res.alertasEncontrados}');
      print('======================================================');

      expect(
        res.status == ResultadoAnalise.naoSeguro || res.status == ResultadoAnalise.suspeito,
        isTrue,
        reason: 'Falso banco pedindo senha deve ser classificado como golpe',
      );
      expect(res.status, isNot(ResultadoAnalise.seguro));
    });

    test('3. Imagem Legítima / Conversa Familiar Segura (legit_chat.jpg)', () async {
      final file = File('test/fixtures/legit_chat.jpg');
      expect(file.existsSync(), isTrue);

      final bytes = await file.readAsBytes();
      final res = await GolpeAnalyzerService.analisarImagem(
        bytes,
        nomeArquivo: 'legit_chat.jpg',
      );

      print('\n======================================================');
      print('[TESTE IMAGEM 3 - Conversa de Família Legítima]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      print('Alertas: ${res.alertasEncontrados}');
      print('======================================================');

      expect(
        res.status,
        ResultadoAnalise.seguro,
        reason: 'Mensagem carinhosa de receita familiar sem pedidos de dinheiro deve ser segura',
      );
    });

    test('4. Confirmação de que imagens diferentes geram análises e explicações diferentes', () async {
      final bytesScam = await File('test/fixtures/scam_pix.jpg').readAsBytes();
      final bytesLegit = await File('test/fixtures/legit_chat.jpg').readAsBytes();

      final resScam = await GolpeAnalyzerService.analisarImagem(bytesScam, nomeArquivo: 'scam.jpg');
      final resLegit = await GolpeAnalyzerService.analisarImagem(bytesLegit, nomeArquivo: 'legit.jpg');

      expect(resScam.status, isNot(equals(resLegit.status)));
      expect(resScam.explicacao, isNot(equals(resLegit.explicacao)));
    });

    test('5. Imagem Ilegível / Sem texto visível (1x1)', () async {
      final pngBytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');
      final res = await GolpeAnalyzerService.analisarImagem(pngBytes, nomeArquivo: 'blank.png');

      print('\n======================================================');
      print('[TESTE IMAGEM 5 - Imagem Ilegível]');
      print('Status: ${res.status}');
      print('Explicação: ${res.explicacao}');
      print('======================================================');

      expect(res.status, ResultadoAnalise.naoFoiPossivelAnalisar);
    });

    test('6. Imagem Vazia (0 bytes)', () async {
      final res = await GolpeAnalyzerService.analisarImagem(Uint8List(0), nomeArquivo: 'vazio.png');
      expect(res.status, ResultadoAnalise.naoFoiPossivelAnalisar);
    });

    test('7. Imagem Acima do Limite de Tamanho (> 12MB)', () async {
      // Simula buffer de 13MB
      final largeBytes = Uint8List(13 * 1024 * 1024);
      final res = await GolpeAnalyzerService.analisarImagem(largeBytes, nomeArquivo: 'grande.jpg');
      expect(res.status, ResultadoAnalise.naoFoiPossivelAnalisar);
      expect(res.explicacao, contains('12MB'));
    });
  });
}
