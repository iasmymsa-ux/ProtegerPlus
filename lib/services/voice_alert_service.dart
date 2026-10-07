import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// Serviço que escuta continuamente o microfone em busca de palavras-chave
/// de emergência. Quando detectadas, envia alerta via WhatsApp para o cuidador.
class VoiceAlertService {
  VoiceAlertService._();
  static final VoiceAlertService instance = VoiceAlertService._();

  // ── Palavras-chave padrão de emergência ───────────────────────────────────
  static const List<String> defaultKeywords = [
    'socorro',
    'ajuda',
    'emergência',
    'emergencia',
    'chama o médico',
    'chama medico',
    'me ajuda',
    'me ajude',
    'caí',
    'cai',
    'estou passando mal',
    'passando mal',
    'não consigo',
    'nao consigo',
    'dor',
    'doendo',
    'acidente',
    'fogo',
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
  Timer? _restartTimer;

  /// Callback chamado na UI com a palavra detectada.
  void Function(String keyword)? onKeywordDetected;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isRunning => _isRunning;
  String get lastDetectedKeyword => _lastDetectedKeyword;

  // ── Inicialização ─────────────────────────────────────────────────────────

  /// Inicializa o reconhecimento e começa a escutar (se habilitado).
  Future<bool> start() async {
    if (_isRunning) return true;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? true;
    if (!enabled) return false;

    _speechAvailable = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) => _onSpeechError(error.errorMsg),
    );

    if (!_speechAvailable) return false;

    _isRunning = true;
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

  /// Alterna ligado/desligado e persiste preferência.
  Future<bool> toggle() async {
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
      keywords.map((k) => k.toLowerCase().trim()).toList(),
    );
  }

  // ── Lógica de escuta ──────────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (!_isRunning || !_speechAvailable) return;

    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: 'pt_BR',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenMode: ListenMode.confirmation,
      cancelOnError: false,
    );
  }

  void _onSpeechStatus(String status) {
    // Quando a sessão de escuta termina, reinicia automaticamente
    if (status == 'done' || status == 'notListening') {
      if (_isRunning) {
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(seconds: 2), _startListening);
      }
    }
  }

  void _onSpeechError(String error) {
    // Em caso de erro, tenta reiniciar após uma pausa
    if (_isRunning) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(seconds: 4), _startListening);
    }
  }

  Future<void> _onSpeechResult(result) async {
    final recognizedText = result.recognizedWords.toLowerCase().trim();
    if (recognizedText.isEmpty) return;

    final keywords = await getKeywords();

    for (final keyword in keywords) {
      if (recognizedText.contains(keyword.toLowerCase())) {
        final now = DateTime.now();

        // Cooldown para não disparar múltiplos alertas em sequência
        if (_lastAlertTime == null ||
            now.difference(_lastAlertTime!).inMilliseconds > alertCooldownMs) {
          _lastAlertTime = now;
          _lastDetectedKeyword = keyword;
          await _triggerAlert(keyword, recognizedText);
        }
        break;
      }
    }
  }

  Future<void> _triggerAlert(String keyword, String fullPhrase) async {
    // Notifica a UI
    onKeywordDetected?.call(keyword);
    // Envia WhatsApp
    await _sendWhatsAppAlert(keyword, fullPhrase);
  }

  Future<void> _sendWhatsAppAlert(String keyword, String fullPhrase) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_keyCuidadorPhone) ?? '';
    if (phone.isEmpty) return;

    final fullPhone = phone.startsWith('55') ? phone : '55$phone';

    final mensagem = Uri.encodeComponent(
      '🚨 ALERTA DE VOZ — PROTEGER+\n\n'
      'O usuário disse: "$fullPhrase"\n\n'
      'Palavra-chave detectada: "$keyword"\n\n'
      '⚠️ Por favor, verifique imediatamente se está tudo bem! 🙏',
    );

    final uri = Uri.parse('https://wa.me/$fullPhone?text=$mensagem');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Envia alerta manual para teste.
  Future<void> sendTestAlert() async {
    await _sendWhatsAppAlert('teste', 'Esse é um alerta de teste do Proteger+');
  }
}
