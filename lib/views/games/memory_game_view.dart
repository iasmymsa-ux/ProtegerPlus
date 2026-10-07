import 'dart:async';
import 'package:flutter/material.dart';

class MemoryGameView extends StatefulWidget {
  const MemoryGameView({super.key});

  @override
  State<MemoryGameView> createState() => _MemoryGameViewState();
}

class _MemoryGameViewState extends State<MemoryGameView> {
  final List<IconData> _iconSet = [
    Icons.favorite,
    Icons.star,
    Icons.pets,
    Icons.wb_sunny,
    Icons.local_florist,
    Icons.music_note,
    Icons.directions_car,
    Icons.flight,
  ];

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
    setState(() {
      _cards = List<IconData>.from(_iconSet)..addAll(_iconSet);
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
      Timer(const Duration(milliseconds: 800), () {
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
          title: const Text('Parabéns!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFC18AD1))),
          content: Text('Você encontrou todos os pares em $_tentativas tentativas!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startNewGame();
              },
              style: ElevatedButton.styleFrom(
                
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Jogar Novamente', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jogo da Memória', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 24)
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'Tentativas: $_tentativas',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
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
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: isFaceUp
                          ? Container(
                              key: const ValueKey(true),
                              decoration: BoxDecoration(
                                color: _isMatched[index] ? Colors.green[200] : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(2, 2))]
                              ),
                              child: Center(
                                child: Icon(_cards[index], size: 40, color: const Color(0xFFC18AD1)),
                              ),
                            )
                          : Container(
                              key: const ValueKey(false),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C72AD),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(2, 2))]
                              ),
                              child: const Center(
                                child: Icon(Icons.help_outline, size: 36, color: Colors.white70),
                              ),
                            ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton.icon(
                onPressed: _startNewGame,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Reiniciar Jogo', style: TextStyle(color: Colors.white, fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
