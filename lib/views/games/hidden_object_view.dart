import 'dart:math';
import 'package:flutter/material.dart';

class HiddenObjectView extends StatefulWidget {
  const HiddenObjectView({super.key});

  @override
  State<HiddenObjectView> createState() => _HiddenObjectViewState();
}

class HiddenItem {
  final IconData icon;
  final Color color;
  final Alignment alignment;
  final double size;
  bool isFound;

  HiddenItem({
    required this.icon,
    required this.color,
    required this.alignment,
    required this.size,
    this.isFound = false,
  });
}

class _HiddenObjectViewState extends State<HiddenObjectView> {
  final Random _random = Random();
  late List<HiddenItem> _items;
  late HiddenItem _targetItem;
  int _score = 0;
  final int _maxScore = 5;

  final List<IconData> _possibleIcons = [
    Icons.favorite, Icons.star, Icons.pets, Icons.directions_car, 
    Icons.wb_sunny, Icons.music_note, Icons.umbrella, Icons.cake,
    Icons.local_florist, Icons.anchor, Icons.sports_soccer, Icons.airplanemode_active,
  ];

  final List<Color> _possibleColors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange, 
    Colors.purple, Colors.teal, Colors.pink, Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    _items = [];
    int itemCount = 30 + (_score * 5); // Aumenta a dificuldade
    
    for (int i = 0; i < itemCount; i++) {
      _items.add(HiddenItem(
        icon: _possibleIcons[_random.nextInt(_possibleIcons.length)],
        color: _possibleColors[_random.nextInt(_possibleColors.length)],
        alignment: Alignment(
          (_random.nextDouble() * 2) - 1, // -1 a 1
          (_random.nextDouble() * 2) - 1, // -1 a 1
        ),
        size: 30.0 + _random.nextInt(30), // 30 a 60
      ));
    }

    // Escolhe um alvo único
    _targetItem = _items[_random.nextInt(_items.length)];
    setState(() {});
  }

  void _onItemTapped(HiddenItem item) {
    if (item == _targetItem) {
      setState(() {
        item.isFound = true;
        _score++;
      });

      if (_score >= _maxScore) {
        _showVictoryDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Muito bem! Você achou.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          )
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _startRound();
        });
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ainda não é esse! Continue procurando.', style: TextStyle(fontSize: 16)),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          )
        );
    }
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Parabéns!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFC18AD1))),
        content: const Text('Você completou todas as fases com atenção excelente!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _score = 0;
              });
              _startRound();
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
          'Ache o Objeto', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 24)
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Text('ENCONTRE:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(_targetItem.icon, color: _targetItem.color, size: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Fase: $_score / $_maxScore', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1DBED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: _items.map((item) {
                      return Align(
                        alignment: item.alignment,
                        child: GestureDetector(
                          onTap: () => _onItemTapped(item),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            transform: item.isFound ? Matrix4.diagonal3Values(1.5, 1.5, 1.0) : Matrix4.identity(),
                            child: Icon(
                              item.icon,
                              color: item.isFound ? Colors.yellow : item.color,
                              size: item.size,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
