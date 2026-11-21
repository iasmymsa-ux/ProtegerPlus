import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'emergency_sms_service.dart';
import 'background_protection_service.dart';
import 'alert_sync_service.dart';
import 'user_session_service.dart';
import '../models/user_profile.dart';

/// Serviço que escuta continuamente o microfone em busca de palavras-chave
/// de emergência. Quando detectadas, envia alerta direto via SMS ao cuidador
/// e acorda a tela.
class VoiceAlertService {
  VoiceAlertService._();
  static final VoiceAlertService instance = VoiceAlertService._();

  // ── Palavras-chave padrão de emergência ───────────────────────────────────
  static const List<String> defaultKeywords = [
    'socorro',
    'socorre',
    'socorram',
    'socorra',
    'me socorre',
    'me socorra',
    'ajuda',
    'ajude',
    'ajudem',
    'me ajuda',
    'me ajude',
    'me ajudem',
    'preciso de ajuda',
    'preciso de socorro',
    'emergencia',
    'acode',
    'me acode',
    'acudam',
    'chama o medico',
    'chama medico',
    'cai',
    'caiu',
    'caindo',
    'estou caindo',
    'estou no chao',
    'estou passando mal',
    'passando mal',
    'nao consigo',
    'dor',
    'doendo',
    'muita dor',
    'acidente',
    'fogo',
    'chama a ambulancia',
    'ambulancia',
    'chama o samu',
    'samu',
    'salva',
    'salve',
    'salvem',
    'machuquei',
    'falta de ar',
    'engasguei',
    'desmaiei',
    'infarto',
  ];

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String _keyEnabled = 'voice_alert_enabled';
  static const String _keyKeywords = 'voice_alert_keywords';
  static const String _keyCuidadorPhone = 'cuidador_whatsapp';
  static const int alertCooldownMs = 30000;

  // ── Estado interno ────────────────────────────────────────────────────────
  final SpeechToText _speech = SpeechToText();
  bool _isRunning = false;
  bool _speechAvailable = false;
  DateTime? _lastAlertTime;
  String _lastDetectedKeyword = '';
  String _lastHeardText = '';
  Timer? _restartTimer;
  int _errorCount = 0;

  /// Callback chamado na UI com a palavra detectada.
  void Function(String keyword)? onKeywordDetected;

  /// Callback chamado na UI em tempo real com o texto ouvido (para diagnóstico visual)
  void Function(String text)? onSpeechHeard;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isRunning => _isRunning;
  String get lastDetectedKeyword => _lastDetectedKeyword;
  String get lastHeardText => _lastHeardText;

  // ── Normalização inteligente de texto ─────────────────────────────────────
  static String _normalize(String text) {
    const withAccents    = 'àáâãäåèéêëìíîïòóôõöùúûüçñ';
    const withoutAccents = 'aaaaaaeeeeiiiioooooouuuucn';
    var result = text.toLowerCase().trim();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }

    // Remove pontuação
    result = result.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Reduz repetições exageradas de letras (ex: "socoooorrro" -> "socorro", "ajuuuuda" -> "ajuda")
    result = result.replaceAllMapped(
      RegExp(r'(.)\1{2,}'),
      (m) => '${m[1]}${m[1]}',
    );

    // Substituições fonéticas e correções frequentes de transcrição em pt-BR
    result = result
        .replaceAll('so corro', 'socorro')
        .replaceAll('sou corro', 'socorro')
        .replaceAll('sol corro', 'socorro')
        .replaceAll('seu corro', 'socorro')
        .replaceAll('se eu corro', 'socorro')
        .replaceAll('se ocorro', 'socorro')
        .replaceAll('se o corro', 'socorro')
        .replaceAll('se o coro', 'socorro')
        .replaceAll('socorrendo', 'socorro')
        .replaceAll('mi ajuda', 'me ajuda')
        .replaceAll('mim ajuda', 'me ajuda')
        .replaceAll('ambulansia', 'ambulancia');

    // Normaliza espaços múltiplos
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  // ── Similaridade fonética / Levenshtein ────────────────────────────────────
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = math.min(v1[j] + 1, math.min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  static double _similarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    final maxLen = math.max(s1.length, s2.length);
    if (maxLen == 0) return 1.0;
    final dist = _levenshtein(s1, s2);
    return 1.0 - (dist / maxLen);
  }

