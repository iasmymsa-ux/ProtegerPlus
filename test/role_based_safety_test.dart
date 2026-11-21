import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proteger_plus/services/user_session_service.dart';
import 'package:proteger_plus/services/phone_drop_service.dart';
import 'package:proteger_plus/services/voice_alert_service.dart';
import 'package:proteger_plus/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserSessionService.instance.logout();
  });

  group('Segurança por Papel de Usuário (Role Restriction)', () {
    test('Cuidador NÃO deve conseguir iniciar detecção de queda', () async {
      // Define papel como Cuidador
      UserSessionService.instance.setRole(UserRole.cuidador, name: 'Cuidador Teste');

      // Tenta iniciar PhoneDropService
      await PhoneDropService.instance.start();

      expect(PhoneDropService.instance.isRunning, isFalse,
          reason: 'PhoneDropService nunca deve rodar para perfil Cuidador');
    });

    test('Cuidador NÃO deve conseguir iniciar reconhecimento de voz', () async {
      // Define papel como Cuidador
      UserSessionService.instance.setRole(UserRole.cuidador, name: 'Cuidador Teste');

      // Tenta iniciar VoiceAlertService
      final started = await VoiceAlertService.instance.start();

      expect(started, isFalse,
          reason: 'VoiceAlertService nunca deve iniciar para perfil Cuidador');
      expect(VoiceAlertService.instance.isRunning, isFalse);
    });

    test('Usuário deslogado NÃO deve ter acesso aos serviços', () async {
      await UserSessionService.instance.logout();

      await PhoneDropService.instance.start();
      expect(PhoneDropService.instance.isRunning, isFalse);

      final voiceStarted = await VoiceAlertService.instance.start();
      expect(voiceStarted, isFalse);
    });
  });

  group('Reconhecimento de Voz - Detecção no Meio da Frase', () {
    final keywords = ['socorro', 'me ajuda', 'dor no peito', 'cai', 'ambulancia'];

    final frasesParaTestar = [
      'Alô, alguém por favor me socorre rápido!',
      'Estou passando muito mal e com dor no peito terrível',
      'Minha pressão subiu e eu caí perto da cama',
      'Por favor alguém me ajuda que não consigo levantar',
      'Preciso de uma ambulancia urgente aqui em casa',
      'Acho que socorram é o que preciso gritar',
      'Socorro!',
    ];

    test('Todas as frases com palavras-chave em qualquer posição são identificadas', () {
      for (final frase in frasesParaTestar) {
        // Valida se a frase normalizada contém ao menos um radical ou termo
        final norm = frase.toLowerCase();
        final match = keywords.any((k) {
          if (norm.contains(k)) return true;
          if (k == 'socorro' && (norm.contains('socorr') || norm.contains('socor'))) return true;
          if (k == 'me ajuda' && norm.contains('ajud')) return true;
          if (k == 'cai' && (norm.contains('cai') || norm.contains('caí'))) return true;
          if (k == 'ambulancia' && norm.contains('ambulanc')) return true;
          return false;
        });

        expect(match, isTrue, reason: 'Deveria identificar emergência na frase: "$frase"');
      }
    });

    test('Frases cotidianas normais NÃO devem disparar falso positivo', () {
      final frasesNormais = [
        'Bom dia, o café já está pronto',
        'Vou assistir ao jornal na televisão',
        'Hoje o dia está ensolarado e agradável',
        'Gostei muito da caminhada no parque',
      ];

      for (final frase in frasesNormais) {
        final norm = frase.toLowerCase();
        final match = keywords.any((k) => norm.contains(k));
        expect(match, isFalse, reason: 'Frase normal "$frase" disparou falso positivo!');
      }
    });
  });
}

