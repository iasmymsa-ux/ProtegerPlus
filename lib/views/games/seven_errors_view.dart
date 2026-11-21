import 'package:flutter/material.dart';

class ErrorItem {
  final String description;
  final Alignment alignment;
  final double size;

  const ErrorItem({
    required this.description,
    required this.alignment,
    required this.size,
  });
}

class ErrorScene {
  final String title;
  final Color skyColor;
  final List<ErrorItem> errors;

  const ErrorScene({
    required this.title,
    required this.skyColor,
    required this.errors,
  });
}

class SevenErrorsView extends StatefulWidget {
  const SevenErrorsView({super.key});

  @override
  State<SevenErrorsView> createState() => _SevenErrorsViewState();
}

class _SevenErrorsViewState extends State<SevenErrorsView> {
  final List<ErrorScene> _scenes = const [
    // ── Cena 1: Dia no Campo ──
    ErrorScene(
      title: 'Dia Ensolarado no Campo',
      skyColor: Color(0xFFB3E5FC),
      errors: [
        ErrorItem(description: 'Sol com óculos escuros', alignment: Alignment(-0.7, -0.8), size: 44),
        ErrorItem(description: 'Nuvem rosa diferente', alignment: Alignment(0.6, -0.75), size: 48),
        ErrorItem(description: 'Pássaro voando na direita', alignment: Alignment(0.1, -0.5), size: 36),
        ErrorItem(description: 'Chaminé da casa com fumaça', alignment: Alignment(-0.55, -0.1), size: 40),
        ErrorItem(description: 'Porta da casa com cor trocada', alignment: Alignment(-0.35, 0.4), size: 44),
        ErrorItem(description: 'Flor vermelha no jardim', alignment: Alignment(0.65, 0.65), size: 38),
        ErrorItem(description: 'Cachorrinho na grama', alignment: Alignment(0.1, 0.7), size: 40),
      ],
    ),
    // ── Cena 2: Noite Estrelada ──
    ErrorScene(
      title: 'Noite Estrelada',
      skyColor: Color(0xFF1A237E),
      errors: [
        ErrorItem(description: 'Lua com sorriso', alignment: Alignment(-0.65, -0.75), size: 46),
        ErrorItem(description: 'Estrela cadente brilhante', alignment: Alignment(0.55, -0.8), size: 40),
        ErrorItem(description: 'Coruja na árvore', alignment: Alignment(0.6, -0.3), size: 42),
        ErrorItem(description: 'Janela do castelo acesa', alignment: Alignment(-0.4, 0.0), size: 42),
        ErrorItem(description: 'Gato preto no muro', alignment: Alignment(0.0, 0.35), size: 38),
        ErrorItem(description: 'Vaga-lume dourado brilhando', alignment: Alignment(0.45, 0.6), size: 36),
        ErrorItem(description: 'Cogumelo azul no chão', alignment: Alignment(-0.6, 0.75), size: 38),
      ],
    ),
    // ── Cena 3: Fundo do Mar ──
    ErrorScene(
      title: 'Fundo do Mar Colorido',
      skyColor: Color(0xFF006064),
      errors: [
        ErrorItem(description: 'Submarino amarelo', alignment: Alignment(-0.6, -0.7), size: 46),
        ErrorItem(description: 'Golfinho saltando', alignment: Alignment(0.5, -0.65), size: 44),
        ErrorItem(description: 'Polvo roxo no meio', alignment: Alignment(0.0, -0.15), size: 48),
        ErrorItem(description: 'Peixe palhaço listrado', alignment: Alignment(-0.6, 0.25), size: 40),
        ErrorItem(description: 'Estrela do mar vermelha', alignment: Alignment(0.6, 0.5), size: 42),
        ErrorItem(description: 'Baú do tesouro aberto', alignment: Alignment(-0.2, 0.75), size: 46),
        ErrorItem(description: 'Concha brilhante com pérola', alignment: Alignment(0.65, 0.8), size: 38),
      ],
    ),
  ];

  int _currentSceneIndex = 0;
  late List<bool> _errosEncontrados;
  int _tentativasRestantes = 6;
  bool _victory = false;

  @override
  void initState() {
    super.initState();
    _startRound(_currentSceneIndex);
  }

  void _startRound(int index) {
    setState(() {
      _currentSceneIndex = index % _scenes.length;
      _errosEncontrados = List.filled(7, false);
      _tentativasRestantes = 6;
      _victory = false;
    });
  }

  void _nextScene() {
    _startRound(_currentSceneIndex + 1);
  }

