import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Resultado de uma ação individual da emergência.
class EmergencyActionResult {
  final String label;
  final bool success;
  final String detail;

  const EmergencyActionResult({
    required this.label,
    required this.success,
    required this.detail,
  });
}

/// Resultado completo do acionamento de emergência.
class EmergencyResult {
  final EmergencyActionResult samu;
  final EmergencyActionResult cuidador;

  const EmergencyResult({required this.samu, required this.cuidador});
}

/// Serviço de emergência real — sem confirmações, sem etapas intermediárias.
///
/// ▌ Android
///   • SAMU 192 → flutter_phone_direct_caller (CALL_PHONE) → ligação direta
///   • Cuidador → SmsManager nativo via MethodChannel → SMS automático
///
/// ▌ iOS  (limitação do sistema operacional Apple — não há exceções)
///   • SAMU 192 → abre discador com 192 preenchido
///   • Cuidador → abre app de SMS com mensagem pronta
///
/// As duas ações são disparadas em paralelo e são completamente independentes.
class EmergencyService {
  EmergencyService._();
  static final EmergencyService instance = EmergencyService._();

  // MethodChannel registrado em MainActivity.kt
  static const _channel = MethodChannel('com.protegerplus/emergency');

  // Mesma chave usada por PhoneDropService e VoiceAlertService
  static const String _keyCuidadorPhone = 'cuidador_whatsapp';

  static const String _samuNumber = '192';
  static const String _mensagemEmergencia =
      'ALERTA DE EMERGÊNCIA: o usuário acionou o botão de emergência do '
      'Proteger+. Verifique a situação imediatamente.';

  // ── Ponto de entrada ──────────────────────────────────────────────────────

  /// Dispara ligação para o SAMU e alerta ao cuidador em paralelo.
  Future<EmergencyResult> trigger() async {
    final results = await Future.wait([
      _acionarSamu(),
      _alertarCuidador(),
    ]);
    return EmergencyResult(samu: results[0], cuidador: results[1]);
  }

  // ── SAMU 192 ──────────────────────────────────────────────────────────────

  Future<EmergencyActionResult> _acionarSamu() async {
    if (Platform.isAndroid) {
      // flutter_phone_direct_caller usa TelecomManager com permissão CALL_PHONE
      // para iniciar a ligação sem interação do usuário.
      try {
        final called =
            await FlutterPhoneDirectCaller.callNumber(_samuNumber);
        if (called == true) {
          return const EmergencyActionResult(
            label: 'SAMU 192',
            success: true,
            detail: 'Ligação iniciada automaticamente para o SAMU 192.',
          );
        }
        // Plugin retornou false (ex: permissão negada pelo usuário)
        return await _abrirDiscador(
          motivo: 'A permissão de ligar foi negada. '
              'Discador aberto com 192 preenchido.',
        );
      } catch (e) {
        return await _abrirDiscador(
          motivo: 'Erro ao ligar diretamente: ${e.toString()}. '
              'Discador aberto com 192 preenchido.',
        );
      }
    } else {
      // iOS: Apple não permite que apps de terceiros façam ligações automáticas.
      return await _abrirDiscador(
        motivo: 'No iOS, o discador é aberto com 192 preenchido. '
            'Pressione a tecla verde para ligar.',
      );
    }
  }

  Future<EmergencyActionResult> _abrirDiscador({String motivo = ''}) async {
    final uri = Uri(scheme: 'tel', path: _samuNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return EmergencyActionResult(
          label: 'SAMU 192',
          success: true,
          detail: motivo.isNotEmpty
              ? motivo
              : 'Discador aberto com 192 preenchido.',
        );
      }
      return const EmergencyActionResult(
        label: 'SAMU 192',
        success: false,
        detail: 'Não foi possível abrir o discador neste dispositivo.',
      );
    } catch (e) {
      return EmergencyActionResult(
        label: 'SAMU 192',
        success: false,
        detail: 'Erro ao tentar acionar o SAMU: ${e.toString()}',
      );
    }
  }

  // ── CUIDADOR ───────────────────────────────────────────────────────────────

  Future<EmergencyActionResult> _alertarCuidador() async {
    final phone = await _getCuidadorPhone();

    if (phone.isEmpty) {
      return const EmergencyActionResult(
        label: 'Cuidador',
        success: false,
        detail: 'Nenhum número de cuidador cadastrado. '
            'Acesse "Detecção de Queda" e cadastre o número.',
      );
    }

    // Normaliza: remove código do país para SMS doméstico
    String numero = phone.replaceAll(RegExp(r'\D'), '');
    if (numero.startsWith('55') && numero.length > 11) {
      numero = numero.substring(2);
    }

    if (Platform.isAndroid) {
      // Tenta enviar SMS diretamente via SmsManager nativo (MethodChannel)
      try {
        final result = await _channel.invokeMethod<String>('sendSmsDirectly', {
          'number': numero,
          'message': _mensagemEmergencia,
        });

        if (result == 'SMS_SENT') {
          return EmergencyActionResult(
            label: 'Cuidador (SMS)',
            success: true,
            detail:
                'SMS de emergência enviado automaticamente para $numero.',
          );
        }
      } on PlatformException catch (e) {
        // Permissão negada em runtime → fallback para abrir app de SMS
        if (e.code == 'PERMISSION_DENIED') {
          return await _abrirAppSms(numero,
              prefixo: 'Permissão de SMS negada. ');
        }
        // Outro erro do SmsManager → fallback
        return await _abrirAppSms(numero,
            prefixo: 'Erro no SMS automático. ');
      } catch (_) {
        return await _abrirAppSms(numero,
            prefixo: 'Erro inesperado no SMS. ');
      }
    }

    // iOS: Apple não permite SMS automático
    return await _abrirAppSms(numero);
  }

  Future<EmergencyActionResult> _abrirAppSms(String numero,
      {String prefixo = ''}) async {
    try {
      final mensagemEncoded = Uri.encodeComponent(_mensagemEmergencia);
      final uri = Uri.parse('sms:$numero?body=$mensagemEncoded');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return EmergencyActionResult(
          label: 'Cuidador (SMS)',
          success: true,
          detail: '${prefixo}App de SMS aberto com mensagem de emergência '
              'para $numero. Pressione enviar.',
        );
      }
      // Fallback final: WhatsApp
      return await _abrirWhatsApp(numero, prefixo: prefixo);
    } catch (_) {
      return await _abrirWhatsApp(numero, prefixo: prefixo);
    }
  }

  Future<EmergencyActionResult> _abrirWhatsApp(String numero,
      {String prefixo = ''}) async {
    try {
      final fullPhone =
          numero.startsWith('55') ? numero : '55$numero';
      final mensagemEncoded = Uri.encodeComponent(_mensagemEmergencia);
      final uri =
          Uri.parse('https://wa.me/$fullPhone?text=$mensagemEncoded');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return EmergencyActionResult(
          label: 'Cuidador (WhatsApp)',
          success: true,
          detail:
              '${prefixo}WhatsApp aberto com mensagem de emergência.',
        );
      }

      return EmergencyActionResult(
        label: 'Cuidador',
        success: false,
        detail:
            'Não foi possível enviar alerta para $numero (SMS e WhatsApp indisponíveis).',
      );
    } catch (e) {
      return EmergencyActionResult(
        label: 'Cuidador',
        success: false,
        detail: 'Erro ao alertar cuidador: ${e.toString()}',
      );
    }
  }

  // ── Utilitário ─────────────────────────────────────────────────────────────

  Future<String> _getCuidadorPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCuidadorPhone) ?? '';
  }
}
