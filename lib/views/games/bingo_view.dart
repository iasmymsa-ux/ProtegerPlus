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
  // Cartela de 15 números: 3 linhas x 5 colunas
  late List<List<int>> _cartela;
  late List<List<bool>> _marcados;
  late List<int> _numerosDisponiveis;
  List<int> _sorteados = [];
  int? _ultimoSorteado;
  bool _bingo = false;

  Timer? _autoDrawTimer;
  bool _isAutoDrawing = false;

  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _iniciarNovoJogo();
  }

  @override
  void dispose() {
    _autoDrawTimer?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  void _iniciarNovoJogo() {
    _autoDrawTimer?.cancel();
    // 90 bolas do bingo tradicional
    _numerosDisponiveis = List.generate(90, (index) => index + 1);
    _sorteados = [];
    _ultimoSorteado = null;
    _bingo = false;
    _isAutoDrawing = false;

    // Gera 15 números únicos e ordenados para a cartela
    final List<int> pool15 = List.generate(90, (i) => i + 1)..shuffle();
    final List<int> quinzeNumeros = pool15.take(15).toList()..sort();

    _cartela = List.generate(3, (r) => List.generate(5, (c) => quinzeNumeros[r * 5 + c]));
    _marcados = List.generate(3, (_) => List.filled(5, false));

    setState(() {});
  }

  void _sortearNumero() {
    if (_numerosDisponiveis.isEmpty || _bingo) {
      _autoDrawTimer?.cancel();
      setState(() => _isAutoDrawing = false);
      return;
    }

    final int index = _random.nextInt(_numerosDisponiveis.length);
    final int numero = _numerosDisponiveis.removeAt(index);

    setState(() {
      _ultimoSorteado = numero;
      _sorteados.insert(0, numero); // Insere no início para o log mostrar o mais recente
    });

    // Auto-scroll do log
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    // Verifica se algum número da cartela coincide e se completou os 15
    _verificarSeMarcaAutomaticoOuAvisa(numero);
  }

  void _toggleAutoDraw() {
    if (_isAutoDrawing) {
      _autoDrawTimer?.cancel();
      setState(() => _isAutoDrawing = false);
    } else {
      setState(() => _isAutoDrawing = true);
      _sortearNumero();
      _autoDrawTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _sortearNumero();
      });
    }
  }

  void _verificarSeMarcaAutomaticoOuAvisa(int numero) {
    bool contemNaCartela = false;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 5; c++) {
        if (_cartela[r][c] == numero) {
          contemNaCartela = true;
          break;
        }
      }
    }

    if (contemNaCartela) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔔 O número $numero está na sua cartela! Toque nele para marcar.',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onCellTapped(int row, int col) {
    if (_bingo) return;
    final int num = _cartela[row][col];

    if (_sorteados.contains(num)) {
      setState(() {
        _marcados[row][col] = !_marcados[row][col];
      });
      _checkWin();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'O número $num ainda não foi sorteado!',
            style: const TextStyle(fontSize: 15),
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _checkWin() {
    // 15 números marcados = BINGO!
    int totalMarcados = 0;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 5; c++) {
        if (_marcados[r][c]) totalMarcados++;
      }
    }

    if (totalMarcados == 15) {
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
          title: const Text(
            '🎊 BINGO! PARABÉNS! 🎊',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFC18AD1)),
          ),
          content: Text(
            'Você completou todos os 15 números da sua cartela com ${_sorteados.length} bolas sorteadas!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _iniciarNovoJogo();
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
  }

  @override
  Widget build(BuildContext context) {
    int marcadosCount = 0;
    for (var r in _marcados) {
      for (var m in r) {
        if (m) marcadosCount++;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFD8A8F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bingo (15 Números)',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: 'Nova Cartela',
            onPressed: _iniciarNovoJogo,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // ── Cabeçalho do Último Sorteado ──────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ÚLTIMO NÚMERO:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _ultimoSorteado != null ? '$_ultimoSorteado' : '--',
                          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A)),
                        ),
                      ],
                    ),
                    Container(
                      height: 50,
                      width: 1.5,
                      color: Colors.grey.shade300,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acertos: $marcadosCount / 15',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sorteados: ${_sorteados.length} / 90',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Cartela 15 Números (3 Linhas x 5 Colunas) ────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF6A1B9A), width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    const Text(
                      'SUA CARTELA (15 NÚMEROS)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A), letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: 15,
                      itemBuilder: (context, index) {
                        int r = index ~/ 5;
                        int c = index % 5;
                        int num = _cartela[r][c];
                        bool isMarked = _marcados[r][c];
                        bool isDrawn = _sorteados.contains(num);

                        return GestureDetector(
                          onTap: () => _onCellTapped(r, c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: isMarked
                                  ? Colors.green.shade600
                                  : (isDrawn ? Colors.amber.shade200 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isMarked ? Colors.green.shade900 : Colors.grey.shade400,
                                width: isMarked ? 2 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$num',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isMarked ? Colors.white : Colors.black87,
                                  ),
                                ),
                                if (isMarked)
                                  const Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Icon(Icons.check, size: 14, color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Botões de Controle ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _bingo ? null : _sortearNumero,
                      icon: const Icon(Icons.casino),
                      label: const Text('Sortear Número', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _bingo ? null : _toggleAutoDraw,
                    icon: Icon(_isAutoDrawing ? Icons.pause : Icons.play_arrow),
                    label: Text(_isAutoDrawing ? 'Pausar' : 'Automático'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAutoDrawing ? Colors.orange.shade700 : Colors.white,
                      foregroundColor: _isAutoDrawing ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Log / Histórico de Números Sorteados ──────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LOG DOS NÚMEROS SORTEADOS:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          '(${_sorteados.length} bolas)',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_sorteados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Center(
                          child: Text(
                            'Nenhum número sorteado ainda. Clique em "Sortear Número"!',
                            style: TextStyle(fontSize: 13, color: Colors.black45),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          controller: _logScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: _sorteados.length,
                          itemBuilder: (context, index) {
                            int num = _sorteados[index];
                            bool isLatest = index == 0;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isLatest ? const Color(0xFF6A1B9A) : Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isLatest ? const Color(0xFF6A1B9A) : Colors.purple.shade200,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$num',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isLatest ? Colors.white : Colors.purple.shade900,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