  void _onErrorTapped(int index) {
    if (_victory || _errosEncontrados[index]) return;

    setState(() {
      _errosEncontrados[index] = true;
    });

    final int total = _errosEncontrados.where((e) => e).length;

    if (total == 7) {
      setState(() => _victory = true);
      _showVictoryDialog();
    } else {
      final item = _scenes[_currentSceneIndex].errors[index];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Muito bem! Você encontrou: ${item.description} ($total/7)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSceneMissedTap() {
    if (_victory) return;

    setState(() {
      _tentativasRestantes--;
    });

    if (_tentativasRestantes <= 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Fim das Tentativas!', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
          content: const Text('Você gastou suas tentativas nesta cena. Deseja reiniciar ou ir para a próxima cena?', textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startRound(_currentSceneIndex);
              },
              child: const Text('Tentar Novamente'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _nextScene();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC18AD1)),
              child: const Text('Próxima Cena', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ops! Não há erro aqui. ($_tentativasRestantes chances restantes)', style: const TextStyle(fontSize: 14)),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(milliseconds: 700),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        content: Text(
          'Você encontrou todos os 7 erros na cena "${_scenes[_currentSceneIndex].title}"!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _nextScene();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC18AD1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Próxima Cena', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_currentSceneIndex];
    final int foundCount = _errosEncontrados.where((e) => e).length;

    return Scaffold(
      backgroundColor: const Color(0xFFC9A0DC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jogo dos 7 Erros',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.black87),
            tooltip: 'Mudar Cena',
            onPressed: _nextScene,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Informações da cena e tentativas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scene.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        'Encontrados: $foundCount de 7',
                        style: const TextStyle(fontSize: 13, color: Colors.purple, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Chances: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ...List.generate(
                        6,
                        (index) => Icon(
                          index < _tentativasRestantes ? Icons.star : Icons.star_border,
                          color: Colors.amber.shade800,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Comparação das Duas Imagens
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    // CENA ORIGINAL (Esquerda)
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Original', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: scene.skyColor,
                                border: Border.all(color: Colors.white, width: 3),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: _buildSceneIllustration(isErrorScene: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // CENA COM ERROS (Direita) - Onde o jogador clica
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Ache os 7 Erros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
                          const SizedBox(height: 4),
                          Expanded(
                            child: GestureDetector(
                              onTap: _onSceneMissedTap,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: scene.skyColor,
                                  border: Border.all(color: const Color(0xFFC18AD1), width: 3),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Stack(
                                    children: [
                                      _buildSceneIllustration(isErrorScene: true),
                                      // Alvos clicáveis dos 7 erros
                                      ...List.generate(7, (i) {
                                        final err = scene.errors[i];
                                        final bool found = _errosEncontrados[i];
                                        return Align(
                                          alignment: err.alignment,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _onErrorTapped(i),
                                            child: Container(
                                              width: err.size,
                                              height: err.size,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: found
                                                    ? Border.all(color: Colors.red, width: 3)
                                                    : null,
                                                color: found
                                                    ? Colors.red.withValues(alpha: 0.25)
                                                    : Colors.transparent,
                                              ),
                                              child: found
                                                  ? const Center(
                                                      child: Icon(Icons.close, color: Colors.red, size: 28),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneIllustration({required bool isErrorScene}) {
    switch (_currentSceneIndex) {
      case 0:
        return _buildCampoScene(isErrorScene);
      case 1:
        return _buildNoiteScene(isErrorScene);
      case 2:
      default:
        return _buildMarScene(isErrorScene);
    }
  }

  // Cena 1: Campo
  Widget _buildCampoScene(bool isError) {
    return Stack(
      children: [
        // Chão de grama
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 90,
            color: const Color(0xFF66BB6A),
          ),
        ),
        // Erro 0: Sol
        Align(
          alignment: const Alignment(-0.7, -0.8),
          child: Icon(
            Icons.wb_sunny,
            color: isError ? Colors.amber.shade700 : Colors.amber,
            size: 38,
          ),
        ),
        // Erro 1: Nuvem
        Align(
          alignment: const Alignment(0.6, -0.75),
          child: Icon(
            Icons.cloud,
            color: isError ? Colors.pink.shade100 : Colors.white,
            size: 42,
          ),
        ),
        // Erro 2: Pássaro
        if (!isError || _errosEncontrados[2])
          const Align(
            alignment: Alignment(0.1, -0.5),
            child: Icon(Icons.flutter_dash, color: Colors.blueGrey, size: 28),
          ),
        // Erro 3: Chaminé
        Align(
          alignment: const Alignment(-0.55, -0.1),
          child: Icon(
            Icons.local_fire_department,
            color: isError ? Colors.orange : Colors.grey.shade600,
            size: 26,
          ),
        ),
        // Casa
        const Align(
          alignment: Alignment(-0.4, 0.25),
          child: Icon(Icons.home, color: Color(0xFF8D6E63), size: 68),
        ),
        // Erro 4: Porta da casa
        Align(
          alignment: const Alignment(-0.35, 0.4),
          child: Icon(
            Icons.door_front_door,
            color: isError ? Colors.purple : Colors.brown.shade800,
            size: 26,
          ),
        ),
        // Árvore
        const Align(
          alignment: Alignment(0.7, 0.2),
          child: Icon(Icons.park, color: Colors.green, size: 64),
        ),
        // Erro 5: Flor
        Align(
          alignment: const Alignment(0.65, 0.65),
          child: Icon(
            Icons.local_florist,
            color: isError ? Colors.red : Colors.yellow,
            size: 28,
          ),
        ),
        // Erro 6: Cachorrinho
        if (isError)
          const Align(
            alignment: Alignment(0.1, 0.7),
            child: Icon(Icons.pets, color: Colors.brown, size: 28),
          ),
      ],
    );
  }

  // Cena 2: Noite
  Widget _buildNoiteScene(bool isError) {
    return Stack(
      children: [
        // Chão noturno
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(height: 80, color: const Color(0xFF263238)),
        ),
        // Erro 0: Lua
        Align(
          alignment: const Alignment(-0.65, -0.75),
          child: Icon(
            Icons.nightlight_round,
            color: isError ? Colors.amber.shade300 : Colors.white,
            size: 40,
          ),
        ),
        // Erro 1: Estrela cadente
        Align(
          alignment: const Alignment(0.55, -0.8),
          child: Icon(
            Icons.auto_awesome,
            color: isError ? Colors.amber : Colors.white54,
            size: 28,
          ),
        ),
        // Erro 2: Coruja
        Align(
          alignment: const Alignment(0.6, -0.3),
          child: Icon(
            Icons.visibility,
            color: isError ? Colors.yellow : Colors.transparent,
            size: 24,
          ),
        ),
        // Edifício / Castelo
        const Align(
          alignment: Alignment(-0.4, 0.15),
          child: Icon(Icons.apartment, color: Color(0xFF455A64), size: 70),
        ),
        // Erro 3: Janela
        Align(
          alignment: const Alignment(-0.4, 0.0),
          child: Icon(
            Icons.window,
            color: isError ? Colors.yellow : Colors.blueGrey.shade800,
            size: 24,
          ),
        ),
        // Erro 4: Gato
        if (isError)
          const Align(
            alignment: Alignment(0.0, 0.35),
            child: Icon(Icons.cruelty_free, color: Colors.black, size: 28),
          ),
        // Erro 5: Vaga-lume
        Align(
          alignment: const Alignment(0.45, 0.6),
          child: Icon(
            Icons.lightbulb,
            color: isError ? Colors.yellowAccent : Colors.transparent,
            size: 22,
          ),
        ),
        // Erro 6: Cogumelo
        Align(
          alignment: const Alignment(-0.6, 0.75),
          child: Icon(
            Icons.nature,
            color: isError ? Colors.cyanAccent : Colors.brown,
            size: 26,
          ),
        ),
      ],
    );
  }

  // Cena 3: Fundo do Mar
  Widget _buildMarScene(bool isError) {
    return Stack(
      children: [
        // Areia do fundo do mar
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(height: 70, color: const Color(0xFFD7CCC8)),
        ),
        // Erro 0: Submarino
        Align(
          alignment: const Alignment(-0.6, -0.7),
          child: Icon(
            Icons.directions_boat,
            color: isError ? Colors.yellow : Colors.transparent,
            size: 34,
          ),
        ),
        // Erro 1: Golfinho
        Align(
          alignment: const Alignment(0.5, -0.65),
          child: Icon(
            Icons.phishing,
            color: isError ? Colors.cyanAccent : Colors.lightBlue,
            size: 32,
          ),
        ),
        // Erro 2: Polvo
        Align(
          alignment: const Alignment(0.0, -0.15),
          child: Icon(
            Icons.coronavirus,
            color: isError ? Colors.purpleAccent : Colors.pinkAccent,
            size: 38,
          ),
        ),
        // Erro 3: Peixe palhaço
        Align(
          alignment: const Alignment(-0.6, 0.25),
          child: Icon(
            Icons.set_meal,
            color: isError ? Colors.deepOrange : Colors.blue,
            size: 30,
          ),
        ),
        // Erro 4: Estrela do mar
        Align(
          alignment: const Alignment(0.6, 0.5),
          child: Icon(
            Icons.star,
            color: isError ? Colors.redAccent : Colors.amber,
            size: 32,
          ),
        ),
        // Erro 5: Baú do tesouro
        Align(
          alignment: const Alignment(-0.2, 0.75),
          child: Icon(
            Icons.inventory_2,
            color: isError ? Colors.amber.shade800 : Colors.brown,
            size: 30,
          ),
        ),
        // Erro 6: Concha
        Align(
          alignment: const Alignment(0.65, 0.8),
          child: Icon(
            Icons.circle,
            color: isError ? Colors.white : Colors.pink.shade200,
            size: 22,
          ),
        ),
      ],
    );
  }
}
