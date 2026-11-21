import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'emergency_sms_service.dart';
import 'alert_sync_service.dart';
import 'user_session_service.dart';
import '../models/user_profile.dart';

/// Serviço que monitora o acelerômetro e detecta queda do celular.
/// Quando detectada, envia alerta direto via SMS para o cuidador.
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

  /// Inicia o monitoramento do acelerômetro SOMENTE se o perfil logado for Idoso.
  Future<void> start() async {
    final session = UserSessionService.instance;
    // Bloqueia execução para qualquer perfil que não seja Idoso
    if (!session.isAuthenticated || session.currentUser.role != UserRole.idoso) {
      await stop();
      return;
    }

    if (_isRunning) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? true;
    if (!enabled) return;

    _isRunning = true;
    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(_onAccelerometerEvent);
    debugPrint('[PhoneDropService] Monitoramento de queda ATIVADO para perfil Idoso.');
  }

  /// Para o monitoramento.
  Future<void> stop() async {
    _isRunning = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Alterna entre ligar/desligar e persiste a preferência.
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

  /// Retorna o número salvo do cuidador (ou telefone do cuidador vinculado na sessão).
  Future<String> getCuidadorPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyPhone) ?? '';
    if (saved.isNotEmpty) return saved;

    // Fallback inteligente para os dados do cuidador vinculado
    final session = UserSessionService.instance;
    final partnerPhone = session.partnerUser?.phone;
    if (partnerPhone != null && partnerPhone.isNotEmpty) {
      final clean = partnerPhone.replaceAll(RegExp(r'\D'), '');
      if (clean.isNotEmpty) return clean;
    }
    final caregiverPhone = session.currentUser.caregiverPhone;
    if (caregiverPhone != null && caregiverPhone.isNotEmpty) {
      final clean = caregiverPhone.replaceAll(RegExp(r'\D'), '');
      if (clean.isNotEmpty) return clean;
    }
    return '';
  }

  /// Verifica se a detecção de queda está habilitada.
  Future<bool> isEnabled() async {
    final session = UserSessionService.instance;
    if (!session.isAuthenticated || session.currentUser.role != UserRole.idoso) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? true;
  }

  // ── Lógica principal ──────────────────────────────────────────────────────
  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (UserSessionService.instance.currentUser.role != UserRole.idoso) {
      stop();
      return;
    }

    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final now = DateTime.now();

    // 0) Detecção de impacto brusco direto (ex: queda rápida sem fase longa de gravidade zero)
    if (magnitude > 32.0) {
      if (_lastAlertTime == null ||
          now.difference(_lastAlertTime!).inMilliseconds > alertCooldownMs) {
        _lastAlertTime = now;
        _triggerDropAlert();
      }
      _freeFallDetected = false;
      _freeFallTime = null;
      return;
    }

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
    final session = UserSessionService.instance;
    if (!session.isAuthenticated || session.currentUser.role != UserRole.idoso) {
      return;
    }

    // Notifica a UI (se o app estiver aberto em primeiro plano)
    onDropDetected?.call();

    final phone = await getCuidadorPhone();

    // 1. Registra alerta em tempo real no servidor para o painel do cuidador
    AlertSyncService.instance.registrarAlerta(
      tipo: 'queda',
      detalhes: 'Queda do celular detectada pelo acelerômetro em movimento brusco!',
      telefoneDestino: phone,
    );

    if (phone.isEmpty) return;

    // 2. Envio direto de SMS nativo (funciona com app aberto, em 2º plano ou tela bloqueada)
    // Sem abrir nenhum app e sem exigir que o idoso aperte em enviar!
    await EmergencySmsService.instance.sendDirectSms(
      rawPhone: phone,
      message: 'ALERTA DE QUEDA - PROTEGER+: O celular do usuário detectou uma queda no chão! Verifique a situação imediatamente.',
    );
  }

  /// Envia um alerta manual (botão de teste ou emergência).
  Future<void> sendManualAlert() async {
    _triggerDropAlert();
  }
}
