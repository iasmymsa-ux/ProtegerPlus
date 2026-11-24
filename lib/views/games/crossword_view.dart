import 'package:flutter/material.dart';

class CrosswordLevel {
  final String title;
  final List<List<String?>> solution;
  final List<String> clues;
  final Map<String, String> startLabels;

  CrosswordLevel({
    required this.title,
    required this.solution,
    required this.clues,
    required this.startLabels,
  });
}

class CrosswordView extends StatefulWidget {
  const CrosswordView({super.key});

  @override
  State<CrosswordView> createState() => _CrosswordViewState();
}

class _CrosswordViewState extends State<CrosswordView> {
  final List<CrosswordLevel> _levels = [
    CrosswordLevel(
      title: 'Lar e Sentimento',
      solution: [
        ['C', 'A', 'S', 'A'],
        [null, 'M', null, null],
        [null, 'O', null, null],
        [null, 'R', null, null],
      ],
      clues: [
        '1. Horizontal: Lugar onde moramos e descansamos (4 letras)',
        '2. Vertical: O sentimento mais nobre e forte (4 letras)',
      ],
      startLabels: {'0,0': '1', '0,1': '2'},
    ),
    CrosswordLevel(
      title: 'Caminhos',
      solution: [
        ['V', 'I', 'D', 'A'],
        [null, 'D', null, null],
        [null, 'A', null, null],
        [null, null, null, null],
      ],
      clues: [
        '1. Horizontal: O maior presente que recebemos (4 letras)',
        '2. Vertical: Caminho de ida e de... (3 letras)',
      ],
      startLabels: {'0,0': '1', '0,1': '2'},
    ),
    CrosswordLevel(
      title: 'Animais da Fazenda',
      solution: [
        ['G', 'A', 'T', 'O'],
        ['A', null, null, null],
        ['L', null, null, null],
        ['O', null, null, null],
      ],
      clues: [
        '1. Horizontal: Animal doméstico que mia (4 letras)',
        '1. Vertical: Ave que canta ao nascer do sol (4 letras)',
      ],
      startLabels: {'0,0': '1'},
    ),
    CrosswordLevel(
      title: 'Festa e Brincadeira',
      solution: [
        ['B', 'O', 'L', 'A'],
        ['O', null, null, null],
        ['L', null, null, null],
        ['O', null, null, null],
      ],
      clues: [
        '1. Horizontal: Objeto redondo para jogar futebol (4 letras)',
        '1. Vertical: Doce saboroso de aniversário (4 letras)',
      ],
      startLabels: {'0,0': '1'},
    ),
    CrosswordLevel(
      title: 'Lago e Riqueza',
      solution: [
        ['P', 'A', 'T', 'O'],
        [null, null, null, 'U'],
        [null, null, null, 'R'],
        [null, null, null, 'O'],
      ],
      clues: [
        '1. Horizontal: Ave que nada na lagoa e faz quá-quá (4 letras)',
        '2. Vertical: Metal precioso e brilhante (4 letras)',
      ],
      startLabels: {'0,0': '1', '0,3': '2'},
    ),
    CrosswordLevel(
      title: 'Café da Manhã',
      solution: [
        ['C', 'A', 'F', 'E'],
        ['H', null, null, null],
        ['A', null, null, null],
        [null, null, null, null],
      ],
      clues: [
        '1. Horizontal: Bebida quente tradicional brasileira (4 letras)',
        '1. Vertical: Infusão de ervas quente e relaxante (3 letras)',
      ],
      startLabels: {'0,0': '1'},
    ),
    CrosswordLevel(
      title: 'Céu e Luz',
      solution: [
        ['S', 'O', 'L', null],
        [null, null, 'U', null],
        [null, null, 'A', null],
        [null, null, null, null],
      ],
      clues: [
        '1. Horizontal: Astro que ilumina o nosso dia (3 letras)',
        '2. Vertical: Rainha do céu noturno (3 letras)',
      ],
      startLabels: {'0,0': '1', '0,2': '2'},
    ),
    CrosswordLevel(
      title: 'Natureza e Jardim',
      solution: [
        ['R', 'O', 'S', 'A'],
        ['I', null, null, null],
        ['O', null, null, null],
        [null, null, null, null],
      ],
      clues: [
        '1. Horizontal: Flor perfumada com espinhos (4 letras)',
        '1. Vertical: Curso natural de água doce (3 letras)',
      ],
      startLabels: {'0,0': '1'},
    ),
    CrosswordLevel(
      title: 'Águas e Oceano',
      solution: [
        ['M', 'A', 'R', null],
        [null, null, 'I', null],
        [null, null, 'O', null],
        [null, null, null, null],
      ],
      clues: [
        '1. Horizontal: Grande extensão de água salgada (3 letras)',
        '2. Vertical: Deságua no mar (3 letras)',
      ],
      startLabels: {'0,0': '1', '0,2': '2'},
    ),
    CrosswordLevel(
      title: 'Padaria e Forno',
      solution: [
        ['P', 'A', 'O', null],
        ['I', null, null, null],
        ['A', null, null, null],
        [null, null, null, null],
      ],
      clues: [
        '1. Horizontal: Alimento quentinho que compramos na padaria (3 letras)',
        '1. Vertical: Onde lavamos a louça na cozinha (3 letras)',
      ],
      startLabels: {'0,0': '1'},
    ),
    CrosswordLevel(
      title: 'Amor de Família',
      solution: [
        ['A', 'M', 'O', 'R'],
        [null, 'A', null, null],
        [null, 'E', null, null],
        [null, null, null, null],
      ],
      clues: [
        '1. Horizontal: Sentimento de afeto profundo (4 letras)',
        '2. Vertical: Mulher carinhosa que nos deu à luz (3 letras)',
      ],
      startLabels: {'0,0': '1', '0,1': '2'},
    ),
    CrosswordLevel(
      title: 'Cores e Harmonia',
      solution: [
        ['A', 'Z', 'U', 'L'],
        [null, 'E', null, null],
        [null, 'R', null, null],
        [null, 'O', null, null],
      ],
      clues: [
        '1. Horizontal: A cor do céu limpo (4 letras)',
        '2. Vertical: Número que representa o nada (4 letras)',
      ],
      startLabels: {'0,0': '1', '0,1': '2'},
    ),
    CrosswordLevel(
      title: 'Pomar de Frutas',
      solution: [
        ['U', 'V', 'A', null],
        [null, 'E', null, null],
        [null, 'R', null, null],
        [null, 'A', null, null],
      ],
      clues: [
        '1. Horizontal: Fruta roxa ou verde que dá em cachos (3 letras)',
        '2. Vertical: Fruta doce com formato arredondado na base (4 letras)',
      ],
      startLabels: {'0,0': '1', '0,1': '2'},
    ),
    CrosswordLevel(
      title: 'Animais Companheiros',
      solution: [
        ['C', 'A', 'O', null],
        ['A', null, null, null],
        ['S', null, null, null],
        ['A', null, null, null],
      ],
      clues: [
        '1. Horizontal: O melhor amigo do homem que late (3 letras)',
        '1. Vertical: Moradia e abrigo familiar (4 letras)',
      ],
      startLabels: {'0,0': '1'},
    ),
    CrosswordLevel(
      title: 'Tempo e Clima',
      solution: [
        ['D', 'I', 'A', null],
        ['O', null, null, null],
        ['C', null, null, null],
        ['E', null, null, null],
      ],
      clues: [
        '1. Horizontal: Período iluminado pelo sol (3 letras)',
        '1. Vertical: Alimento com açúcar que agrada o paladar (4 letras)',
      ],
      startLabels: {'0,0': '1'},
    ),
  ];

