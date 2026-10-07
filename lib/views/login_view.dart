import 'package:flutter/material.dart';
import '../widgets/custom_logo.dart';
import '../widgets/custom_text_field.dart';
import 'permissions_view.dart';
import 'signup_view.dart';
import '../app_theme_manager.dart';

class LoginView extends StatelessWidget {
  final String profile;
  const LoginView({super.key, required this.profile});

  void _navigateToPermissions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PermissionsView(profile: profile)),
    );
  }

  void _navigateToSignup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SignupView(profile: profile)),
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
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Center(child: CustomLogo(size: 180)),
                      const SizedBox(height: 32),
  
                      // Título "Login" como se fosse um botão não clicável
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
  
                      CustomTextField(hintText: 'Email/telefone/ usuário:'),
                      CustomTextField(
                        hintText: 'Senha da conta do usuário:',
                        obscureText: true,
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
                            // TODO: Forgot password
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
                      const SizedBox(height: 60),
  
                      ElevatedButton(
                        onPressed: () => _navigateToPermissions(context),
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
                        child: const Text(
                          'Continuar',
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
