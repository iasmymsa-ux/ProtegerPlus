import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alert_sync_service.dart';
import '../services/user_session_service.dart';
import '../services/voice_alert_service.dart';
import '../services/phone_drop_service.dart';
import '../services/emergency_sms_service.dart';
import '../app_theme_manager.dart';

/// Tela unificada de Alertas de Emergência: Voz e Quedas.
/// Permite ao cuidador gerenciar e acompanhar:
/// 1. Palavras de socorro por voz detectadas no aparelho do idoso
/// 2. Detecção automática de impacto e queda do idoso
class GerenciarPalavrasView extends StatefulWidget {
  const GerenciarPalavrasView({super.key});

  @override
  State<GerenciarPalavrasView> createState() => _GerenciarPalavrasViewState();
}

class _GerenciarPalavrasViewState extends State<GerenciarPalavrasView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Estado de Palavras de Voz ──────────────────────────────────────────────
  final TextEditingController _palavraController = TextEditingController();
  List<String> _palavras = [];
  bool _isLoadingPalavras = true;
  bool _isSavingPalavras = false;

  // ── Estado de Detecção de Quedas ───────────────────────────────────────────
  final TextEditingController _telefoneCuidadorController = TextEditingController();
  bool _quedaAtivada = true;
  bool _isLoadingQueda = true;
  bool _isSavingQueda = false;
  List<EmergencyAlertItem> _historicoQuedas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarTudo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _palavraController.dispose();
    _telefoneCuidadorController.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    await Future.wait([
      _carregarPalavras(),
      _carregarConfiguracaoQuedas(),
    ]);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LÓGICA DE PALAVRAS DE VOZ
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _carregarPalavras() async {
    setState(() => _isLoadingPalavras = true);
    final session = UserSessionService.instance;
    final codigo = session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.currentUser.connectionCode ??
        '';

    List<String> lista = [];
    if (codigo.isNotEmpty) {
      lista = await AlertSyncService.instance.obterPalavrasAlerta(codigo: codigo);
    }

    if (lista.isEmpty) {
      lista = List.from(VoiceAlertService.defaultKeywords.take(15));
    }

    if (mounted) {
      setState(() {
        _palavras = lista;
        _isLoadingPalavras = false;
      });
    }
  }

  Future<void> _salvarPalavrasNoServidor() async {
    final session = UserSessionService.instance;
    final codigo = session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.currentUser.connectionCode ??
        '';

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Código de vínculo com o idoso não encontrado.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSavingPalavras = true);
    final ok = await AlertSyncService.instance.salvarPalavrasAlerta(
      codigo: codigo,
      palavras: _palavras,
      seniorId: session.partnerUser?.id,
    );

    if (mounted) {
      setState(() => _isSavingPalavras = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.info, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ok
                      ? 'Palavras de alerta sincronizadas com o aparelho do idoso!'
                      : 'Salvo localmente (aguardando conexão do servidor).',
                ),
              ),
            ],
          ),
          backgroundColor: ok ? Colors.green.shade700 : Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _adicionarPalavra() {
    final text = _palavraController.text.trim().toLowerCase();
    if (text.isEmpty) return;

    if (_palavras.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta palavra já está na lista!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _palavras.insert(0, text);
      _palavraController.clear();
    });

    _salvarPalavrasNoServidor();
  }

  void _removerPalavra(String palavra) {
    setState(() {
      _palavras.remove(palavra);
    });
    _salvarPalavrasNoServidor();
  }

  void _restaurarPadrao() {
    setState(() {
      _palavras = List.from(VoiceAlertService.defaultKeywords.take(15));
    });
    _salvarPalavrasNoServidor();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LÓGICA DE DETECÇÃO DE QUEDAS
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _carregarConfiguracaoQuedas() async {
    setState(() => _isLoadingQueda = true);

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('cuidador_whatsapp') ??
        UserSessionService.instance.partnerUser?.phone ??
        UserSessionService.instance.currentUser.caregiverPhone ??
        '';

    final enabled = prefs.getBool('phone_drop_enabled') ?? true;

    // Busca alertas de queda recentes
    final session = UserSessionService.instance;
    final codigo = session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.currentUser.connectionCode ??
        '';

    List<EmergencyAlertItem> alertas = [];
    if (codigo.isNotEmpty) {
      try {
        final todos = await AlertSyncService.instance.buscarAlertas(
          codigo: codigo,
          userId: session.partnerUser?.id,
        );
        alertas = todos.where((a) => a.tipoAlerta == 'queda').toList();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _telefoneCuidadorController.text = phone;
        _quedaAtivada = enabled;
        _historicoQuedas = alertas;
        _isLoadingQueda = false;
      });
    }
  }

  Future<void> _salvarConfiguracaoQueda() async {
    setState(() => _isSavingQueda = true);
    final phone = _telefoneCuidadorController.text.trim();
    await PhoneDropService.instance.saveCuidadorPhone(phone);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('phone_drop_enabled', _quedaAtivada);

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _isSavingQueda = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Configuração de queda salva com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _testarAlertaQueda() async {
    final phone = _telefoneCuidadorController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre o telefone de socorro primeiro.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Registra alerta no servidor
    final session = UserSessionService.instance;
    await AlertSyncService.instance.registrarAlerta(
      tipo: 'queda',
      detalhes: 'Simulação de queda efetuada pelo cuidador para teste de prontidão.',
      telefoneDestino: phone,
    );

    // Envia SMS de teste se possível
    await EmergencySmsService.instance.sendDirectSms(
      rawPhone: phone,
      message: 'PROTEGER+ (TESTE): Alerta de queda disparado em modo de teste pelo cuidador.',
    );

    await _carregarConfiguracaoQuedas();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Teste de alerta de queda disparado com sucesso!'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionService.instance;
    final idosoNome = session.partnerUser?.name.isNotEmpty == true
        ? session.partnerUser!.name
        : (session.activeLink?.seniorName.isNotEmpty == true
            ? session.activeLink!.seniorName
            : 'Idoso Monitorado');
    final codigo = session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.currentUser.connectionCode ??
        'N/A';

    return Scaffold(
      backgroundColor: AppThemeManager.instance.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alertas e Quedas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'serif',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.sync, color: AppThemeManager.instance.borderColor),
            tooltip: 'Sincronizar',
            onPressed: _carregarTudo,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppThemeManager.instance.borderColor,
          indicatorWeight: 3,
          labelColor: AppThemeManager.instance.borderColor,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.record_voice_over_outlined, size: 22),
              text: 'Alerta por Voz',
            ),
            Tab(
              icon: Icon(Icons.personal_injury_outlined, size: 22),
              text: 'Detecção de Quedas',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // ── ABA 1: ALERTA POR VOZ ──────────────────────────────────────
            _buildAbaVoz(idosoNome, codigo),

            // ── ABA 2: DETECÇÃO DE QUEDAS ──────────────────────────────────
            _buildAbaQuedas(idosoNome, codigo),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // WIDGETS ABA 1: ALERTA POR VOZ
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAbaVoz(String idosoNome, String codigo) {
    return _isLoadingPalavras
        ? Center(child: CircularProgressIndicator(color: AppThemeManager.instance.borderColor))
        : RefreshIndicator(
            color: AppThemeManager.instance.borderColor,
            onRefresh: _carregarPalavras,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Card de informações do idoso
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppThemeManager.instance.secondaryColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppThemeManager.instance.borderColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppThemeManager.instance.borderColor),
                        ),
                        child: Icon(
                          Icons.mic_outlined,
                          color: AppThemeManager.instance.borderColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monitorando: $idosoNome',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Código de conexão: $codigo',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Caixa explicativa
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppThemeManager.instance.borderColor, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Quando o idoso pronunciar qualquer uma dessas palavras no aparelho dele, você receberá um alarme de socorro imediatamente.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Campo para adicionar nova palavra
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _palavraController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Adicionar palavra (ex: "caí", "socorro")...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => _adicionarPalavra(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeManager.instance.borderColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _adicionarPalavra,
                      child: const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Cabeçalho da lista de palavras
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Palavras Cadastradas (${_palavras.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppThemeManager.instance.borderColor,
                      ),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Restaurar padrão', style: TextStyle(fontSize: 12.5)),
                      onPressed: _restaurarPadrao,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Lista de chips de palavras
                if (_palavras.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Text(
                        'Nenhuma palavra cadastrada ainda.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _palavras.map((palavra) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppThemeManager.instance.borderColor.withValues(alpha: 0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up_outlined,
                              color: AppThemeManager.instance.borderColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              palavra,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _removerPalavra(palavra),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // WIDGETS ABA 2: DETECÇÃO DE QUEDAS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAbaQuedas(String idosoNome, String codigo) {
    return _isLoadingQueda
        ? Center(child: CircularProgressIndicator(color: AppThemeManager.instance.borderColor))
        : RefreshIndicator(
            color: AppThemeManager.instance.borderColor,
            onRefresh: _carregarConfiguracaoQuedas,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Card de status da detecção de quedas
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppThemeManager.instance.secondaryColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppThemeManager.instance.borderColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppThemeManager.instance.borderColor),
                        ),
                        child: Icon(
                          Icons.personal_injury_outlined,
                          color: AppThemeManager.instance.borderColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monitoramento de Quedas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _quedaAtivada
                                  ? 'Acelerômetro ativo no aparelho do idoso'
                                  : 'Detecção de quedas pausada',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _quedaAtivada ? Colors.green.shade700 : Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _quedaAtivada,
                        activeColor: AppThemeManager.instance.borderColor,
                        onChanged: (val) {
                          setState(() => _quedaAtivada = val);
                          _salvarConfiguracaoQueda();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Telefone de emergência
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_in_talk_outlined, color: AppThemeManager.instance.borderColor, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Telefone de Emergência (SMS / Ligação)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Número que receberá o aviso imediato caso uma queda seja detectada.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _telefoneCuidadorController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: '(00) 00000-0000',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemeManager.instance.borderColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isSavingQueda ? null : _salvarConfiguracaoQueda,
                            child: const Text('Salvar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Botão de Testar Alerta
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemeManager.instance.borderColor,
                      side: BorderSide(color: AppThemeManager.instance.borderColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text(
                      'Testar Alerta de Queda Agora',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _testarAlertaQueda,
                  ),
                ),

                const SizedBox(height: 24),

                // Histórico de Quedas
                Text(
                  'Ocorrências de Queda Registradas (${_historicoQuedas.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                if (_historicoQuedas.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.green.shade600, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Nenhuma queda registrada no momento.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'O sistema está vigiando e alertará caso ocorra qualquer impacto.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._historicoQuedas.map((queda) {
                    final dataStr =
                        '${queda.dataHora.day.toString().padLeft(2, '0')}/${queda.dataHora.month.toString().padLeft(2, '0')}/${queda.dataHora.year} às ${queda.dataHora.hour.toString().padLeft(2, '0')}:${queda.dataHora.minute.toString().padLeft(2, '0')}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.personal_injury, color: Colors.red, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Impacto / Queda Detectada',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dataStr,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                if (queda.detalhes.isNotEmpty)
                                  Text(
                                    queda.detalhes,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 24),
              ],
            ),
          );
  }
}
