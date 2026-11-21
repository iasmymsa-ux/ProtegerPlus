import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/voice_alert_service.dart';
import '../services/emergency_sms_service.dart';
import '../services/background_protection_service.dart';
import '../app_theme_manager.dart';

/// Tela de configuração do alerta por voz.
/// Permite:
///   - Ligar/desligar o monitoramento de voz
///   - Ver em tempo real as palavras que o microfone está ouvindo (diagnóstico)
///   - Ativar permissão de segundo plano e tela bloqueada (otimização de bateria)
///   - Ver/adicionar/remover palavras-chave de emergência
///   - Testar o envio de alerta manualmente
class VoiceAlertView extends StatefulWidget {
  const VoiceAlertView({super.key});

  @override
  State<VoiceAlertView> createState() => _VoiceAlertViewState();
}

class _VoiceAlertViewState extends State<VoiceAlertView>
    with SingleTickerProviderStateMixin {
  bool _isEnabled = false;
  bool _isLoading = true;
  List<String> _keywords = [];
  final _newKeywordController = TextEditingController();
  String _lastDetectedWord = '';
  String _lastHeardText = '';
  String _alertMessage = '';
  bool _hasSmsPermission = false;
  bool _isBatteryOptIgnored = false;
  String _cuidadorPhone = '';

  late AnimationController _micController;
  late Animation<double> _micScale;

  @override
  void initState() {
    super.initState();

    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _micScale = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _micController, curve: Curves.easeInOut),
    );

    _loadState();

    VoiceAlertService.instance.onKeywordDetected = (keyword) {
      if (mounted) {
        setState(() {
          _lastDetectedWord = keyword;
          _alertMessage = '🚨 Palavra detectada: "$keyword" — Alerta enviado ao cuidador!';
        });
        _showAlertDialog(keyword);
      }
    };

    VoiceAlertService.instance.onSpeechHeard = (text) {
      if (mounted) {
        setState(() {
          _lastHeardText = text;
        });
      }
    };
  }

  Future<void> _loadState() async {
    final enabled = await VoiceAlertService.instance.isEnabled();
    final keywords = await VoiceAlertService.instance.getKeywords();
    final smsPerm = await EmergencySmsService.instance.hasPermission();
    final batteryIgnored = await BackgroundProtectionService.instance.isBatteryOptimizationIgnored();
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('cuidador_whatsapp') ?? '';

    if (mounted) {
      setState(() {
        _isEnabled = VoiceAlertService.instance.isRunning || enabled;
        _keywords = keywords;
        _hasSmsPermission = smsPerm;
        _isBatteryOptIgnored = batteryIgnored;
        _cuidadorPhone = phone;
        _lastHeardText = VoiceAlertService.instance.lastHeardText;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMonitoring() async {
    setState(() => _isLoading = true);
    final newState = await VoiceAlertService.instance.toggle();

    if (newState) {
      // Proativamente solicita as permissões necessárias para segundo plano e SMS
      final smsOk = await EmergencySmsService.instance.requestPermission();
      final batteryOk = await BackgroundProtectionService.instance.requestIgnoreBatteryOptimizations();

      if (mounted) {
        setState(() {
          _hasSmsPermission = smsOk;
          _isBatteryOptIgnored = batteryOk;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isEnabled = newState;
        _isLoading = false;
        if (!newState) _alertMessage = '';
      });
    }
  }

  Future<void> _requestBatteryOptimization() async {
    final ok = await BackgroundProtectionService.instance.requestIgnoreBatteryOptimizations();
    if (mounted) {
      setState(() {
        _isBatteryOptIgnored = ok;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Proteção em segundo plano e tela bloqueada autorizada!'
                : 'Abra as configurações do app e marque "Sem restrições" na bateria.',
          ),
          backgroundColor: ok ? Colors.green.shade700 : Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _requestSmsPermission() async {
    final ok = await EmergencySmsService.instance.requestPermission();
    if (mounted) {
      setState(() {
        _hasSmsPermission = ok;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Permissão de SMS concedida com sucesso!'
                : 'Permissão de SMS foi negada. Conceda nas configurações do app.',
          ),
          backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _addKeyword() {
    final word = _newKeywordController.text.trim().toLowerCase();
    if (word.isEmpty) return;
    if (_keywords.contains(word)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A palavra "$word" já está na lista!'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() {
      _keywords.add(word);
      _newKeywordController.clear();
    });
    VoiceAlertService.instance.saveKeywords(_keywords);
  }

  void _removeKeyword(String keyword) {
    setState(() => _keywords.remove(keyword));
    VoiceAlertService.instance.saveKeywords(_keywords);
  }

  void _resetToDefaults() {
    setState(() => _keywords = List.from(VoiceAlertService.defaultKeywords));
    VoiceAlertService.instance.saveKeywords(_keywords);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Palavras-chave restauradas para o padrão!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAlertDialog(String keyword) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.red.shade50,
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.red, size: 30),
            SizedBox(width: 8),
            Text('Alerta de Voz!', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          'Palavra-chave detectada:\n\n"$keyword"\n\nO cuidador foi alertado por SMS diretamente!',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _micController.dispose();
    _newKeywordController.dispose();
    VoiceAlertService.instance.onKeywordDetected = null;
    VoiceAlertService.instance.onSpeechHeard = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppThemeManager.instance.primaryColor;
    final bgColor = AppThemeManager.instance.backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Alerta por Voz',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'serif',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.restore, color: AppThemeManager.instance.borderColor),
            tooltip: 'Restaurar padrão',
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    // ── Ícone de microfone animado ──────────────────────────
                    AnimatedBuilder(
                      animation: _micScale,
                      builder: (context, child) => Transform.scale(
                        scale: _isEnabled ? _micScale.value : 1.0,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isEnabled
                                ? Colors.red.withValues(alpha: 0.12)
                                : Colors.grey.shade200,
                            border: Border.all(
                              color: _isEnabled ? Colors.red : Colors.grey,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            _isEnabled ? Icons.mic : Icons.mic_off,
                            size: 68,
                            color: _isEnabled ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status
                    Text(
                      _isEnabled
                          ? '🟢 Escutando ativamente...'
                          : '🔴 Monitoramento desativado',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _isEnabled
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),

                    // Palavra detectada (aparece quando detecta algo)
                    if (_alertMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _alertMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    Text(
                      _isEnabled
                          ? 'O microfone escuta palavras de socorro continuamente,\nmesmo fora do app ou com a tela apagada.'
                          : 'Ative para monitorar palavras de socorro em tempo real.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Card de Diagnóstico em Tempo Real (O que o mic está ouvindo) ──
                    if (_isEnabled)
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.hearing, color: Colors.blueAccent, size: 24),
                                const SizedBox(width: 8),
                                const Text(
                                  'Captado pelo Microfone (Tempo Real):',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                _lastHeardText.isNotEmpty
                                    ? '"$_lastHeardText"'
                                    : 'Aguardando voz... Fale "socorro" ou "ajuda" para testar.',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontStyle: _lastHeardText.isNotEmpty
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                  fontWeight: _lastHeardText.isNotEmpty
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _lastHeardText.isNotEmpty
                                      ? Colors.blue.shade900
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Avisos e Permissões Importantes (Segundo Plano e SMS) ──
                    if (!_isBatteryOptIgnored || !_hasSmsPermission || _cuidadorPhone.isEmpty) ...[
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange, size: 26),
                                SizedBox(width: 8),
                                Text(
                                  'Configurações Necessárias',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Alerta Bateria (Segundo plano / tela bloqueada)
                            if (!_isBatteryOptIgnored) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: const Icon(Icons.battery_alert,
                                    color: Colors.orange),
                                title: const Text(
                                  'Funcionar com a tela bloqueada',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: const Text(
                                  'Permita o app rodar sem restrições de bateria no Android.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: _requestBatteryOptimization,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  child: const Text('Permitir'),
                                ),
                              ),
                              const Divider(),
                            ],

                            // Alerta SMS
                            if (!_hasSmsPermission) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: const Icon(Icons.sms_failed,
                                    color: Colors.red),
                                title: const Text(
                                  'Permissão de Envio de SMS',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: const Text(
                                  'Necessária para alertar o cuidador silenciosamente.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: _requestSmsPermission,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  child: const Text('Autorizar'),
                                ),
                              ),
                              const Divider(),
                            ],

                            // Alerta Cuidador
                            if (_cuidadorPhone.isEmpty) ...[
                              const ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: Icon(Icons.person_off, color: Colors.red),
                                title: Text(
                                  'Nenhum cuidador cadastrado',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                ),
                                subtitle: Text(
                                  'Cadastre o telefone do cuidador na tela de Perfil ou Queda.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Toggle Liga/Desliga ──────────────────────────────────
                    _buildCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.record_voice_over,
                                  color: primaryColor, size: 28),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monitoramento de voz',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Detecta palavras de socorro',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: _isEnabled,
                            onChanged: (_) => _toggleMonitoring(),
                            activeThumbColor: Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Adicionar palavra-chave ──────────────────────────────
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_circle_outline,
                                  color: primaryColor, size: 26),
                              const SizedBox(width: 10),
                              const Text(
                                'Adicionar Palavra-chave',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Personalize quais palavras disparam o alerta',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newKeywordController,
                                  textCapitalization: TextCapitalization.none,
                                  decoration: InputDecoration(
                                    hintText: 'Ex: não consigo respirar',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: primaryColor, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                  ),
                                  onSubmitted: (_) => _addKeyword(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addKeyword,
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(14),
                                  backgroundColor: primaryColor,
                                ),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 22),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Lista de palavras-chave ──────────────────────────────
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.list_alt,
                                      color: primaryColor, size: 26),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Palavras Monitoradas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_keywords.length}',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _keywords.map((keyword) {
                              final isDetected = keyword == _lastDetectedWord;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                child: Chip(
                                  label: Text(
                                    keyword,
                                    style: TextStyle(
                                      fontWeight: isDetected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isDetected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 13,
                                    ),
                                  ),
                                  backgroundColor: isDetected
                                      ? Colors.red
                                      : primaryColor.withValues(alpha: 0.12),
                                  side: BorderSide(
                                    color: isDetected
                                        ? Colors.red
                                        : primaryColor.withValues(alpha: 0.3),
                                  ),
                                  deleteIcon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: isDetected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                  onDeleted: () => _removeKeyword(keyword),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Como funciona ────────────────────────────────────────
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: primaryColor),
                              const SizedBox(width: 8),
                              const Text(
                                'Como funciona?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStep(
                              '1', 'O microfone escuta continuamente em segundo plano (com reconhecimento fonético)'),
                          _buildStep(
                              '2', 'Tolera variações de fala, gritos prolongados ou erros do reconhecedor'),
                          _buildStep(
                              '3', 'Funciona com tela apagada e fora do app graças à Proteção em 2º Plano'),
                          _buildStep(
                              '4', 'Ao detectar socorro, acorda a tela e envia um SMS direto com a frase dita'),
                          _buildStep(
                              '5', 'O cuidador é acionado imediatamente sem que o idoso precise tocar no celular!'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Botão de Teste ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final sent = await VoiceAlertService.instance.sendTestAlert();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(sent ? Icons.check_circle : Icons.error, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(sent
                                          ? 'Alerta de teste enviado diretamente por SMS!'
                                          : 'Falha ao enviar SMS. Verifique permissão de SMS e telefone do cuidador.'),
                                    ),
                                  ],
                                ),
                                backgroundColor: sent ? Colors.green.shade700 : Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_outlined),
                        label: const Text(
                          'Testar Alerta Agora',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppThemeManager.instance.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