  /// Verifica se o texto reconhecido corresponde à palavra-chave em qualquer posição da frase
  static bool _matchesKeyword(String recognized, String keyword) {
    final normKeyword = _normalize(keyword);
    final normRecognized = _normalize(recognized);
    if (normKeyword.isEmpty || normRecognized.isEmpty) return false;

    // 1. Se a frase inteira contiver a palavra ou expressão em qualquer lugar
    // (ex: "alô socorro por favor me ajuda", "estou caído no chão socorro")
    if (normRecognized.contains(normKeyword)) return true;

    final words = normRecognized.split(' ').where((w) => w.isNotEmpty).toList();

    // 2. Se a palavra-chave contém mais de um termo (ex: "me ajuda", "dor no peito")
    final keyTerms = normKeyword.split(' ').where((w) => w.isNotEmpty).toList();
    if (keyTerms.length > 1) {
      bool allFound = true;
      for (final kt in keyTerms) {
        if (!normRecognized.contains(kt) &&
            !words.any((w) => w.startsWith(kt.substring(0, math.min(kt.length, 4))))) {
          allFound = false;
          break;
        }
      }
      if (allFound) return true;
    }

    // 3. Radical/prefixo de emergência em qualquer posição da frase
    // Garante que mesmo conjugações ("socorram", "socorre", "ajudem", "desmaiei")
    // no meio de qualquer frase sejam capturadas!
    for (final word in words) {
      if (word == normKeyword) return true;

      if (normKeyword == 'socorro' && (word.startsWith('socorr') || word.startsWith('socor'))) {
        return true;
      }
      if ((normKeyword == 'ajuda' || normKeyword == 'me ajuda') &&
          (word.startsWith('ajud') || word.startsWith('ajude'))) {
        return true;
      }
      if (normKeyword == 'emergencia' && word.startsWith('emergenc')) {
        return true;
      }
      if (normKeyword == 'ambulancia' && word.startsWith('ambulanc')) {
        return true;
      }
      if (normKeyword == 'machuquei' && word.startsWith('machuc')) {
        return true;
      }
      if (normKeyword == 'acode' && (word.startsWith('acod') || word.startsWith('acud'))) {
        return true;
      }
      if (normKeyword == 'cai' && (word == 'cai' || word.startsWith('caid') || word.startsWith('cair'))) {
        return true;
      }
      if (normKeyword == 'desmaio' && word.startsWith('desmai')) {
        return true;
      }
      if (normKeyword == 'infarto' && word.startsWith('infart')) {
        return true;
      }

      // Radical dinâmico para palavras customizadas cadastradas pelo cuidador
      if (normKeyword.length >= 4 && word.length >= 4) {
        final stem = normKeyword.substring(0, math.min(normKeyword.length, 5));
        if (word.startsWith(stem)) return true;
        if (_similarity(word, normKeyword) >= 0.70) {
          return true;
        }
      }
    }

    return false;
  }

  // ── Inicialização ─────────────────────────────────────────────────────────

