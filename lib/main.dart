import 'package:flutter/material.dart';
import 'views/initial_view.dart';
import 'app_theme_manager.dart';
import 'services/phone_drop_service.dart';
import 'services/voice_alert_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicia monitoramento de queda em segundo plano
  await PhoneDropService.instance.start();
  // Inicia monitoramento de voz em segundo plano
  await VoiceAlertService.instance.start();
  runApp(const ProtegerPlusApp());
}

class ProtegerPlusApp extends StatelessWidget {
  const ProtegerPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeManager.instance,
      builder: 
      (context, child) {
        return MaterialApp(
          title: 'Proteger+',
          debugShowCheckedModeBanner: false,
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
    );
  }
}
