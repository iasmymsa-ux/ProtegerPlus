import 'dart:math';
import 'package:flutter/material.dart';

class CrosswordLevel {
  final List<List<String?>> solution;
  final List<String> clues;
  final Map<String, String> startLabels;

  CrosswordLevel({required this.solution, required this.clues, required this.startLabels});
}

class CrosswordView extends StatefulWidget {
  const CrosswordView({super.key});

  @override
  State<CrosswordView> createState() => _CrosswordViewState();
}

class _CrosswordViewState extends State<CrosswordView> {
  final List<CrosswordLevel> _levels = [
    CrosswordLevel(
      solution: [
        ['C', 'A', 'S', 'A'],
        [null, 'M', null, null],
        [null, 'O', null, null],
        [null, 'R', null, null],
      ],
      clues: [
        '1. Horizontal: Lugar onde moramos (4 letras)',
        '2. Vertical: Sentimento muito forte (4 letras)'
      ],
      startLabels: {'0,0': '1', '0,1': '2'}
    ),
    CrosswordLevel(
      solution: [
        ['V', 'I', 'D', 'A'],
        [null, 'D', null, null],
        [null, 'A', null, null],
        [null, null, null, null],
      ],
      clues: [
        '1. Horizontal: O oposto da morte (4 letras)',
        '2. Vertical: Viagem de ida e volta, caminho de __ (3 letras)'
      ],
      startLabels: {'0,0': '1', '0,1': '2'}
    ),
    CrosswordLevel(
      solution: [
        ['G', 'A', 'T', 'O'],
        ['A', null, null, null],
        ['L', null, null, null],
        ['O', null, null, null],
      ],
      clues: [
        '1. Horizontal: Animal de estimação que mia (4 letras)',
        '1. Vertical: Ave que canta de manhã (4 letras)'
      ],
      startLabels: {'0,0': '1'}
    ),
    CrosswordLevel(
      solution: [
        ['B', 'O', 'L', 'A'],
        ['O', null, null, null],
        ['L', null, null, null],
        ['O', null, null, null],
      ],
      clues: [
        '1. Horizontal: Objeto redondo usado em esportes (4 letras)',
        '1. Vertical: Doce servido em aniversários (4 letras)'
      ],
      startLabels: {'0,0': '1'}
    ),
    CrosswordLevel(
      solution: [
        ['P', 'A', 'T', 'O'],
        [null, null, null, 'U'],
        [null, null, null, 'R'],
        [null, null, null, 'O'],
      ],
      clues: [
        '1. Horizontal: Ave de bico achatado que gosta de água (4 letras)',
        '2. Vertical: Metal precioso e brilhante (4 letras)'
      ],
      startLabels: {'0,0': '1', '0,3': '2'}
    ),
  ];

  late CrosswordLevel _currentLevel;
  int _currentLevelIndex = -1;
  final Random _random = Random();

  late List<List<String>> _userInput;
  int? _selectedRow;
  int? _selectedCol;
  bool _isVictory = false;

  final String _alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    int nextLevel;
    do {
      nextLevel = _random.nextInt(_levels.length);
    } while (nextLevel == _currentLevelIndex && _levels.length > 1);

    _currentLevelIndex = nextLevel;
    _currentLevel = _levels[_currentLevelIndex];

    _userInput = List.generate(4, (_) => List.generate(4, (_) => ''));
    _selectedRow = null;
    _selectedCol = null;
    _isVictory = false;

    // Seleciona a primeira célula válida automaticamente
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_currentLevel.solution[r][c] != null) {
          _selectedRow = r;
          _selectedCol = c;
          break;
        }
      }
      if (_selectedRow != null) break;
    }

    setState(() {});
  }

  void _onCellTapped(int r, int c) {
    if (_currentLevel.solution[r][c] != null) {
      setState(() {
        _selectedRow = r;
        _selectedCol = c;
      });
    }
  }

  void _onKeyPress(String letter) {
    if (_selectedRow != null && _selectedCol != null && !_isVictory) {
      setState(() {
        _userInput[_selectedRow!][_selectedCol!] = letter;
      });
      _checkWin();
    }
  }

  void _checkWin() {
    bool win = true;
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_currentLevel.solution[r][c] != null) {
          if (_userInput[r][c] != _currentLevel.solution[r][c]) {
            win = false;
          }
        }
      }
    }
    if (win) {
      setState(() {
        _isVictory = true;
        _selectedRow = null;
        _selectedCol = null;
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Parabéns!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFC18AD1))),
          content: const Text('Você completou a cruzadinha com sucesso!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startRound();
              },
              style: ElevatedButton.styleFrom(
                
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Limpar e Tentar Novamente', style: TextStyle(color: Colors.white, fontSize: 16)),
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
          'Cruzadinha', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 24)
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Dicas
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _currentLevel.clues.map((clue) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      clue,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Grade Crossword
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (r) {
                        return Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (c) {
                              bool isCell = _currentLevel.solution[r][c] != null;
                              bool isSelected = _selectedRow == r && _selectedCol == c;
                              
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(2.0),
                                  child: isCell
                                      ? GestureDetector(
                                          onTap: () => _onCellTapped(r, c),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.yellow[200] : Colors.white,
                                              border: Border.all(color: isSelected ? Colors.orange : Colors.black, width: isSelected ? 3 : 1),
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 1))]
                                            ),
                                            child: Stack(
                                              children: [
                                                // Número da dica
                                                if (_currentLevel.startLabels['$r,$c'] != null)
                                                  Positioned(
                                                    top: 2, 
                                                    left: 4, 
                                                    child: Text(
                                                      _currentLevel.startLabels['$r,$c']!, 
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                                                    )
                                                  ),
                                                  
                                                // Letra do usuário
                                                Center(
                                                  child: Text(
                                                    _userInput[r][c],
                                                    style: TextStyle(
                                                      fontSize: 28, 
                                                      fontWeight: FontWeight.bold,
                                                      color: _isVictory ? Colors.green : Colors.black
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            
            // Teclado Customizado
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.white.withValues(alpha: 0.5),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _alphabet.split('').map((letter) {
                  return GestureDetector(
                    onTap: () => _onKeyPress(letter),
                    child: Container(
                      width: 40,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4C8A),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0, 2), blurRadius: 2)],
                      ),
                      child: Center(
                        child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
