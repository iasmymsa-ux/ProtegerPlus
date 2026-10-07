import 'package:flutter/material.dart';
import 'lembretes_view.dart';
import 'profile_view.dart';
import 'direct_chat_view.dart';
import 'phone_drop_view.dart';
import 'voice_alert_view.dart';

class CuidadorHomeView extends StatelessWidget {
  const CuidadorHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lado Esquerdo: Perfil
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileView(profile: 'Cuidador')));
                    },
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Color(0xFF9C72AD)),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lado Direito: Premium
                  const Row(
                    children: [
                      Text(
                        'Perfil Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.stars, color: Colors.amber, size: 28),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // ── BOTÕES PRINCIPAIS ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Botão 1: Conversa Direta
                  _buildLargeCircularButton(
                    context: context,
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'CONVERSA DIRETA COM O USUÁRIO',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectChatView()));
                    },
                  ),
                  const SizedBox(height: 40),
  
                  // Botão 2: Lembretes
                  _buildLargeCircularButton(
                    context: context,
                    icon: Icons.event_note_rounded,
                    label: 'LEMBRETES',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LembretesView()));
                    },
                  ),
                  const SizedBox(height: 40),

                  // Botão 3: Detecção de Queda
                  _buildLargeCircularButton(
                    context: context,
                    icon: Icons.phone_android,
                    label: 'DETECÇÃO DE QUEDA',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneDropView()));
                    },
                  ),
                  const SizedBox(height: 40),

                  // Botão 4: Alerta por Voz
                  _buildLargeCircularButton(
                    context: context,
                    icon: Icons.mic,
                    label: 'ALERTA POR VOZ',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceAlertView()));
                    },
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // ── ÁREA DE NOTIFICAÇÕES ──────────────────────────
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Avisos e Notificações',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Não há novos lembretes no momento.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeCircularButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFAA8ED6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 3.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, size: 70, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
