import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_session_service.dart';
import 'direct_chat_view.dart';

/// Tela de Chat principal do Proteger+.
/// Respeita a regra de negócio exclusiva de vínculo entre Idoso e Cuidador por código.
/// Todos os contatos e conversas fictícias foram removidos.
class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserSessionService.instance,
      builder: (context, _) {
        final session = UserSessionService.instance;

        // Se houver vínculo ativo, direciona diretamente para a conversa com o cuidador
        if (session.hasActiveLink) {
          return const DirectChatView();
        }

        // Estado vazio contextual quando não há vínculo
        return _buildUnlinkedView(context, session);
      },
    );
  }

  Widget _buildUnlinkedView(BuildContext context, UserSessionService session) {
    final isSenior = session.currentUser.role == UserRole.idoso;

    final title = isSenior
        ? 'Nenhum Cuidador Vinculado'
        : 'Nenhum Idoso Vinculado';

    final explanation = isSenior
        ? 'Você ainda não está conectado a um cuidador. Vincule sua conta para começar a conversar com segurança.'
        : 'Você ainda não está conectado a um idoso. Vincule sua conta para começar a conversar e acompanhar seu paciente.';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat de Conversas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícone ilustrativo com a identidade visual do app
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C72AD).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 52,
                    color: Color(0xFF9C72AD),
                  ),
                ),
                const SizedBox(height: 24),

                // Título
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Mensagem contextual
                Text(
                  explanation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Card explicativo sobre o vínculo por código
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF9C72AD).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security, color: Color(0xFF9C72AD), size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Conexão Privada e Segura',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isSenior
                            ? 'O chat do Proteger+ funciona exclusivamente entre você e seu cuidador através do código de vinculação gerado no cadastro.'
                            : 'O chat do Proteger+ exige a confirmação do código de vinculação do idoso para liberar a troca de mensagens.',
                        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
