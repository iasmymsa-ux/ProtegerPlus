import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Serviço que monitora o acelerômetro e detecta queda do celular.
/// Quando detectada, envia mensagem via WhatsApp para o cuidador.
class PhoneDropService {
  PhoneDropService._();
  static final PhoneDropService instance = PhoneDropService._();

  // ── Configurações de sensibilidade ────────────────────────────────────────
  // Queda livre: magnitude do vetor de aceleração < freeFallThreshold m/s²
  static const double freeFallThreshold = 3.0;
  // Impacto: magnitude > impactThreshold m/s² após queda livre
  static const double impactThreshold = 25.0;
  // Janela de tempo (ms) entre queda livre e impacto para considerar como queda
  static const int impactWindowMs = 1500;
  // Cooldown (ms) entre alertas consecutivos para evitar spam
  static const int alertCooldownMs = 30000;

  // ── Estado interno ────────────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _subscription;
  bool _freeFallDetected = false;
  DateTime? _freeFallTime;
  DateTime? _lastAlertTime;
  bool _isRunning = false;

  // Callback chamado quando queda é confirmada (para atualizar a UI)
  VoidCallback? onDropDetected;

  // ── SharedPreferences key ─────────────────────────────────────────────────
  static const String _keyPhone = 'cuidador_whatsapp';
  static const String _keyEnabled = 'phone_drop_enabled';

  // ── Controle de estado ────────────────────────────────────────────────────
  bool get isRunning => _isRunning;

  /// Inicia o monitoramento do acelerômetro.
  Future<void> start() async {
    if (_isRunning) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? true;
    if (!enabled) return;

    _isRunning = true;
    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(_onAccelerometerEvent);
  }

  /// Para o monitoramento.
  Future<void> stop() async {
    _isRunning = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Alterna entre ligar/desligar e persiste a preferência.
  Future<bool> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isRunning) {
      await stop();
      await prefs.setBool(_keyEnabled, false);
      return false;
    } else {
      await prefs.setBool(_keyEnabled, true);
      await start();
      return true;
    }
  }

  /// Salva o número do WhatsApp do cuidador (apenas dígitos).
  Future<void> saveCuidadorPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    // Remove tudo que não é dígito
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    await prefs.setString(_keyPhone, digits);
  }

  /// Retorna o número salvo do cuidador (ou string vazia).
  Future<String> getCuidadorPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone) ?? '';
  }

  /// Verifica se a detecção de queda está habilitada.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? true;
  }

  // ── Lógica principal ──────────────────────────────────────────────────────
  void _onAccelerometerEvent(AccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final now = DateTime.now();

    // 1) Detecta queda livre (magnitude muito baixa → celular em queda)
    if (magnitude < freeFallThreshold && !_freeFallDetected) {
      _freeFallDetected = true;
      _freeFallTime = now;
      return;
    }

    // 2) Detecta impacto após queda livre dentro da janela de tempo
    if (_freeFallDetected && magnitude > impactThreshold) {
      final elapsed = now.difference(_freeFallTime!).inMilliseconds;

      if (elapsed <= impactWindowMs) {
        // Verifica cooldown para não disparar várias vezes seguidas
        if (_lastAlertTime == null ||
            now.difference(_lastAlertTime!).inMilliseconds > alertCooldownMs) {
          _lastAlertTime = now;
          _triggerDropAlert();
        }
      }

      _freeFallDetected = false;
      _freeFallTime = null;
    }

    // Reset se demorou muito para o impacto
    if (_freeFallDetected &&
        _freeFallTime != null &&
        now.difference(_freeFallTime!).inMilliseconds > impactWindowMs) {
      _freeFallDetected = false;
      _freeFallTime = null;
    }
  }

  void _triggerDropAlert() async {
    // Notifica a UI (ex.: exibir diálogo)
    onDropDetected?.call();
    // Envia WhatsApp para o cuidador
    await _sendWhatsAppAlert();
  }

  /// Abre o WhatsApp com uma mensagem de alerta para o cuidador.
  Future<void> _sendWhatsAppAlert() async {
    final phone = await getCuidadorPhone();
    if (phone.isEmpty) return;

    // Garante código do país (Brasil = 55)
    final fullPhone = phone.startsWith('55') ? phone : '55$phone';

    final mensagem = Uri.encodeComponent(
      '⚠️ ALERTA PROTEGER+\n\n'
      'O celular do usuário foi detectado caindo no chão!\n\n'
      'Por favor, verifique se está tudo bem. 🙏',
    );

    final uri = Uri.parse('https://wa.me/$fullPhone?text=$mensagem');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Envia um alerta manual (botão de teste ou emergência).
  Future<void> sendManualAlert() async {
    await _sendWhatsAppAlert();
  }
}
