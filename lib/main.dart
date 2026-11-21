import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'views/initial_view.dart';
import 'app_theme_manager.dart';
import 'services/reminder_service.dart';
import 'services/background_protection_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/api_config.dart';
import 'services/mysql_chat_repository.dart';
import 'services/chat_service.dart';
import 'services/chat_notification_service.dart';
import 'services/user_session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Calibra o fuso horário com o timezone real do aparelho
  tz.initializeTimeZones();
  try {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
  } catch (e) {
    debugPrint('Aviso: Não foi possível obter o fuso horário local: $e');
  }

  try {
    // Conecta à API do Apache MySQL e inicializa a sessão do usuário
    await ApiConfig.instance.init();
    await UserSessionService.instance.init();
    ChatService.instance.setRepository(MySqlChatRepository());
  } catch (e) {
    debugPrint('Aviso ao inicializar UserSession/API: $e');
  }

  try {
    // Inicializa o serviço de alarmes e lembretes com a sessão de usuário já carregada
    await ReminderService().initNotifications();
  } catch (e) {
    debugPrint('Aviso ao inicializar ReminderService: $e');
  }

  try {
    await ChatNotificationService.instance.init();
  } catch (e) {
    debugPrint('Aviso ao inicializar ChatNotificationService: $e');
  }

  // Inicia serviços em segundo plano com tratamento de exceção seguro
  try {
    await BackgroundProtectionService.instance.init();
    await BackgroundProtectionService.instance.start();
  } catch (e) {
    debugPrint('Aviso ao iniciar BackgroundProtectionService: $e');
  }

  try {
    // Sincroniza serviços de segurança estritamente para o perfil logado (somente Idoso)
    await UserSessionService.instance.syncRoleServices();
  } catch (e) {
    debugPrint('Aviso ao sincronizar serviços por perfil: $e');
  }

  runApp(const ProtegerPlusApp());
}

class ProtegerPlusApp extends StatelessWidget {
  const ProtegerPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: AnimatedBuilder(
      animation: AppThemeManager.instance,
      builder: 
      (context, child) {
        return MaterialApp(
          title: 'Proteger+',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
          ],
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  AppThemeManager.instance.fontScale,
                ),
              ),
              child: widget!,
            );
          },
          theme: ThemeData(
            
            scaffoldBackgroundColor: AppThemeManager.instance.backgroundColor,
            primaryColor: AppThemeManager.instance.primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppThemeManager.instance.primaryColor,
              primary: AppThemeManager.instance.primaryColor,
              secondary: AppThemeManager.instance.secondaryColor,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeManager.instance.primaryColor,
                foregroundColor: AppThemeManager.instance.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 32.0,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          home: const InitialView(),
        );
      },
    ),
  );
}
}
