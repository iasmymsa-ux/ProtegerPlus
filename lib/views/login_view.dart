import 'package:flutter/material.dart';
import '../widgets/custom_logo.dart';
import '../widgets/custom_text_field.dart';
import 'permissions_view.dart';
import 'signup_view.dart';
import '../app_theme_manager.dart';
import '../services/api_config.dart';
import '../services/user_session_service.dart';

class LoginView extends StatefulWidget {
  final String profile;
  const LoginView({super.key, required this.profile});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _loginController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToSignup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SignupView(profile: widget.profile)),
    );
  }

  Future<void> _handleLogin() async {
    final loginInput = _loginController.text.trim();
    final passwordInput = _passwordController.text.trim();

    if (loginInput.isEmpty) {
      // Se não digitou login, permite navegar como modo de demonstração rápida
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PermissionsView(profile: widget.profile)),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isLoading = true);

    final res = await UserSessionService.instance.login(
      login: loginInput,
      password: passwordInput,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['sucesso'] == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Bem-vindo(a), ${UserSessionService.instance.currentUser.name}!'),
          backgroundColor: AppThemeManager.instance.primaryColor,
        ),
      );
      navigator.push(
        MaterialPageRoute(
          builder: (_) => PermissionsView(
            profile: UserSessionService.instance.currentUser.isCaregiver ? 'Cuidador' : 'Idoso',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['erro'] ?? 'Usuário ou senha incorretos.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showServerConfigDialog(BuildContext context) async {
    final currentUrl = ApiConfig.instance.baseUrl;
    final initialUrl = ApiConfig.isStaleTunnelUrl(currentUrl)
        ? ApiConfig.defaultPublicUrl
        : currentUrl;
    final controller = TextEditingController(text: initialUrl);
    String? statusMessage;
    bool isTesting = false;
    bool? isSuccess;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(

        
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.dns, color: Color(0xFF6A1B9A)),
              SizedBox(width: 8),
              Text('Servidor / Conexão', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Endereço da API do Banco de Dados:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isSuccess ?? false) ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isSuccess ?? false) ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (isSuccess ?? false) ? Icons.check_circle : Icons.error,
                          color: (isSuccess ?? false) ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: (isSuccess ?? false) ? Colors.green.shade900 : Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: isTesting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_find, size: 18),
                        label: const Text('Testar Conexão', style: TextStyle(fontSize: 12)),
                        onPressed: isTesting
                            ? null
                            : () async {
                                setDialogState(() {
                                  isTesting = true;
                                  statusMessage = null;
                                });
                                final ok = await ApiConfig.instance.testConnection(controller.text);
                                setDialogState(() {
                                  isTesting = false;
                                  isSuccess = ok;
                                  statusMessage = ok
                                      ? 'Conexão estabelecida com sucesso com o banco de dados!'
                                      : 'Não foi possível conectar. Verifique o endereço e a internet.';
                                });
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () async {
                        setDialogState(() {
                          isTesting = true;
                          statusMessage = null;
                        });
                        final working = await ApiConfig.instance.findWorkingBaseUrl();
                        controller.text = working;
                        final ok = await ApiConfig.instance.testConnection(working);
                        setDialogState(() {
                          isTesting = false;
                          isSuccess = ok;
                          statusMessage = ok
                              ? 'Túnel ativo encontrado e conectado!'
                              : 'Não foi possível alcançar o túnel automático.';
                        });
                      },
                      child: const Text('Restaurar Túnel Ativo (Online)', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () {
                        controller.text = 'http://${ApiConfig.defaultLocalIp}/proteger_plus_api';
                        setDialogState(() {
                          statusMessage = null;
                        });
                      },
                      child: const Text('Usar Wi-Fi Local (${ApiConfig.defaultLocalIp})', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await ApiConfig.instance.setBaseUrl(controller.text);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Endereço do servidor atualizado!')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeManager.instance,
      builder: (context, _) {
        final theme = AppThemeManager.instance;
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.backgroundColor,
                  theme.cardSelectionColor,
                ],
              ),
            ),
            child: SafeArea(
              child: IntrinsicHeight(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: Icon(Icons.dns_outlined, color: theme.primaryColor),
                            tooltip: 'Configurar Servidor / Conexão',
                            onPressed: () => _showServerConfigDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Center(child: CustomLogo(size: 180)),
                      const SizedBox(height: 32),
  
                      // Título "Login" como cabeçalho
                      Container(
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(25.0),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: theme.buttonTextColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
  
                      CustomTextField(
                        hintText: 'Email/telefone/usuário:',
                        controller: _loginController,
                      ),
                      CustomTextField(
                        hintText: 'Senha da conta:',
                        obscureText: true,
                        controller: _passwordController,
                      ),
  
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => _navigateToSignup(context),
                          child: Text(
                            'Não tem conta? Cadastrar',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
  
                      Center(
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Para redefinir sua senha, solicite ao seu cuidador ou administrador.'),
                              ),
                            );
                          },
                          child: Text(
                            'Esqueci minha senha',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
  
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: theme.buttonTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 6,
                          shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
