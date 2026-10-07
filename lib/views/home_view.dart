import 'package:flutter/material.dart';
import 'lembretes_view.dart';
import 'jogos_view.dart';
import 'alerta_golpes_view.dart';
import 'cuidados_saude_view.dart';
import 'chat_view.dart';
import 'profile_view.dart';
import 'atendimento_psicologico_view.dart';
import 'phone_drop_view.dart';
import 'voice_alert_view.dart';
import '../app_theme_manager.dart';
import '../services/emergency_service.dart';

// HomeView agora é StatefulWidget para controlar o lock de emergência.
// O design é 100% preservado — apenas a lógica do botão foi substituída.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Protege contra múltiplos acionamentos simultâneos sem criar confirmação.
  // true = emergência em andamento, novos toques são ignorados silenciosamente.
  bool _emergencyFiring = false;

  Future<void> _handleEmergency() async {
    // Guard: ignora toques enquanto o fluxo está em andamento.
    if (_emergencyFiring) return;
    setState(() => _emergencyFiring = true);

    try {
      // Dispara SAMU + cuidador em paralelo — ações independentes.
      final result = await EmergencyService.instance.trigger();

      if (!mounted) return;

      // Exibe o resultado real de cada ação, sem inventar sucesso.
      _showEmergencyResult(result);
    } finally {
      // Libera o lock após 8 segundos para evitar travamento permanente.
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _emergencyFiring = false);
      });
    }
  }

  void _showEmergencyResult(EmergencyResult result) {
    final samuOk = result.samu.success;
    final cuidadorOk = result.cuidador.success;

    // Monta mensagem honesta baseada no que de fato aconteceu.
    final List<String> linhas = [];

    if (samuOk) {
      linhas.add('📞 ${result.samu.detail}');
    } else {
      linhas.add('❌ SAMU: ${result.samu.detail}');
    }

    if (cuidadorOk) {
      linhas.add('✅ ${result.cuidador.detail}');
    } else {
      linhas.add('❌ Cuidador: ${result.cuidador.detail}');
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: [
            Icon(
              (samuOk || cuidadorOk)
                  ? Icons.warning_amber_rounded
                  : Icons.error_outline,
              color: Colors.red,
              size: 30,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Emergência acionada',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: linhas
              .map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(l, style: const TextStyle(fontSize: 14, height: 1.4)),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header (Profile + Premium Badge) ── design preservado ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ProfileView(profile: 'Usuario'),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person,
                              size: 32,
                              color: AppThemeManager.instance.borderColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Perfil',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            size: 40,
                            color: Color(0xFFDAA520),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Perfil Premium',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppThemeManager.instance.borderColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // ── Botão de Emergência ── design 100% preservado ──────────
                // GestureDetector com onTap real — sem confirmação.
                GestureDetector(
                  onTap: _handleEmergency,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      // Pisca levemente enquanto emergência está em andamento.
                      color: _emergencyFiring
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFFF44336),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: -0.3,
                          child: const Icon(
                            Icons.phone_in_talk,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          top: 32,
                          right: 42,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CHAMADA DE EMERGÊNCIA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Grade de funcionalidades ── design preservado ──────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildFeatureButton(
                      icon: Icons.medical_services_outlined,
                      text: 'CUIDADOS COM A\nSAÚDE',
                      iconColor: AppThemeManager.instance.borderColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CuidadosSaudeView()),
                      ),
                    ),
                    _buildFeatureButton(
                      icon: Icons.forum_outlined,
                      text: 'CHAT DE\nCONVERSAS',
                      iconColor: AppThemeManager.instance.borderColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatView()),
                      ),
                    ),
                    _buildFeatureButton(
                      icon: Icons.event_note_outlined,
                      text: 'LEMBRETES',
                      iconColor: AppThemeManager.instance.borderColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LembretesView()),
                      ),
                    ),
                    _buildFeatureButton(
                      icon: Icons.warning_rounded,
                      text: 'ALERTA DE\nGOLPES',
                      iconColor: AppThemeManager.instance.borderColor,
                      iconSize: 64,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AlertaGolpesView()),
                      ),
                    ),
                    _buildFeatureButton(
                      icon: Icons.videogame_asset_outlined,
                      text: 'JOGOS',
                      iconColor: AppThemeManager.instance.borderColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JogosView()),
                      ),
                    ),
                    _buildFeatureButton(
                      icon: Icons.self_improvement_outlined,
                      text: 'ATENDIMENTO\nPSICOLÓGICO',
                      iconColor: AppThemeManager.instance.borderColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AtendimentoPsicologicoView()),
                      ),
                    ),
                    _buildFeatureButton(
                      icon: Icons.phone_android,
                      text: 'DETECÇÃO\nDE QUEDA',
                      iconColor: AppThemeManager.instance.borderColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PhoneDropView()),
                      ),
                    ),
                    _buildFeatureButton(
                      icon: Icons.mic,
                      text: 'ALERTA\nPOR VOZ',
                      iconColor: AppThemeManager.instance.borderColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VoiceAlertView()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String text,
    required Color iconColor,
    double iconSize = 56,
    bool capitalizeText = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppThemeManager.instance.secondaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppThemeManager.instance.borderColor, width: 3),
            ),
            child: Center(
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            capitalizeText ? text.toUpperCase() : text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
