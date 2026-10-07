import 'package:flutter/material.dart';

class UnderDevelopmentView extends StatelessWidget {
  const UnderDevelopmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Em desenvolvimento'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).primaryColor, // Botão de voltar roxo
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Logo in the background (watermark)
          Center(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/logo.png',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Main text
          const Center(
            child: Text(
              'Tela em desenvolvimento',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900, // Black bold text
                color: Colors.black87,
              ),
            ),
          ),
          // Bottom text
          const Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Text(
              'ASS: Equipe Proteger+',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B3B63),
              ),
            ),
          ),
          // Voltar ao Menu button
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Voltar ao Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
