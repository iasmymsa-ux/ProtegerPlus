import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/custom_logo.dart';
import 'login_view.dart';
import 'under_development_view.dart';

class InitialView extends StatefulWidget {
  const InitialView({super.key});

  @override
  State<InitialView> createState() => _InitialViewState();
}

class _InitialViewState extends State<InitialView> {
  final FlutterTts _flutterTts = FlutterTts();
  int _selectedButtonIndex = 0;

  final List<Map<String, dynamic>> _buttons = [
    {'text': 'Usuário', 'profile': 'Usuario'},
    {'text': 'Cuidador', 'profile': 'Cuidador'},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setPitch(1.0);
  }

  void _onMicTap() async {
    String text = _buttons[_selectedButtonIndex]['text'];
    await _flutterTts.speak(text);
    setState(() {
      _selectedButtonIndex = (_selectedButtonIndex + 1) % _buttons.length;
    });
  }

  void _onMicDoubleTap() {
    _handleButtonAction(_selectedButtonIndex);
  }

  void _handleButtonAction(int index) {
    if (_buttons[index]['profile'] != null) {
      _navigateToLogin(context, _buttons[index]['profile']);
    } else {
      _navigateToUnderDevelopment(context);
    }
  }

  void _navigateToLogin(BuildContext context, String profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginView(profile: profile),
      ),
    );
  }

  void _navigateToUnderDevelopment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UnderDevelopmentView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: _onMicTap,
                  onDoubleTap: _onMicDoubleTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C72AD).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Color(0xFF9C72AD),
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const CustomLogo(size: 250),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: List.generate(_buttons.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildButton(
                      context,
                      _buttons[index]['text'],
                      () => _handleButtonAction(index),
                      isSelectedIdx: index == _selectedButtonIndex,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    bool isSelectedIdx = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          border: isSelectedIdx
              ? Border.all(color: Colors.white, width: 4)
              : null,
          boxShadow: isSelectedIdx
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: isSelectedIdx ? 0 : 4,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
