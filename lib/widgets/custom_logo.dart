import 'package:flutter/material.dart';

class CustomLogo extends StatelessWidget {
  final double size;
  const CustomLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        const Text(
          'Proteger+',
          style: TextStyle(
            color: Color(0xFF9C72AD),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
