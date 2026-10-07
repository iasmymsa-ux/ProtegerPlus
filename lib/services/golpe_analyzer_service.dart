import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Resultado da análise da IA / Heurística
enum ResultadoAnalise {
  seguro,
  suspeito,
  naoSeguro,
  naoFoiPossivelAnalisar,
}

class ResultadoDetalhado {
  final ResultadoAnalise status;
  final String explicacao;
  final List<String> alertasEncontrados;

  ResultadoDetalhado({
    required this.status,
    required this.explicacao,
    this.alertasEncontrados = const [],
  });
}

class GolpeAnalyzerService {
  static const String _apiKey = 'AIzaSyBOBERSnd_4L4X_VCyvySZ2MdlfU4QnQ5w';
  static const String _model = 'gemini-3.5-flash-lite';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// Lista de encurtadores de URL conhecidos
  static const List<String> _encurtadoresConhecidos = [
    'bit.ly',
    'tinyurl.com',
    't.co',
    'is.gd',
    'cutt.ly',
    'shorturl.at',
    'rb.gy',
    'wa.me',
    'linktr.ee',
    'goo.gl',
    'ow.ly',
    'buff.ly',
    'rebrand.ly',
  ];

  /// TLDs frequentemente associados a domínios de baixo custo / phishing
  static const List<String> _tldsSuspeitos = [
    '.xyz',
    '.top',
    '.site',
    '.online',
    '.tk',
    '.ml',
    '.ga',
    '.cf',
    '.gq',
    '.club',
    '.work',
    '.vip',
    '.biz',
    '.download',
    '.racing',
    '.space',
    '.tech',
    '.store',
    '.icu',
    '.fun',
    '.loan',
  ];

  /// Palavras-chave de bancos e marcas brasileiras frequentemente falsificadas
  static const List<String> _marcasSensives = [
    'banco',
    'bradesco',
    'santander',
    'itau',
    'caixa',
    'nubank',
    'bb.com',
    'bancodobrasil',
    'correios',
    'gov.br',
    'serasa',
    'magalu',
    'mercadolivre',
    'bradescartao',
    'sicredi',
    'sicoob',
    'inter',
    'c6bank',
    'pagseguro',
    'inss',
  ];

  /// Domínios oficiais legítimos conhecidos
  static const List<String> _dominiosOficiais = [
    'bradesco.com.br',
    'santander.com.br',
    'itau.com.br',
    'caixa.gov.br',
    'bb.com.br',
    'nubank.com.br',
    'correios.com.br',
    'gov.br',
    'serasa.com.br',
    'magazineluiza.com.br',
    'mercadolivre.com.br',
    'google.com',
    'google.com.br',
    'youtube.com',
    'facebook.com',
    'instagram.com',
    'whatsapp.com',
    'globo.com',
    'uol.com.br',
  ];

