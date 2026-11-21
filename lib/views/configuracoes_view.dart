import 'package:flutter/material.dart';
import '../app_theme_manager.dart';
import '../services/background_protection_service.dart';
import '../services/phone_drop_service.dart';
import '../services/voice_alert_service.dart';
import '../services/user_session_service.dart';
import '../models/user_profile.dart';
import 'phone_drop_view.dart';
import 'voice_alert_view.dart';

class ConfiguracoesView extends StatefulWidget {
  const ConfiguracoesView({super.key});

  @override
  State<ConfiguracoesView> createState() => _ConfiguracoesViewState();
}

class _ConfiguracoesViewState extends State<ConfiguracoesView> {
  bool _bgProtectionEnabled = true;
  bool _phoneDropEnabled = true;
  bool _voiceAlertEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final bg = await BackgroundProtectionService.instance.isEnabled();
    final drop = await PhoneDropService.instance.isEnabled();
    final voice = VoiceAlertService.instance.isRunning;
    if (mounted) {
      setState(() {
        _bgProtectionEnabled = bg;
        _phoneDropEnabled = drop;
        _voiceAlertEnabled = voice;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeManager.instance;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar ───────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'CONFIGURAÇÕES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        color: Colors.black,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Equilíbrio com o botão voltar
                ],
              ),
              const SizedBox(height: 24),

              if (UserSessionService.instance.currentUser.role == UserRole.idoso) ...[
                // ── Seção: Serviços de Emergência (Exclusivo do Perfil Idoso) ──────────
                const Text(
                  'SERVIÇOS DE SEGURANÇA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Aba 1: Detecção de Queda
                _buildFeatureCard(
                  icon: Icons.phone_android,
                  title: 'Detecção de Queda',
                  subtitle: 'Monitora impactos e quedas do aparelho e alerta o cuidador.',
                  statusText: _phoneDropEnabled ? 'ATIVO' : 'DESATIVADO',
                  statusColor: _phoneDropEnabled ? Colors.green.shade700 : Colors.grey,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PhoneDropView()),
                    );
                    _loadStatuses();
                  },
                ),
                const SizedBox(height: 14),

                // Aba 2: Alerta por Voz
                _buildFeatureCard(
                  icon: Icons.mic,
                  title: 'Alerta por Voz',
                  subtitle: 'Reconhece palavras de socorro como "socorro", "ajuda" e aciona o cuidador.',
                  statusText: _voiceAlertEnabled ? 'ATIVO' : 'DESATIVADO',
                  statusColor: _voiceAlertEnabled ? Colors.green.shade700 : Colors.grey,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VoiceAlertView()),
                    );
                    _loadStatuses();
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Aba 3: Proteção Contínua (Fora do App)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shield_outlined, color: theme.borderColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Proteção Fora do App',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Mantém queda e voz ativas mesmo com o app minimizado ou tela bloqueada.',
                            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _bgProtectionEnabled,
                      activeColor: theme.borderColor,
                      onChanged: (val) async {
                        final newStatus = await BackgroundProtectionService.instance.toggle();
                        setState(() => _bgProtectionEnabled = newStatus);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Seção: Aparência e Acessibilidade ─────────────────────
              const Text(
                'APARÊNCIA E ACESSIBILIDADE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tamanho da Fonte:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Slider(
                      value: theme.fontScale,
                      min: 0.8,
                      max: 1.5,
                      divisions: 7,
                      activeColor: theme.borderColor,
                      onChanged: (val) {
                        theme.setFontScale(val);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cor de Fundo do Aplicativo:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildColorOption(
                          color: const Color(0xFFC9A0DC),
                          label: 'Lilás Padrão',
                          isSelected: theme.backgroundColor == const Color(0xFFC9A0DC),
                          onTap: () {
                            theme.setBackgroundColor(const Color(0xFFC9A0DC));
                            setState(() {});
                          },
                        ),
                        _buildColorOption(
                          color: const Color(0xFFB3E5FC),
                          label: 'Azul Bebê',
                          isSelected: theme.backgroundColor == const Color(0xFFB3E5FC),
                          onTap: () {
                            theme.setBackgroundColor(const Color(0xFFB3E5FC));
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    final theme = AppThemeManager.instance;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.borderColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption({
    required Color color,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 24,
            child: isSelected ? const Icon(Icons.check, color: Colors.black) : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
