import 'package:flutter/material.dart';
import 'alimentacao_view.dart';
import 'under_development_view.dart';
import '../app_theme_manager.dart';

class CuidadosSaudeView extends StatelessWidget {
  const CuidadosSaudeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cuidados com a Saúde',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'serif',
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildFeatureButton(
                context,
                icon: Icons.restaurant,
                text: 'Alimentação',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AlimentacaoView()));
                },
              ),
              const SizedBox(height: 32),
              _buildFeatureButton(
                context,
                icon: Icons.fitness_center,
                text: 'Exercícios',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UnderDevelopmentView()));
                },
              ),
              const SizedBox(height: 32),
              _buildFeatureButton(
                context,
                icon: Icons.spa,
                text: 'Bem-estar',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UnderDevelopmentView()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton(BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppThemeManager.instance.secondaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppThemeManager.instance.borderColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: 64, color: AppThemeManager.instance.borderColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