  /// Valida se o texto inserido é uma URL com formato válido
  static String? validarEFormatarUrl(String entrada) {
    final textoLimpo = entrada.trim();
    if (textoLimpo.isEmpty) return null;

    String urlParaTestar = textoLimpo;
    if (!urlParaTestar.startsWith('http://') && !urlParaTestar.startsWith('https://')) {
      urlParaTestar = 'https://$urlParaTestar';
    }

    try {
      final uri = Uri.parse(urlParaTestar);
      if (uri.hasAuthority && uri.host.isNotEmpty && uri.host.contains('.')) {
        return urlParaTestar;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Realiza a análise heurística local da URL
  static ResultadoDetalhado analisarHeuristicaUrl(String rawUrl) {
    final formattedUrl = validarEFormatarUrl(rawUrl) ?? rawUrl;
    final Uri? uri = Uri.tryParse(formattedUrl);

    final List<String> alertas = [];
    bool isShortened = false;
    bool isIpHost = false;
    bool isSuspiciousTld = false;
    bool isImpersonatingBrand = false;
    bool isMissingHttps = false;
    bool isOfficialDomain = false;

    if (uri != null && uri.host.isNotEmpty) {
      final host = uri.host.toLowerCase();
      final scheme = uri.scheme.toLowerCase();

      // Check HTTPS
      if (scheme == 'http') {
        isMissingHttps = true;
        alertas.add('O site não utiliza conexão segura (HTTP em vez de HTTPS).');
      }

      // Check URL Shortener
      for (final shortener in _encurtadoresConhecidos) {
        if (host == shortener || host.endsWith('.$shortener')) {
          isShortened = true;
          alertas.add('Link encurtado ($host) que oculta o destino real da página.');
          break;
        }
      }

      // Check IP Hostname
      final ipRegExp = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      if (ipRegExp.hasMatch(host)) {
        isIpHost = true;
        alertas.add('O link utiliza um endereço numérico de IP diretamente.');
      }

      // Check Suspicious TLD
      for (final tld in _tldsSuspeitos) {
        if (host.endsWith(tld)) {
          isSuspiciousTld = true;
          alertas.add('Extensão de domínio incomum ($tld), comumente usada para fraudes.');
          break;
        }
      }

      // Check Official Domain Match
      for (final official in _dominiosOficiais) {
        if (host == official || host.endsWith('.$official')) {
          isOfficialDomain = true;
          break;
        }
      }

      // Check Brand Impersonation if not official
      if (!isOfficialDomain) {
        for (final marca in _marcasSensives) {
          if (host.contains(marca)) {
            isImpersonatingBrand = true;
            alertas.add('O endereço tenta imitar o nome de uma instituição ("$marca"), mas não é o site oficial.');
            break;
          }
        }
      }
    } else {
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoFoiPossivelAnalisar,
        explicacao: 'O link informado possui uma estrutura inválida. Verifique o endereço digitado.',
        alertasEncontrados: ['Endereço com formato inválido.'],
      );
    }

    if (isIpHost || (isImpersonatingBrand && isSuspiciousTld)) {
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoSeguro,
        explicacao: 'Risco alto de golpe detectado! Este endereço apresenta fortes indícios de fraude ou falsificação de página oficial.',
        alertasEncontrados: alertas,
      );
    } else if (isShortened || isImpersonatingBrand || isSuspiciousTld || isMissingHttps) {
      return ResultadoDetalhado(
        status: ResultadoAnalise.suspeito,
        explicacao: 'Sinais suspeitos encontrados neste endereço. Evite clicar ou informar senhas e dados confidenciais.',
        alertasEncontrados: alertas,
      );
    } else if (isOfficialDomain) {
      return ResultadoDetalhado(
        status: ResultadoAnalise.seguro,
        explicacao: 'Este link pertence a um domínio oficial e legítimo reconhecido.',
        alertasEncontrados: ['Canal oficial verificado.'],
      );
    } else {
      // Quando não há sinais na heurística, NÃO afirmamos segurança sem a IA
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoFoiPossivelAnalisar,
        explicacao: 'Análise heurística inconclusiva. É necessária a confirmação da inteligência artificial para verificar o link.',
        alertasEncontrados: ['Aguardando análise detalhada da IA.'],
      );
    }
  }

  /// Faz a chamada HTTP para a API Gemini
  static Future<http.Response> _postComRetry(String body, {int maxRetries = 2}) async {
    for (int tentativa = 0; tentativa < maxRetries; tentativa++) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 429 && tentativa < maxRetries - 1) {
          debugPrint('[GolpeAnalyzerService] Erro 429 (Muitas requisições). Aguardando retry...');
          await Future.delayed(Duration(seconds: (tentativa + 1) * 2));
          continue;
        }

