import 'package:flutter/material.dart';
import '../app_theme_manager.dart';

class PremiumView extends StatefulWidget {
  const PremiumView({super.key});

  @override
  State<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<PremiumView> {
  String _selectedPlan = 'Mensal'; // 'Mensal' or 'Anual'

  void _onAssinarPressed() {
    // Simular início do processo de assinatura
    AppThemeManager.instance.setPremiumUser(true);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Assinatura Iniciada', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'Você selecionou o $_selectedPlan.\n\nAgora você é um Usuário Premium! Aproveite todos os recursos exclusivos.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('VAMOS LÁ!'),
            ),
          ),
        ],
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
          backgroundColor: theme.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- HEADER ---
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 30,
                          color: Colors.black,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'Perfil Premium',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.workspace_premium,
                        color: Colors.amber,
                        size: 36,
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- TITLE & SUBTITLE ---
                  const Text(
                    'Experiência Premium: Segurança e Controle Total na Palma da Sua Mão!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'Atualize para o Perfil Premium e tenha acesso exclusivo a recursos avançados que garantem mais segurança, praticidade e uma experiência sem interrupções:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- BENEFITS CARD ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildBenefitItem(
                          'Monitoramento ao vivo: acompanhe em tempo real todas as câmeras da sua casa, onde e quando quiser, aumentando a segurança do idoso.',
                        ),
                        _buildBenefitItem(
                          'Acesso ao GPS: localize e rastreie os dispositivos utilizados pelo idoso com precisão para mais tranquilidade.',
                        ),
                        _buildBenefitItem(
                          'Zero anúncios: navegue sem distrações e aproveite uma experiência sem propagandas.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- PLANS SECTION ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlanCard(
                          title: 'Plano Mensal',
                          price: 'R\$19,90',
                          isSelected: _selectedPlan == 'Mensal',
                          onTap: () => setState(() => _selectedPlan = 'Mensal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPlanCard(
                          title: 'Plano Anual',
                          price: 'R\$189,90',
                          subtitle: '(economize mais de R\$40/ano)',
                          isSelected: _selectedPlan == 'Anual',
                          onTap: () => setState(() => _selectedPlan = 'Anual'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // --- MAIN ACTION BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onAssinarPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 8,
                        shadowColor: theme.primaryColor.withValues(alpha: 0.5),
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.buttonTextColor,
                      ),
                      child: const Text(
                        'Assinar Premium',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- FOOTER ---
                  const Text(
                    'Garanta agora mesmo o controle total do seu ambiente e tenha mais segurança!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = AppThemeManager.instance;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.cardSelectionColor
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.black12,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? theme.primaryColor : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isSelected ? theme.primaryColor : Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