  /// Inicializa o reconhecimento e começa a escutar SOMENTE se o perfil for Idoso.
  Future<bool> start() async {
    final session = UserSessionService.instance;
    // Bloqueia execução se não for perfil Idoso
    if (!session.isAuthenticated || session.currentUser.role != UserRole.idoso) {
      debugPrint('[VoiceAlertService] Serviço exclusivo para perfil Idoso. Parando microfone.');
      await stop();
      return false;
    }

    if (_isRunning) return true;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? true;
    if (!enabled) return false;

    _speechAvailable = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) => _onSpeechError(error.errorMsg),
      debugLogging: false,
    );

    if (!_speechAvailable) {
      debugPrint('[VoiceAlertService] SpeechToText não disponível.');
      return false;
    }

    _isRunning = true;
    _errorCount = 0;

    // Sincroniza palavras-chave configuradas pelo cuidador no MySQL
    try {
      AlertSyncService.instance.obterPalavrasAlerta().then((remoteWords) async {
        if (remoteWords.isNotEmpty) {
          final current = await getKeywords();
          final merged = <String>{...current, ...remoteWords}.toList();
          await saveKeywords(merged);
          debugPrint('[VoiceAlertService] ${remoteWords.length} palavras sincronizadas do cuidador.');
        }
      });
    } catch (_) {}

    await _startListening();
    return true;
  }

  /// Para o monitoramento de voz.
  Future<void> stop() async {
    _isRunning = false;
    _restartTimer?.cancel();
    _restartTimer = null;
    await _speech.stop();
  }

  /// Alterna ligado/desligado e persiste preferência SOMENTE para perfil Idoso.
  Future<bool> toggle() async {
    final session = UserSessionService.instance;
    if (!session.isAuthenticated || session.currentUser.role != UserRole.idoso) {
      await stop();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    if (_isRunning) {
      await stop();
      await prefs.setBool(_keyEnabled, false);
      return false;
    } else {
      await prefs.setBool(_keyEnabled, true);
      final ok = await start();
      return ok;
    }
  }

  /// Verifica se está habilitado nas preferências.
  Future<bool> isEnabled() async {
    final session = UserSessionService.instance;
    if (!session.isAuthenticated || session.currentUser.role != UserRole.idoso) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? true;
  }

  // ── Palavras-chave ────────────────────────────────────────────────────────

  /// Retorna as palavras-chave configuradas (ou as padrão).
  Future<List<String>> getKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_keyKeywords);
    return saved ?? List.from(defaultKeywords);
  }

  /// Salva a lista de palavras-chave personalizadas.
  Future<void> saveKeywords(List<String> keywords) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyKeywords,
      keywords.map((k) => _normalize(k)).toList(),
    );
  }

  // ── Lógica de escuta ──────────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (!_isRunning || !_speechAvailable) return;

    try {
      if (_speech.isListening) {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _speech.listen(
        onResult: _onSpeechResult,
        localeId: 'pt_BR',
        listenFor: const Duration(minutes: 30),
        pauseFor: const Duration(seconds: 15),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
      );
      _errorCount = 0;
      debugPrint('[VoiceAlertService] Escutando ativamente (pt_BR)...');
    } catch (e) {
      debugPrint('[VoiceAlertService] Erro ao iniciar escuta: $e');
      _scheduleRestart(delayMs: 1500);
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('[VoiceAlertService] Status: $status');
    if ((status == 'done' || status == 'notListening') && _isRunning) {
      // Reinicia rapidamente (250ms) para manter o microfone sempre escutando
      _scheduleRestart(delayMs: 250);
    }
  }

  void _onSpeechError(String error) {
    debugPrint('[VoiceAlertService] Erro: $error');
    if (!_isRunning) return;

    // Timeouts e ausência de fala são normais em escuta contínua: reinicia rapidamente sem penalidade!
    if (error == 'error_no_match' || error == 'error_speech_timeout') {
      _scheduleRestart(delayMs: 250);
      return;
    }

    // Microfone ocupado ou reconectando cliente
    if (error == 'error_client' || error == 'error_busy') {
      _scheduleRestart(delayMs: 600);
      return;
    }

    _errorCount++;
    final delayMs = _errorCount < 5 ? 1500 : 4000;
    _scheduleRestart(delayMs: delayMs);
  }

  void _scheduleRestart({int delayMs = 250}) {
    _restartTimer?.cancel();
    _restartTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_isRunning) _startListening();
    });
  }

  Future<void> _onSpeechResult(dynamic result) async {
    final raw = result.recognizedWords as String? ?? '';
    if (raw.isEmpty) return;

    _lastHeardText = raw;
    onSpeechHeard?.call(raw);

    final textsToCheck = <String>[raw];
    try {
      if (result.alternates != null && result.alternates is Iterable) {
        for (final alt in result.alternates) {
          final altWords = alt.recognizedWords?.toString() ?? '';
          if (altWords.isNotEmpty && !textsToCheck.contains(altWords)) {
            textsToCheck.add(altWords);
          }
        }
      }
    } catch (_) {}

    final keywords = await getKeywords();

    for (final candidate in textsToCheck) {
      final recognized = _normalize(candidate);
      debugPrint('[VoiceAlertService] Reconhecido: "$recognized" (Original: "$candidate")');

      for (final keyword in keywords) {
        if (_matchesKeyword(recognized, keyword)) {
          final now = DateTime.now();
          if (_lastAlertTime == null ||
              now.difference(_lastAlertTime!).inMilliseconds > alertCooldownMs) {
            _lastAlertTime = now;
            _lastDetectedKeyword = keyword;
            debugPrint('[VoiceAlertService] PALAVRA DE EMERGÊNCIA DETECTADA: "$keyword"');
            await _triggerAlert(keyword, candidate);
          }
          return;
        }
      }
    }
  }

  Future<void> _triggerAlert(String keyword, String fullPhrase) async {
    final session = UserSessionService.instance;
    if (!session.isAuthenticated || session.currentUser.role != UserRole.idoso) {
      return;
    }

    // Acorda a tela caso o celular esteja com tela desligada/bloqueada
    await BackgroundProtectionService.instance.wakeUpScreen();

    onKeywordDetected?.call(keyword);

    // Registra alerta no servidor MySQL em tempo real para o painel do cuidador
    AlertSyncService.instance.registrarAlerta(
      tipo: 'voz',
      detalhes: 'Alerta por voz ativado! Palavra: "$keyword". Frase dita: "$fullPhrase"',
      palavraChave: keyword,
      fraseDetectada: fullPhrase,
    );

    await _sendAlert(keyword, fullPhrase);
  }

  Future<void> _sendAlert(String keyword, String fullPhrase) async {
    final prefs = await SharedPreferences.getInstance();
    var phone = prefs.getString(_keyCuidadorPhone) ?? '';
    if (phone.isEmpty) {
      final session = UserSessionService.instance;
      phone = session.partnerUser?.phone ?? session.currentUser.caregiverPhone ?? '';
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      debugPrint('[VoiceAlertService] Cuidador não configurado para SMS. Alerta registrado no painel.');
      return;
    }

    final mensagemSms =
        'ALERTA DE VOZ - PROTEGER+: O usuário disse "$fullPhrase" (Palavra de socorro: "$keyword"). Verifique a situação imediatamente!';

    // Envio direto de SMS nativo sem abrir app e sem exigir clique do idoso
    await EmergencySmsService.instance.sendDirectSms(
      rawPhone: digits,
      message: mensagemSms,
    );
  }

  /// Envia alerta manual para teste diretamente por SMS.
  Future<bool> sendTestAlert() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_keyCuidadorPhone) ?? '';
    if (phone.isEmpty) return false;

    return await EmergencySmsService.instance.sendDirectSms(
      rawPhone: phone,
      message: 'PROTEGER+ (TESTE): Alerta de voz de teste enviado diretamente por SMS.',
    );
  }
}
