import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class BingoView extends StatefulWidget {
  const BingoView({super.key});

  @override
  State<BingoView> createState() => _BingoViewState();
}

class _BingoViewState extends State<BingoView> {
  final Random _random = Random();
  late List<List<int>> _board;
  late List<List<bool>> _marked;
  late List<int> _availableNumbers;
  List<int> _drawnNumbers = [];
  int? _lastDrawn;
  bool _bingo = false;
  
  Timer? _autoDrawTimer;
  bool _isAutoDrawing = false;

  final List<String> _letters = ['B', 'I', 'N', 'G', 'O'];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }
  
  @override
  void dispose() {
    _autoDrawTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _autoDrawTimer?.cancel();
    _availableNumbers = List.generate(75, (index) => index + 1);
    _drawnNumbers = [];
    _lastDrawn = null;
    _bingo = false;
    _isAutoDrawing = false;
    _marked = List.generate(5, (_) => List.filled(5, false));
    _board = List.generate(5, (_) => List.filled(5, 0));

    // Fill columns
    for (int col = 0; col < 5; col++) {
      int min = col * 15 + 1;
      List<int> colNums = List.generate(15, (index) => min + index);
      colNums.shuffle();
      for (int row = 0; row < 5; row++) {
        if (col == 2 && row == 2) {
          _board[row][col] = 0; // FREE SPACE
          _marked[row][col] = true;
        } else {
          _board[row][col] = colNums[row];
        }
      }
    }
    setState(() {});
  }
  
  void _toggleAutoDraw() {
    if (_isAutoDrawing) {
      _autoDrawTimer?.cancel();
      setState(() {
        _isAutoDrawing = false;
      });
    } else {
      setState(() {
        _isAutoDrawing = true;
      });
      // Sortear o primeiro instantaneamente
      _drawNumber();
      // Configurar o intervalo (ex: a cada 4 segundos)
      _autoDrawTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        _drawNumber();
      });
    }
  }

  void _drawNumber() {
    if (_availableNumbers.isEmpty || _bingo) {
      _autoDrawTimer?.cancel();
      setState(() {
        _isAutoDrawing = false;
      });
      return;
    }
    
    int index = _random.nextInt(_availableNumbers.length);
    int num = _availableNumbers.removeAt(index);
    setState(() {
      _lastDrawn = num;
      _drawnNumbers.add(num);
    });
  }

  void _onCellTapped(int row, int col) {
    if (_bingo || _board[row][col] == 0) return; // Free space or game over
    
    int num = _board[row][col];
    if (_drawnNumbers.contains(num)) {
      setState(() {
        _marked[row][col] = !_marked[row][col];
      });
      _checkWin();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este número ainda não foi sorteado!', style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        )
      );
    }
  }

  void _checkWin() {
    bool isWin = false;

    // Horizontal & Vertical
    for (int i = 0; i < 5; i++) {
      bool rowWin = true;
      bool colWin = true;
      for (int j = 0; j < 5; j++) {
        if (!_marked[i][j]) rowWin = false;
        if (!_marked[j][i]) colWin = false;
      }
      if (rowWin || colWin) isWin = true;
    }

    // Diagnonals
    bool diag1 = true;
    bool diag2 = true;
    for (int i = 0; i < 5; i++) {
      if (!_marked[i][i]) diag1 = false;
      if (!_marked[i][4 - i]) diag2 = false;
    }
    if (diag1 || diag2) isWin = true;

    if (isWin) {
      _autoDrawTimer?.cancel();
      setState(() {
        _bingo = true;
        _isAutoDrawing = false;
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('B I N G O !', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
          content: const Text('Você completou uma linha e venceu!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
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
          'BINGO', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 24, letterSpacing: 2)
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header Bingo Letras
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _letters.map((l) => SizedBox(
                  width: 50, 
                  child: Center(child: Text(l, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87)))
                )).toList(),
              ),
            ),
            
            // Cartela
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE27C4E), width: 4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (row) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (col) {
                          bool isFree = row == 2 && col == 2;
                          bool isMarked = _marked[row][col];
                          
                          return GestureDetector(
                            onTap: () => _onCellTapped(row, col),
                            child: Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: isMarked ? const Color(0xFFC0AEEB) : Colors.white,
                                border: Border.all(color: Colors.black12, width: 2),
                                shape: BoxShape.circle,
                                boxShadow: isMarked ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
                              ),
                              child: Center(
                                child: isFree
                                  ? const Icon(Icons.star, color: Colors.amber, size: 30)
                                  : Text(
                                      '${_board[row][col]}',
                                      style: TextStyle(
                                        fontSize: 22, 
                                        fontWeight: FontWeight.bold,
                                        color: isMarked ? Colors.white : Colors.black87
                                      ),
                                    ),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
            
            // Sorteio
            Container(
              margin: const EdgeInsets.all(20.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text('NÚMERO SORTEADO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE27C4E),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(2, 2))],
                    ),
                    child: Center(
                      child: Text(
                        _lastDrawn != null ? '$_lastDrawn' : '--',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _toggleAutoDraw,
                      icon: Icon(_isAutoDrawing ? Icons.pause : Icons.play_arrow, size: 30, color: Colors.white),
                      label: Text(_isAutoDrawing ? 'PAUSAR SORTEIO' : 'INICIAR SORTEIO (4s)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAutoDrawing ? Colors.redAccent : const Color(0xFF6B4C8A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
