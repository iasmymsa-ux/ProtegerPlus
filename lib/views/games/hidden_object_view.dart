import 'dart:math';
import 'package:flutter/material.dart';

class ObjectDefinition {
  final IconData icon;
  final String name;

  const ObjectDefinition(this.icon, this.name);
}

class HiddenItem {
  final IconData icon;
  final Color color;
  final String name;
  final Alignment alignment;
  final double size;
  bool isFound;

  HiddenItem({
    required this.icon,
    required this.color,
    required this.name,
    required this.alignment,
    required this.size,
    this.isFound = false,
  });
}

class HiddenObjectView extends StatefulWidget {
  const HiddenObjectView({super.key});

  @override
  State<HiddenObjectView> createState() => _HiddenObjectViewState();
}

class _HiddenObjectViewState extends State<HiddenObjectView> {
  final Random _random = Random();
  late List<HiddenItem> _items;
  late HiddenItem _targetItem;
  int _score = 0;
  final int _maxScore = 5;
  int _tentativasRestantes = 5;

  final List<ObjectDefinition> _objectDefs = const [
    ObjectDefinition(Icons.favorite, 'Coração'),
    ObjectDefinition(Icons.star, 'Estrela'),
    ObjectDefinition(Icons.pets, 'Patinha'),
    ObjectDefinition(Icons.directions_car, 'Carro'),
    ObjectDefinition(Icons.wb_sunny, 'Sol'),
    ObjectDefinition(Icons.music_note, 'Nota Musical'),
    ObjectDefinition(Icons.umbrella, 'Guarda-chuva'),
    ObjectDefinition(Icons.cake, 'Bolo'),
    ObjectDefinition(Icons.local_florist, 'Flor'),
    ObjectDefinition(Icons.anchor, 'Âncora'),
    ObjectDefinition(Icons.sports_soccer, 'Bola'),
    ObjectDefinition(Icons.airplanemode_active, 'Avião'),
    ObjectDefinition(Icons.lightbulb, 'Lâmpada'),
    ObjectDefinition(Icons.key, 'Chave'),
    ObjectDefinition(Icons.coffee, 'Xícara de Café'),
    ObjectDefinition(Icons.apple, 'Maçã'),
  ];

  final List<Color> _colors = const [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  final List<Color> _backgroundColors = [
    const Color(0xFFF3E5F5), // Lilás suave
    const Color(0xFFE8F5E9), // Verde jardim
    const Color(0xFFE1F5FE), // Azul céu
    const Color(0xFFFFF3E0), // Laranja pôr do sol
    const Color(0xFFFCE4EC), // Rosa algodão
  ];

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    _items = [];
    _tentativasRestantes = 5;
    final int itemCount = 32 + (_score * 4);

    // Gera lista de objetos variados
    for (int i = 0; i < itemCount; i++) {
      final def = _objectDefs[_random.nextInt(_objectDefs.length)];
      final color = _colors[_random.nextInt(_colors.length)];
      _items.add(HiddenItem(
        icon: def.icon,
        name: def.name,
        color: color,
        alignment: Alignment(
          (_random.nextDouble() * 1.8) - 0.9,
          (_random.nextDouble() * 1.8) - 0.9,
        ),
        size: 38.0 + _random.nextInt(26),
      ));
    }

    // Escolhe um alvo garantido na cena
    _targetItem = _items[_random.nextInt(_items.length)];
    setState(() {});
  }

  void _onItemTapped(HiddenItem item) {
    // Comparação por tipo de ícone e cor (não por referência de memória)
    final bool isCorrect = item.icon == _targetItem.icon && item.color == _targetItem.color;

    if (isCorrect) {
      setState(() {
        item.isFound = true;
        _score++;
      });

      if (_score >= _maxScore) {
        _showVictoryDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Muito bem! Você encontrou o ${_targetItem.name}!',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _startRound();
        });
      }
    } else {
      setState(() {
        _tentativasRestantes--;
      });

      if (_tentativasRestantes <= 0) {
        _showGameOverDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ainda não é esse! Procure: ${_targetItem.name} ($_tentativasRestantes tentativas restantes)',
              style: const TextStyle(fontSize: 15),
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Fim das Tentativas!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        content: Text(
          'O objeto era: ${_targetItem.name}.\nVamos tentar novamente com um novo cenário!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startRound();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC18AD1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Tentar de Novo', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showVictoryDialog() {
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
        content: const Text(
          'Você encontrou todos os objetos e completou todas as fases com excelente atenção visual!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
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
              backgroundColor: const Color(0xFFC18AD1),
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
    final bgColor = _backgroundColors[_score % _backgroundColors.length];

    return Scaffold(
      backgroundColor: const Color(0xFFDABDFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ache o Objeto',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: 'Trocar Objeto / Novo Cenário',
            onPressed: _startRound,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Placar e tentativas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fase: ${_score + 1} de $_maxScore',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Tentativas: ',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < _tentativasRestantes ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cartão de instruções destacando o objeto alvo
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                ],
                border: Border.all(color: _targetItem.color, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _targetItem.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _targetItem.icon,
                      color: _targetItem.color,
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ENCONTRE NA TELA:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        Text(
                          _targetItem.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _targetItem.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Área do jogo com os itens espalhados
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    children: _items.map((item) {
                      return Align(
                        alignment: item.alignment,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onItemTapped(item),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              item.icon,
                              color: item.color,
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

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
