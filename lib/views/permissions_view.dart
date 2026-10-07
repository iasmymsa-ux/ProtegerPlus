import 'package:flutter/material.dart';
import '../widgets/custom_logo.dart';
import 'home_view.dart';
import 'cuidador_home_view.dart';

class PermissionsView extends StatefulWidget {
  final String profile;
  const PermissionsView({super.key, required this.profile});

  @override
  State<PermissionsView> createState() => _PermissionsViewState();
}

class _PermissionsViewState extends State<PermissionsView> {
  bool _dadosPessoais = false;
  bool _notificacoes = false;

  void _navigateToHome(BuildContext context) {
    final destination = widget.profile == 'Cuidador' 
        ? const CuidadorHomeView() 
        : const HomeView();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF9C72AD)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Center(child: CustomLogo(size: 220)),
              const SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF9C72AD),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Permissão de uso de dados',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildCheckboxItem(
                'Permitir o uso de dados pessoais',
                _dadosPessoais,
                (val) {
                  setState(() => _dadosPessoais = val!);
                },
              ),
              const SizedBox(height: 16),
              _buildCheckboxItem('Permitir notificações', _notificacoes, (val) {
                setState(() => _notificacoes = val!);
              }),

              const SizedBox(height: 60),

              ElevatedButton(
                onPressed: () => _navigateToHome(context),
                style: ElevatedButton.styleFrom(
                  
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxItem(
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.3,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF9C72AD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF9C72AD),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
