import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serviço centralizado para envio direto de SMS de emergência
/// sem abrir nenhum app e sem exigir que o idoso aperte em enviar.
class EmergencySmsService {
  EmergencySmsService._();
  static final EmergencySmsService instance = EmergencySmsService._();

  static const _channel = MethodChannel('com.protegerplus/emergency');

  /// Verifica se a permissão de SEND_SMS foi concedida pelo usuário
  Future<bool> hasPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('hasSmsPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('[EmergencySmsService] Erro ao verificar permissão SMS: $e');
      return false;
    }
  }

  /// Solicita ao usuário a permissão de envio direto de SMS em runtime
  Future<bool> requestPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('requestSmsPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('[EmergencySmsService] Erro ao solicitar permissão SMS: $e');
      return false;
    }
  }

  /// Envia SMS silenciosamente e diretamente para o número informado via SmsManager
  Future<bool> sendDirectSms({
    required String rawPhone,
    required String message,
  }) async {
    if (rawPhone.trim().isEmpty) {
      debugPrint('[EmergencySmsService] Telefone vazio, SMS não enviado.');
      return false;
    }

    if (kIsWeb || !Platform.isAndroid) {
      debugPrint('[EmergencySmsService] Envio direto de SMS suportado apenas no Android.');
      return false;
    }

    // Normaliza número (remove não-dígitos)
    String numero = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (numero.startsWith('55') && numero.length > 11) {
      numero = numero.substring(2);
    }

    if (numero.isEmpty) return false;

    // Se ainda não tiver permissão, tenta solicitar
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      debugPrint('[EmergencySmsService] Permissão não concedida, solicitando...');
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('[EmergencySmsService] Permissão SEND_SMS negada pelo usuário.');
        return false;
      }
    }

    try {
      final result = await _channel.invokeMethod<String>('sendSmsDirectly', {
        'number': numero,
        'message': message,
      });
      debugPrint('[EmergencySmsService] Resultado envio SMS direto: $result');
      return result == 'SMS_SENT';
    } catch (e) {
      debugPrint('[EmergencySmsService] Falha ao enviar SMS diretamente: $e');
      return false;
    }
  }
}
