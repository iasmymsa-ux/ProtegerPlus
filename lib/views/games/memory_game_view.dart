import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MemoryCardTheme {
  final String name;
  final Color themeColor;
  final List<IconData> icons;

  const MemoryCardTheme({
    required this.name,
    required this.themeColor,
    required this.icons,
  });
}

class MemoryGameView extends StatefulWidget {
  const MemoryGameView({super.key});

  @override
  State<MemoryGameView> createState() => _MemoryGameViewState();
}

class _MemoryGameViewState extends State<MemoryGameView> {
  final Random _random = Random();

  final List<MemoryCardTheme> _themes = const [
    MemoryCardTheme(
      name: 'Animais e Pets',
      themeColor: Colors.deepPurple,
      icons: [
        Icons.pets,
        Icons.cruelty_free,
        Icons.flutter_dash,
        Icons.phishing,
        Icons.bug_report,
        Icons.pest_control_rodent,
        Icons.savings,
        Icons.catching_pokemon,
      ],
    ),
    MemoryCardTheme(
      name: 'Frutas e Doces',
      themeColor: Colors.pink,
      icons: [
        Icons.cake,
        Icons.coffee,
        Icons.icecream,
        Icons.lunch_dining,
        Icons.local_pizza,
        Icons.apple,
        Icons.egg_alt,
        Icons.cookie,
      ],
    ),
    MemoryCardTheme(
      name: 'Natureza e Céu',
      themeColor: Colors.teal,
      icons: [
        Icons.wb_sunny,
        Icons.nightlight_round,
        Icons.star,
        Icons.local_florist,
        Icons.park,
        Icons.cloud,
        Icons.water_drop,
        Icons.local_fire_department,
      ],
    ),
    MemoryCardTheme(
      name: 'Música e Diversão',
      themeColor: Colors.indigo,
      icons: [
        Icons.music_note,
        Icons.headphones,
        Icons.mic,
        Icons.piano,
        Icons.radio,
        Icons.speaker,
        Icons.videogame_asset,
        Icons.sports_soccer,
      ],
    ),
    MemoryCardTheme(
      name: 'Viagens e Transportes',
      themeColor: Colors.blueAccent,
      icons: [
        Icons.directions_car,
        Icons.airplanemode_active,
        Icons.directions_boat,
        Icons.pedal_bike,
        Icons.train,
        Icons.rocket_launch,
        Icons.directions_bus,
        Icons.motorcycle,
      ],
    ),
  ];

  late MemoryCardTheme _currentTheme;
  late List<IconData> _cards;
  late List<bool> _isFlipped;
  late List<bool> _isMatched;

  int? _previousIndex;
  bool _isProcessing = false;
  int _tentativas = 0;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    // Sorteia um tema novo para sempre atualizar
    _currentTheme = _themes[_random.nextInt(_themes.length)];
    final List<IconData> shuffledIcons = List<IconData>.from(_currentTheme.icons)..shuffle();
    final List<IconData> selected8 = shuffledIcons.take(8).toList();

    setState(() {
      _cards = List<IconData>.from(selected8)..addAll(selected8);
      _cards.shuffle();
      _isFlipped = List<bool>.filled(16, false);
      _isMatched = List<bool>.filled(16, false);
      _previousIndex = null;
      _isProcessing = false;
      _tentativas = 0;
    });
  }

  void _onCardTap(int index) {
    if (_isProcessing || _isFlipped[index] || _isMatched[index]) return;

    setState(() {
      _isFlipped[index] = true;
    });

    if (_previousIndex == null) {
      _previousIndex = index;
    } else {
      _tentativas++;
      _isProcessing = true;
      Timer(const Duration(milliseconds: 700), () {
        if (_cards[_previousIndex!] == _cards[index]) {
          setState(() {
            _isMatched[_previousIndex!] = true;
            _isMatched[index] = true;
          });
          _checkWin();
        } else {
          setState(() {
            _isFlipped[_previousIndex!] = false;
            _isFlipped[index] = false;
          });
        }
        _previousIndex = null;
        _isProcessing = false;
      });
    }
  }

  void _checkWin() {
    if (_isMatched.every((matched) => matched)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '🎉 Parabéns!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFC18AD1)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Você encontrou todos os 8 pares do tema "${_currentTheme.name}" em $_tentativas tentativas!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 12),
              const Text(
                'Excelente memória e foco mental!',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startNewGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC18AD1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Jogar com Novo Tema', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int paresEncontrados = _isMatched.where((m) => m).length ~/ 2;

    return Scaffold(
      backgroundColor: const Color(0xFFE4B1FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jogo da Memória',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: 'Atualizar / Trocar Tema',
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Placar e Tema Atual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TEMA ATUAL:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      Text(
                        _currentTheme.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _currentTheme.themeColor),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Pares: $paresEncontrados / 8',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                      Text(
                        'Tentativas: $_tentativas',
                        style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Grade das Cartas 4x4
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    final bool isFaceUp = _isFlipped[index] || _isMatched[index];
                    return GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: isFaceUp
                            ? Container(
                                key: ValueKey('up_$index'),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isMatched[index] ? Colors.green : _currentTheme.themeColor,
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    _cards[index],
                                    size: 38,
                                    color: _isMatched[index] ? Colors.green : _currentTheme.themeColor,
                                  ),
                                ),
                              )
                            : Container(
                                key: ValueKey('down_$index'),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC18AD1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.help_outline,
                                    size: 32,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Botão para atualizar cartas/tema
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: OutlinedButton.icon(
                onPressed: _startNewGame,
                icon: const Icon(Icons.shuffle, color: Colors.black87),
                label: const Text(
                  'Atualizar Cartas / Novo Tema',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
