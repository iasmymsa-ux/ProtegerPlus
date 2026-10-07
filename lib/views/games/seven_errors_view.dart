import 'package:flutter/material.dart';

class SevenErrorsView extends StatefulWidget {
  const SevenErrorsView({super.key});

  @override
  State<SevenErrorsView> createState() => _SevenErrorsViewState();
}

class _SevenErrorsViewState extends State<SevenErrorsView> {
  // Estado das 7 diferenças (true = encontrado)
  late List<bool> _erros;
  bool _victory = false;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    setState(() {
      _erros = List.filled(7, false);
      _victory = false;
    });
  }

  void _onErrorTapped(int index) {
    if (_victory || _erros[index]) return;

    setState(() {
      _erros[index] = true;
    });

    if (_erros.every((e) => e)) {
      setState(() {
        _victory = true;
      });
      _showVictoryDialog();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Muito bem! Você encontrou um erro.', style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.green,
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
        content: const Text('Você encontrou todas as 7 diferenças!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
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
            child: const Text('Jogar Novamente', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int foundCount = _erros.where((e) => e).length;

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jogo dos 7 Erros', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 24)
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        // Botões de voltar e header permanecem
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Erros Encontrados: $foundCount / 7',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // IMAGEM ORIGINAL (Esquerda)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.lightBlue[100],
                          border: Border.all(color: Colors.white, width: 4),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildOriginalScene(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),

                    // IMAGEM COM ERROS (Direita)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.lightBlue[100],
                          border: Border.all(color: Colors.white, width: 4),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildErrorScene(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // --- CENA ORIGINAL ---
  Widget _buildOriginalScene() {
    return Stack(
      children: [
        // Chão Verde
        Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 60, color: Colors.green[400])),
        
        // Items base
        const Positioned(top: 20, right: 30, child: Icon(Icons.wb_sunny, color: Colors.yellow, size: 50)), // Sol 
        const Positioned(bottom: 60, left: 30, child: Icon(Icons.home, color: Colors.red, size: 80)), // Casa
        const Positioned(bottom: 60, right: 30, child: Icon(Icons.park, color: Colors.green, size: 90)), // Arvore
        const Positioned(top: 40, left: 40, child: Icon(Icons.cloud, color: Colors.white, size: 60)), // Nuvem
        const Positioned(bottom: 20, left: 130, child: Icon(Icons.directions_car, color: Colors.blue, size: 50)), // Carro
        const Positioned(bottom: 60, right: 120, child: Icon(Icons.pets, color: Colors.brown, size: 40)), // Cachorro
        const Positioned(top: 80, right: 100, child: Icon(Icons.flight, color: Colors.grey, size: 40)), // Aviao
      ],
    );
  }

  // --- CENA COM ERROS ---
  Widget _buildErrorScene() {
    return Stack(
      children: [
        // Chão Verde
        Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 60, color: Colors.green[400])),
        
        // Erro 0: Sem sol
        _buildErrorHitbox(0, top: 20, right: 30, size: 50,
          child: const SizedBox(width: 50, height: 50),
        ),
        
        // Erro 1: Casa de outra cor
        _buildErrorHitbox(1, bottom: 60, left: 30, size: 80,
          child: const Icon(Icons.home, color: Colors.orange, size: 80),
        ),

        // Erro 2: Arvore vermelha
        _buildErrorHitbox(2, bottom: 60, right: 30, size: 90,
          child: const Icon(Icons.park, color: Colors.redAccent, size: 90),
        ),

        // Erro 3: Nuvem movida muito pra direita
        _buildErrorHitbox(3, top: 40, left: 140, size: 60,
          child: const Icon(Icons.cloud, color: Colors.white, size: 60),
        ),

        // Erro 4: Carro girado
        _buildErrorHitbox(4, bottom: 20, left: 130, size: 50,
          child: Transform.flip(flipX: true, child: const Icon(Icons.directions_car, color: Colors.blue, size: 50)),
        ),

        // Erro 5: Gato no lugar do Cachorro
        _buildErrorHitbox(5, bottom: 60, right: 120, size: 40,
          child: const Icon(Icons.cruelty_free, color: Colors.brown, size: 40),
        ),

        // Erro 6: Pipa no lugar do Aviao
        _buildErrorHitbox(6, top: 80, right: 100, size: 40,
          child: const Icon(Icons.toys, color: Colors.pink, size: 40),
        ),
      ],
    );
  }

  Widget _buildErrorHitbox(int index, {double? top, double? bottom, double? left, double? right, required double size, required Widget child}) {
    bool isFound = _erros[index];
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: GestureDetector(
        onTap: () => _onErrorTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size + 20,
          height: size + 20,
          alignment: Alignment.center,
          decoration: isFound
              ? BoxDecoration(
                  border: Border.all(color: Colors.red, width: 4),
                  shape: BoxShape.circle,
                )
              : null,
          child: child,
        ),
      ),
    );
  }
}
