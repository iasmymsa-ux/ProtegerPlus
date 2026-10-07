import 'package:flutter/material.dart';
import '../services/phone_drop_service.dart';
import '../app_theme_manager.dart';

/// Tela de configuração e monitoramento de queda do celular.
/// Permite ao usuário:
///   - Ligar/desligar a detecção automática
///   - Cadastrar o número WhatsApp do cuidador
///   - Testar o envio do alerta manualmente
class PhoneDropView extends StatefulWidget {
  const PhoneDropView({super.key});

  @override
  State<PhoneDropView> createState() => _PhoneDropViewState();
}

class _PhoneDropViewState extends State<PhoneDropView>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _isEnabled = true;
  bool _isSaving = false;
  bool _dropJustDetected = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animação de pulso no ícone de alerta
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadSettings();

    // Registra callback para atualizar a UI quando uma queda for detectada
    PhoneDropService.instance.onDropDetected = () {
      if (mounted) {
        setState(() => _dropJustDetected = true);
        _showDropDialog();
        Future.delayed(
          const Duration(seconds: 5),
          () {
            if (mounted) setState(() => _dropJustDetected = false);
          },
        );
      }
    };
  }

  Future<void> _loadSettings() async {
    final phone = await PhoneDropService.instance.getCuidadorPhone();
    final enabled = await PhoneDropService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _phoneController.text = phone;
        _isEnabled = enabled;
      });
    }
  }

  Future<void> _savePhone() async {
    setState(() => _isSaving = true);
    await PhoneDropService.instance.saveCuidadorPhone(_phoneController.text);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Número do cuidador salvo com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _toggleMonitoring() async {
    final newState = await PhoneDropService.instance.toggle();
    if (mounted) setState(() => _isEnabled = newState);
  }

  Future<void> _testAlert() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cadastre o número do cuidador primeiro!'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    await PhoneDropService.instance.saveCuidadorPhone(phone);
    await PhoneDropService.instance.sendManualAlert();
  }

  void _showDropDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.red.shade50,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('Queda Detectada!', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          'O celular parece ter caído no chão.\n\n'
          'O cuidador foi notificado via WhatsApp automaticamente.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK, estou bem', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _phoneController.dispose();
    PhoneDropService.instance.onDropDetected = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppThemeManager.instance.primaryColor;
    final bgColor = AppThemeManager.instance.backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Detecção de Queda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // ── Ícone principal animado ─────────────────────────────────
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) => Transform.scale(
                  scale: _isEnabled ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dropJustDetected
                          ? Colors.red.shade100
                          : _isEnabled
                              ? primaryColor.withValues(alpha: 0.15)
                              : Colors.grey.shade200,
                      border: Border.all(
                        color: _dropJustDetected
                            ? Colors.red
                            : _isEnabled
                                ? primaryColor
                                : Colors.grey,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      _dropJustDetected
                          ? Icons.warning_amber_rounded
                          : Icons.phone_android,
                      size: 72,
                      color: _dropJustDetected
                          ? Colors.red
                          : _isEnabled
                              ? primaryColor
                              : Colors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Status ──────────────────────────────────────────────────
              Text(
                _dropJustDetected
                    ? '⚠️ Queda detectada!'
                    : _isEnabled
                        ? '🟢 Monitoramento ativo'
                        : '🔴 Monitoramento desativado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _dropJustDetected
                      ? Colors.red
                      : _isEnabled
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isEnabled
                    ? 'O app detecta automaticamente se o celular\ncair e avisa o cuidador pelo WhatsApp.'
                    : 'Ative o monitoramento para receber alertas\nautomáticos de queda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 32),

              // ── Toggle de ativação ──────────────────────────────────────
              _buildCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sensors,
                          color: primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detecção automática',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Usa o acelerômetro do celular',
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
                      activeThumbColor: primaryColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Campo do número do cuidador ─────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chat, color: Colors.green.shade600, size: 28),
                        const SizedBox(width: 10),
                        const Text(
                          'WhatsApp do Cuidador',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Número que receberá o alerta de queda',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Ex: (31) 99999-0000',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _savePhone,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSaving ? 'Salvando...' : 'Salvar Número'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Como funciona ───────────────────────────────────────────
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
                    _buildStep('1', 'O acelerômetro detecta queda livre do celular'),
                    _buildStep('2', 'Em seguida detecta o impacto com o chão'),
                    _buildStep('3', 'Abre WhatsApp com mensagem de alerta pronta'),
                    _buildStep('4', 'O cuidador é avisado imediatamente!'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Botão de Teste ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _testAlert,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text(
                    'Testar Alerta Agora',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor, width: 2),
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
