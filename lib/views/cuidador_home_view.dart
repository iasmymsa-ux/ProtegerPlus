import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'lembretes_view.dart';
import 'profile_view.dart';
import 'direct_chat_view.dart';
import 'gerenciar_palavras_view.dart';
import 'saude_idoso_view.dart';
import 'initial_view.dart';
import '../app_theme_manager.dart';
import '../services/user_session_service.dart';
import '../services/reminder_service.dart';
import '../services/alert_sync_service.dart';
import '../models/user_profile.dart';
import '../models/reminder_model.dart';

class CuidadorHomeView extends StatefulWidget {
  const CuidadorHomeView({super.key});

  @override
  State<CuidadorHomeView> createState() => _CuidadorHomeViewState();
}

class _CuidadorHomeViewState extends State<CuidadorHomeView> {
  List<ReminderModel> _proximosLembretes = [];
  List<EmergencyAlertItem> _alertasEmergencia = [];
  Timer? _alertPollTimer;
  bool _isLoadingAlerts = false;

  @override
  void initState() {
    super.initState();
    UserSessionService.instance.addListener(_onSessionChange);
    _loadLembretes();
    _iniciarMonitoramentoAlertas();
  }

  @override
  void dispose() {
    _alertPollTimer?.cancel();
    UserSessionService.instance.removeListener(_onSessionChange);
    super.dispose();
  }

  void _onSessionChange() {
    if (mounted) setState(() {});
  }

  void _loadLembretes() {
    final todos = ReminderService().reminders;
    setState(() {
      _proximosLembretes = todos.take(3).toList();
    });
  }