        return response;
      } catch (e) {
        debugPrint('[GolpeAnalyzerService] Falha na tentativa $tentativa: $e');
        if (tentativa == maxRetries - 1) rethrow;
      }
    }
    return http.Response('{"error": "timeout"}', 500);
  }

  /// Analisa um link/URL para detectar golpes usando IA Gemini
  static Future<ResultadoDetalhado> analisarLink(String rawUrl) async {
    final urlLimpa = rawUrl.trim();
    if (urlLimpa.isEmpty) {
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoFoiPossivelAnalisar,
        explicacao: 'Por favor, digite ou cole um endereço de link para que possamos analisar.',
        alertasEncontrados: ['Nenhum link foi informado.'],
      );
    }

    final urlValidada = validarEFormatarUrl(urlLimpa);
    if (urlValidada == null) {
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoFoiPossivelAnalisar,
        explicacao: 'O link digitado não possui um formato válido (exemplo correto: site.com ou https://site.com).',
        alertasEncontrados: ['Formato de link inválido.'],
      );
    }

    // Heurística local prévia
    final analiseLocal = analisarHeuristicaUrl(urlValidada);

    // Se a chave não estiver configurada
    if (_apiKey.isEmpty || _apiKey == 'COLE_SUA_CHAVE_AQUI') {
      debugPrint('[GolpeAnalyzerService] Chave da API Gemini não configurada.');
      if (analiseLocal.status == ResultadoAnalise.naoSeguro ||
          analiseLocal.status == ResultadoAnalise.suspeito) {
        return analiseLocal;
      }
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoFoiPossivelAnalisar,
        explicacao: 'Não foi possível analisar o link online porque a chave do serviço de inteligência artificial não foi configurada.',
        alertasEncontrados: ['Serviço de IA não configurado.'],
      );
    }

    final prompt = '''
Você é um especialista em segurança digital focado em proteger idosos de golpes online no Brasil.
Analise a seguinte URL e determine com rigor se é segura, suspeita ou golpe:

URL para analisar: $urlValidada

Verifique cuidadosamente:
1. Domínio legítimo vs imitação de bancos (Itaú, Bradesco, Caixa, Banco do Brasil, Nubank, etc.), órgãos públicos (Gov.br, Receita, INSS, Correios) ou lojas conhecidas.
2. Uso de TLDs comumente associados a phishing (.xyz, .top, .site, .online, .tk, etc.).
3. Encurtadores de URL que escondem o destino real (bit.ly, tinyurl, etc.).
4. Termos no endereço como 'pix', 'resgate', 'bloqueio', 'seguro', 'atualizacao', 'indemnizacao'.
5. Uso de HTTP sem segurança.
6. Erros de digitação intencionais para enganar o usuário (typosquatting).

Responda OBRIGATORIAMENTE no seguinte formato estruturado (sem markdown, sem negrito, sem asteriscos):
STATUS: [SEGURO / SUSPEITO / GOLPE]
EXPLICACAO: [Explique em 1 a 2 frases simples, acolhedoras e diretas para um idoso]
ALERTAS: [Liste de 1 a 3 motivos curtos separados por vírgula, ou 'Nenhum' se seguro]
''';

    debugPrint('[GolpeAnalyzerService] Enviando link para IA Gemini: $urlValidada');

    try {
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 250,
        }
      });

      final response = await _postComRetry(body);
      debugPrint('[GolpeAnalyzerService] Resposta HTTP da IA: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final texto = json['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        debugPrint('[GolpeAnalyzerService] Texto da resposta da IA: $texto');

        if (texto.toString().trim().isEmpty) {
          debugPrint('[GolpeAnalyzerService] Resposta da IA veio vazia.');
          return _tratarFalhaOuHeuristica(analiseLocal, 'A resposta da inteligência artificial veio vazia.');
        }

        final resultadoIa = _parsearResposta(texto);

        // Se a heurística local detectou risco alto e a IA foi ingênua, priorizamos a segurança
        ResultadoAnalise statusFinal = resultadoIa.status;
        final alertasUnicos = <String>{
          ...resultadoIa.alertasEncontrados,
          ...analiseLocal.alertasEncontrados.where((a) => !a.contains('Aguardando')),
        }.toList();

        if (analiseLocal.status == ResultadoAnalise.naoSeguro) {
          statusFinal = ResultadoAnalise.naoSeguro;
        } else if (analiseLocal.status == ResultadoAnalise.suspeito && statusFinal == ResultadoAnalise.seguro) {
          statusFinal = ResultadoAnalise.suspeito;
        }

        return ResultadoDetalhado(
          status: statusFinal,
          explicacao: resultadoIa.explicacao,
          alertasEncontrados: alertasUnicos,
        );
      } else {
        debugPrint('[GolpeAnalyzerService] Erro na API Gemini: ${response.statusCode} - ${response.body}');
        return _tratarFalhaOuHeuristica(
          analiseLocal,
          'Serviço de análise temporariamente indisponível (código ${response.statusCode}).',
        );
      }
    } catch (e) {
      debugPrint('[GolpeAnalyzerService] Exceção ao chamar IA: $e');
      return _tratarFalhaOuHeuristica(
        analiseLocal,
        'Não foi possível conectar ao serviço de inteligência artificial. Verifique sua conexão com a internet.',
      );
    }
  }

  /// Trata falha de IA para links: se a heurística local já acusou perigo, avisa o perigo. Se não, NUNCA diz que é seguro.
  static ResultadoDetalhado _tratarFalhaOuHeuristica(ResultadoDetalhado local, String motivoFalha) {
    if (local.status == ResultadoAnalise.naoSeguro || local.status == ResultadoAnalise.suspeito) {
      return ResultadoDetalhado(
        status: local.status,
        explicacao: '${local.explicacao} (Aviso: A verificação online falhou, mas identificamos esses riscos localmente).',
        alertasEncontrados: local.alertasEncontrados,
      );
    }

    return ResultadoDetalhado(
      status: ResultadoAnalise.naoFoiPossivelAnalisar,
      explicacao: '$motivoFalha Por segurança, evite clicar neste link ou fornecer qualquer informação pessoal.',
      alertasEncontrados: ['Análise online não pôde ser concluída.'],
    );
  }

  /// Analisa uma imagem (print/screenshot) para detectar golpes usando IA Gemini Multimodal
  /// Analisa uma imagem (print/screenshot) para detectar golpes usando IA Gemini Multimodal.
  /// Suporta [Uint8List] (Web e memória), [File] (Mobile/Desktop) ou [XFile] (ImagePicker).
  static Future<ResultadoDetalhado> analisarImagem(
    dynamic imagem, {
    String? nomeArquivo,
    String? mimeType,
  }) async {
    Uint8List bytes;
    String nome = nomeArquivo ?? 'imagem.jpg';
    String? tipoMime = mimeType;

    if (imagem is Uint8List) {
      bytes = imagem;
    } else if (imagem is File) {
      if (!imagem.existsSync()) {
        return ResultadoDetalhado(
          status: ResultadoAnalise.naoFoiPossivelAnalisar,
          explicacao: 'O arquivo de imagem selecionado não foi encontrado no dispositivo.',
          alertasEncontrados: ['Arquivo inexistente.'],
        );
      }
      bytes = await imagem.readAsBytes();
      nome = imagem.path;
    } else if (imagem != null && imagem.runtimeType.toString() == 'XFile') {
      try {
        bytes = await (imagem as dynamic).readAsBytes();
        nome = (imagem as dynamic).name ?? 'imagem.jpg';
        tipoMime = (imagem as dynamic).mimeType;
      } catch (e) {
        return ResultadoDetalhado(
          status: ResultadoAnalise.naoFoiPossivelAnalisar,
          explicacao: 'Não foi possível carregar os dados da imagem selecionada.',
          alertasEncontrados: ['Erro ao ler imagem: $e'],
        );
      }
    } else {
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoFoiPossivelAnalisar,
        explicacao: 'Nenhuma imagem válida foi selecionada para análise.',
        alertasEncontrados: ['Imagem inválida ou não selecionada.'],
      );
    }

    final tamanhoBytes = bytes.length;
    if (tamanhoBytes == 0) {
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoFoiPossivelAnalisar,
        explicacao: 'A imagem selecionada está vazia ou corrompida. Por favor, escolha outra foto.',
        alertasEncontrados: ['Arquivo de imagem vazio.'],
      );
    }

    if (tamanhoBytes > 12 * 1024 * 1024) {
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoFoiPossivelAnalisar,
        explicacao: 'A imagem é muito grande (acima de 12MB). Por favor, tire uma captura de tela menor ou escolha outra foto.',
        alertasEncontrados: ['Tamanho de imagem excedido.'],
      );
    }

    if (_apiKey.isEmpty || _apiKey == 'COLE_SUA_CHAVE_AQUI') {
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoFoiPossivelAnalisar,
        explicacao: 'Não foi possível analisar a imagem porque a chave do serviço de inteligência artificial não foi configurada.',
        alertasEncontrados: ['Chave da IA não configurada.'],
      );
    }

    final prompt = '''
Você é um especialista em segurança digital focado em proteger idosos de golpes online no Brasil.
Analise com extrema atenção esta imagem (print de WhatsApp, SMS, rede social, recibo, fatura ou tela de celular) e avalie se há risco de golpe.

Procure por sinais clássicos de golpes:
1. Pedidos urgentes de dinheiro ou Pix (ex: "troquei de número", falso filho/parente pedindo ajuda).
2. Pedidos de senhas, códigos de confirmação recebidos por SMS ou fotos de cartões de banco.
3. Falsas mensagens de bancos alegando bloqueio de conta, tentativa de compra suspeita ou pedido para ligar para 0800 falso.
4. Falsas mensagens de órgãos públicos (INSS, Gov.br, Correios com taxa alfandegária falsa).
5. Promessas de dinheiro fácil, empréstimo liberado sem consulta, sorteios ou prêmios inesperados.
6. Links ou chaves Pix suspeitas exibidas na imagem.
7. Tom de urgência, desespero ou ameaça para fazer a vítima agir sem consultar ninguém.

ATENÇÃO CRÍTICA:
Se a imagem estiver totalmente preta/escura, cortada, ilegível, borrada ou não contiver nenhuma mensagem ou texto compreensível para avaliar, responda STATUS: INCONCLUSIVO e explique que a imagem não possui mensagem legível.

Responda OBRIGATORIAMENTE no seguinte formato estruturado (sem markdown, sem asteriscos):
STATUS: [SEGURO / SUSPEITO / GOLPE / INCONCLUSIVO]
EXPLICACAO: [Explique em 1 a 2 frases simples, acolhedoras e claras para um idoso]
ALERTAS: [Liste de 1 a 3 motivos curtos observados, ou 'Nenhum' se seguro ou inconclusivo]
''';

    debugPrint('[GolpeAnalyzerService] Preparando imagem para envio (${tamanhoBytes ~/ 1024} KB)...');

    try {
      final base64Image = base64Encode(bytes);
      final mimeFinal = tipoMime ?? _getMimeType(nome);

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': mimeFinal,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 300,
        }
      });

      debugPrint('[GolpeAnalyzerService] Enviando imagem para IA Gemini...');
      final response = await _postComRetry(body);
      debugPrint('[GolpeAnalyzerService] Resposta HTTP da imagem: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final texto = json['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        debugPrint('[GolpeAnalyzerService] Texto da resposta da imagem:\n$texto');

        if (texto.toString().trim().isEmpty) {
          return ResultadoDetalhado(
            status: ResultadoAnalise.naoFoiPossivelAnalisar,
            explicacao: 'A inteligência artificial não retornou resposta para esta imagem. Tente enviar novamente.',
            alertasEncontrados: ['Resposta da IA vazia.'],
          );
        }

        return _parsearResposta(texto);
      } else {
        debugPrint('[GolpeAnalyzerService] Erro na API para imagem: ${response.statusCode} - ${response.body}');
        return ResultadoDetalhado(
          status: ResultadoAnalise.naoFoiPossivelAnalisar,
          explicacao: 'Não foi possível analisar a imagem no momento (código ${response.statusCode}). Por favor, tente novamente.',
          alertasEncontrados: ['Indisponibilidade temporária do serviço de análise.'],
        );
      }
    } catch (e) {
      debugPrint('[GolpeAnalyzerService] Exceção ao analisar imagem: $e');
      return ResultadoDetalhado(
        status: ResultadoAnalise.naoFoiPossivelAnalisar,
        explicacao: 'Não foi possível analisar a imagem devido a uma falha de conexão. Verifique sua internet e tente novamente.',
        alertasEncontrados: ['Falha de conexão com a internet.'],
      );
    }
  }

  /// Converte o texto estruturado da resposta da IA para um objeto ResultadoDetalhado
  static ResultadoDetalhado _parsearResposta(String texto) {
    ResultadoAnalise status = ResultadoAnalise.naoFoiPossivelAnalisar;
    String explicacao = '';
    final List<String> alertas = [];

    final linhas = texto.split('\n');
    for (final linha in linhas) {
      final linhaLimpa = linha.trim();
      if (linhaLimpa.toUpperCase().startsWith('STATUS:')) {
        final valor = linhaLimpa.replaceFirst(RegExp(r'^STATUS:\s*', caseSensitive: false), '').trim().toUpperCase();
        if (valor.contains('GOLPE') || valor.contains('NAO_SEGURO') || valor.contains('NÃO_SEGURO')) {
          status = ResultadoAnalise.naoSeguro;
        } else if (valor.contains('SUSPEITO')) {
          status = ResultadoAnalise.suspeito;
        } else if (valor.contains('SEGURO')) {
          status = ResultadoAnalise.seguro;
        } else if (valor.contains('INCONCLUSIVO')) {
          status = ResultadoAnalise.naoFoiPossivelAnalisar;
        }
      } else if (linhaLimpa.toUpperCase().startsWith('EXPLICACAO:') || linhaLimpa.toUpperCase().startsWith('EXPLICAÇÃO:')) {
        explicacao = linhaLimpa.replaceFirst(RegExp(r'^EXPLICA[CÇ][AÃ]O:\s*', caseSensitive: false), '').trim();
      } else if (linhaLimpa.toUpperCase().startsWith('ALERTAS:')) {
        final rawAlertas = linhaLimpa.replaceFirst(RegExp(r'^ALERTAS:\s*', caseSensitive: false), '').trim();
        if (rawAlertas.isNotEmpty && !rawAlertas.toLowerCase().contains('nenhum')) {
          final itens = rawAlertas.split(RegExp(r'[,;]'));
          for (final item in itens) {
            final limpo = item.trim();
            if (limpo.isNotEmpty && !limpo.toLowerCase().contains('nenhum')) {
              alertas.add(limpo);
            }
          }
        }
      }
    }

    if (explicacao.isEmpty) {
      explicacao = texto.replaceAll(RegExp(r'STATUS:.*|ALERTAS:.*', caseSensitive: false), '').trim();
      if (explicacao.isEmpty) {
        if (status == ResultadoAnalise.seguro) {
          explicacao = 'Não foram identificados sinais de golpe neste conteúdo.';
        } else if (status == ResultadoAnalise.naoSeguro) {
          explicacao = 'Risco alto de golpe detectado! Recomendamos não interagir com esta mensagem.';
        } else if (status == ResultadoAnalise.suspeito) {
          explicacao = 'Foram encontrados elementos suspeitos. Mantenha cautela e não informe senhas.';
        } else {
          explicacao = 'Não foi possível chegar a uma conclusão segura sobre este conteúdo.';
        }
      }
    }

    return ResultadoDetalhado(
      status: status,
      explicacao: explicacao,
      alertasEncontrados: alertas,
    );
  }

  static String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