  late CrosswordLevel _currentLevel;
  int _currentLevelIndex = 0;

  late List<List<String>> _userInput;
  int? _selectedRow;
  int? _selectedCol;
  bool _isVictory = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(_currentLevelIndex);
  }

  void _loadLevel(int index) {
    _currentLevelIndex = index.clamp(0, _levels.length - 1);
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

  void _nextLevel() {
    int next = (_currentLevelIndex + 1) % _levels.length;
    _loadLevel(next);
  }

  void _previousLevel() {
    int prev = (_currentLevelIndex - 1 + _levels.length) % _levels.length;
    _loadLevel(prev);
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

  void _onBackspace() {
    if (_selectedRow != null && _selectedCol != null && !_isVictory) {
      setState(() {
        _userInput[_selectedRow!][_selectedCol!] = '';
      });
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
          title: const Text(
            '🎉 Parabéns!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFC18AD1)),
          ),
          content: Text(
            'Você completou a cruzadinha "${_currentLevel.title}" com sucesso!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _nextLevel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC18AD1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Próxima Cruzadinha', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD49FE9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cruzadinha',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de navegação entre cruzadinhas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                    tooltip: 'Cruzadinha Anterior',
                    onPressed: _previousLevel,
                  ),
                  Column(
                    children: [
                      Text(
                        'Cruzadinha ${_currentLevelIndex + 1} de ${_levels.length}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        _currentLevel.title,
                        style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.black87),
                    tooltip: 'Próxima Cruzadinha',
                    onPressed: _nextLevel,
                  ),
                ],
              ),
            ),

            // Dicas
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _currentLevel.clues.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    c,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                )).toList(),
              ),
            ),

            // Grade 4x4
            Expanded(
              flex: 5,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: 16,
                      itemBuilder: (context, index) {
                        int r = index ~/ 4;
                        int c = index % 4;
                        bool isValid = _currentLevel.solution[r][c] != null;
                        bool isSelected = _selectedRow == r && _selectedCol == c;
                        String? label = _currentLevel.startLabels['$r,$c'];

                        if (!isValid) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }

                        return GestureDetector(
                          onTap: () => _onCellTapped(r, c),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFC18AD1) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.purple : Colors.grey.shade400,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
                              ],
                            ),
                            child: Stack(
                              children: [
                                if (label != null)
                                  Positioned(
                                    top: 2,
                                    left: 4,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: Text(
                                    _userInput[r][c],
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Teclado Virtual
            Container(
              padding: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0, top: 4.0),
              child: Column(
                children: [
                  _buildKeyboardRow("QWERTYUIOP"),
                  const SizedBox(height: 4),
                  _buildKeyboardRow("ASDFGHJKL"),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildKeyButton('←', isBackspace: true),
                      const SizedBox(width: 4),
                      ... "ZXCVBNM".split('').map((l) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: _buildKeyButton(l),
                      )),
                      const SizedBox(width: 4),
                      _buildKeyButton('DEL', isBackspace: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(String letters) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters.split('').map((l) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: _buildKeyButton(l),
      )).toList(),
    );
  }

  Widget _buildKeyButton(String label, {bool isBackspace = false}) {
    return SizedBox(
      width: isBackspace ? 44 : 32,
      height: 42,
      child: ElevatedButton(
        onPressed: () {
          if (isBackspace) {
            _onBackspace();
          } else {
            _onKeyPress(label);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isBackspace ? Colors.red.shade400 : Colors.white,
          foregroundColor: isBackspace ? Colors.white : Colors.black87,
          elevation: 2,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isBackspace ? 13 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