  void _iniciarMonitoramentoAlertas() {
    _buscarAlertas();
    _alertPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _buscarAlertas();
    });
  }

  Future<void> _buscarAlertas() async {
    if (_isLoadingAlerts) return;
    _isLoadingAlerts = true;
    try {
      final session = UserSessionService.instance;
      final codigo = session.activeLink?.connectionCode ??
          session.partnerUser?.connectionCode ??
          session.currentUser.connectionCode ??
          '';

      final lista = await AlertSyncService.instance.buscarAlertas(
        codigo: codigo,
        userId: session.partnerUser?.id,
      );

      if (mounted) {
        setState(() {
          _alertasEmergencia = lista;
        });
      }
    } catch (_) {}
    _isLoadingAlerts = false;
  }

  Future<void> _marcarAlertaVisto(String alertaId) async {
    await AlertSyncService.instance.marcarVisto(alertaId);
    _buscarAlertas();
  }

  Future<void> _ligarParaIdoso(String telefone) async {
    final clean = telefone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _getReminderTitle(ReminderModel r) {
    switch (r.type) {
      case ReminderType.medicamento:
        return r.nomeMedicamento ?? 'Medicamento';
      case ReminderType.consulta:
        return r.profissionalConsulta ?? 'Consulta';
      case ReminderType.tarefa:
        return r.nomeTarefa ?? 'Tarefa';
      case ReminderType.alerta:
        return r.tituloAlerta ?? 'Alerta';
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente fazer logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await UserSessionService.instance.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InitialView()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Excluir conta permanentemente',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Atenção: esta ação é irreversível!\n\n'
          'Todos os seus dados cadastrais, lembretes, conversas e vínculos serão excluídos definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Definitivamente',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final res = await UserSessionService.instance.deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['mensagem'] ?? 'Conta excluída com sucesso.'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InitialView()),
        (route) => false,
      );
    }
  }

  void _showAccountOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Opções da Conta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.black87),
                title: const Text('Meu Perfil'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileView(profile: 'Cuidador'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.black87),
                title: const Text('Sair da conta (Logout)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleLogout();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Excluir conta permanentemente',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                subtitle:
                    const Text('Apaga todos os dados e vínculos no servidor'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDeleteAccount();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionService.instance;
    final firstName = session.currentUser.name.isNotEmpty &&
            session.currentUser.name != 'Usuário'
        ? session.currentUser.name.split(' ').first
        : 'Cuidador';

    final hasPartner = session.hasActiveLink || session.partnerUser != null;
    final partnerName = session.partnerUser?.name.isNotEmpty == true
        ? session.partnerUser!.name
        : (session.activeLink?.seniorName.isNotEmpty == true
            ? session.activeLink!.seniorName
            : 'Idoso Monitorado');

    final connectionCode = session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.currentUser.connectionCode ??
        'N/A';

    final idosoPhone = session.partnerUser?.phone ??
        session.currentUser.caregiverPhone ??
        '';

    final alertasNaoVistos = _alertasEmergencia.where((a) => !a.visto).toList();

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
                // ── Header igual ao home_view ──────────────────────
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
                                const ProfileView(profile: 'Cuidador'),
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
                          Text(
                            firstName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.2),
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
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.logout,
                              size: 28, color: Colors.black87),
                          tooltip: 'Sair ou Excluir Conta',
                          onPressed: _showAccountOptions,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Card do Idoso Monitorado ────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppThemeManager.instance.secondaryColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppThemeManager.instance.borderColor
                          .withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasPartner
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          hasPartner
                              ? Icons.link_rounded
                              : Icons.link_off_rounded,
                          color:
                              hasPartner ? Colors.green.shade700 : Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasPartner
                                  ? 'Idoso Conectado'
                                  : 'Aguardando Vínculo',
                              style: TextStyle(
                                color: hasPartner
                                    ? Colors.green.shade700
                                    : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              partnerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Código: $connectionCode',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (idosoPhone.isNotEmpty)
                        IconButton(
                          onPressed: () => _ligarParaIdoso(idosoPhone),
                          icon: Icon(Icons.call,
                              color: AppThemeManager.instance.borderColor),
                          tooltip: 'Ligar para o idoso',
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Alertas de Emergência ─────────────────────────
                if (alertasNaoVistos.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.red.shade300, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.red.shade700, size: 26),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🚨 ALERTA DE EMERGÊNCIA (${alertasNaoVistos.length})',
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...alertasNaoVistos.take(2).map((alerta) {
                          String titulo = 'Ocorrência detectada';
                          IconData iconData = Icons.emergency_rounded;
                          if (alerta.tipoAlerta == 'queda') {
                            titulo = 'Queda do aparelho detectada!';
                            iconData = Icons.phone_android_rounded;
                          } else if (alerta.tipoAlerta == 'voz') {
                            titulo = 'Palavra de socorro detectada!';
                            iconData = Icons.record_voice_over_rounded;
                          } else if (alerta.tipoAlerta == 'botao_panico') {
                            titulo = 'Botão SOS de emergência pressionado!';
                            iconData = Icons.touch_app_rounded;
                          }
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(iconData,
                                        color: Colors.red.shade700, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        titulo,
                                        style: TextStyle(
                                          color: Colors.red.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${alerta.dataHora.hour.toString().padLeft(2, '0')}:${alerta.dataHora.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alerta.detalhes,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (alerta.telefoneDestino.isNotEmpty)
                                      TextButton.icon(
                                        onPressed: () => _ligarParaIdoso(
                                            alerta.telefoneDestino),
                                        icon: const Icon(Icons.call,
                                            size: 16, color: Colors.white),
                                        label: const Text('Ligar Agora',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12)),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () =>
                                          _marcarAlertaVisto(alerta.id),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: Colors.red.shade400),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                      ),
                                      child: Text(
                                        'Marcar como Atendido',
                                        style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 28),

                // ── Grade de funcionalidades (igual ao home_view) ──
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildFeatureButton(
                      icon: Icons.chat_bubble_outline,
                      text: 'CONVERSA\nDIRETA',
                      iconColor: AppThemeManager.instance.borderColor,
                      onTap: () {
                        UserSessionService.instance.setRole(UserRole.cuidador);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DirectChatView()),
                        );
                      },
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
                      icon: Icons.health_and_safety_outlined,
                      text: 'SAÚDE DO\nIDOSO',
                      iconColor: AppThemeManager.instance.borderColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SaudeIdosoView()),
                      ),
                    ),
                    _buildFeatureButton(
                      icon: Icons.record_voice_over_outlined,
                      text: 'ALERTA\nDE VOZ',
                      iconColor: AppThemeManager.instance.borderColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GerenciarPalavrasView()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Próximos Lembretes ──────────────────────────────
                if (_proximosLembretes.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Próximos Lembretes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppThemeManager.instance.borderColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppThemeManager.instance.secondaryColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppThemeManager.instance.borderColor
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: _proximosLembretes.map<Widget>((r) {
                        final horario = r.horarios.isNotEmpty
                            ? r.horarios.first
                            : (r.horarioConsulta ?? '');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 7,
                                  color: AppThemeManager.instance.borderColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getReminderTitle(r),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (horario.isNotEmpty)
                                Text(
                                  horario,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
    required VoidCallback onTap,
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
                color: AppThemeManager.instance.borderColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
