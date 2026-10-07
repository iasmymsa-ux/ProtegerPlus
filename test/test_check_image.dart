import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyBOBERSnd_4L4X_VCyvySZ2MdlfU4QnQ5w';
  const model = 'gemini-3.5-flash-lite';
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

  print('Testando envio de imagem com texto de golpe...');
  
  // Prompt para a IA
  final prompt = '''
Você é um especialista em segurança digital focado em proteger idosos de golpes online no Brasil.
Analise com extrema atenção esta imagem (print de WhatsApp, SMS, rede social, fatura ou tela de celular) e avalie se há risco de golpe.

Procure por sinais de golpes:
1. Pedidos urgentes de dinheiro ou Pix (ex: "troquei de número", falso filho/parente pedindo ajuda).
2. Pedidos de senhas, códigos de confirmação recebidos por SMS ou fotos de cartões de banco.
3. Falsas mensagens de bancos alegando bloqueio de conta, tentativa de compra suspeita ou pedido para ligar para 0800 falso.
4. Falsas mensagens de órgãos públicos (INSS, Gov.br, Correios).
5. Promessas de dinheiro fácil, empréstimo liberado sem consulta, sorteios ou prêmios.
6. Links ou chaves Pix suspeitas exibidas na imagem.
7. Tom de urgência ou ameaça.

ATENÇÃO:
Se a imagem for ilegível, totalmente escura ou não contiver texto, responda STATUS: INCONCLUSIVO.

Responda OBRIGATORIAMENTE no seguinte formato estruturado (sem markdown, sem asteriscos):
STATUS: [SEGURO / SUSPEITO / GOLPE / INCONCLUSIVO]
EXPLICACAO: [Explique em 1 a 2 frases simples e claras para um idoso]
ALERTAS: [Liste de 1 a 3 motivos curtos observados, ou 'Nenhum']
''';

  // Test with 1x1 png first to ensure endpoint is live
  const tinyPng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

  final res = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/png',
                'data': tinyPng,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 400,
      }
    }),
  );

  print('Status: ${res.statusCode}');
  print('Resposta:\n${res.body}');
}
