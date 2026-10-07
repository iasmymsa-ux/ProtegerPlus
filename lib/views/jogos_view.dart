import 'package:flutter/material.dart';
import 'games/memory_game_view.dart';
import 'games/hidden_object_view.dart';
import 'games/crossword_view.dart';
import 'games/seven_errors_view.dart';
import 'games/bingo_view.dart';

class JogosView extends StatelessWidget {
  const JogosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 28, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Jogos',
                      style: TextStyle(
                        fontSize: 24, 
                        color: Colors.black, 
                        fontFamily: 'serif',
                        fontWeight: FontWeight.bold,
                      ), 
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGameButton(
                    context: context,
                    title: 'Jogo da Memoria',
                    targetView: const MemoryGameView(),
                    iconBuilder: () => _buildMemoryIcon(),
                  ),
                  _buildGameButton(
                    context: context,
                    title: 'Ache o Objeto',
                    targetView: const HiddenObjectView(),
                    iconBuilder: () => _buildHiddenObjectIcon(),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGameButton(
                    context: context,
                    title: 'Cruzadinha',
                    targetView: const CrosswordView(),
                    iconBuilder: () => _buildCrosswordIcon(),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGameButton(
                    context: context,
                    title: 'Jogo dos 7 Erros', // Fixed the typo from the user's mockup image
                    targetView: const SevenErrorsView(),
                    iconBuilder: () => _buildSevenErrorsIcon(),
                  ),
                  _buildGameButton(
                    context: context,
                    title: 'Bingo', // Fixed the typo from the user's mockup image
                    targetView: const BingoView(),
                    iconBuilder: () => _buildBingoIcon(),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameButton({
    required BuildContext context,
    required String title,
    required Widget targetView,
    required Widget Function() iconBuilder,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () {
             Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => targetView),
             );
          },
          splashColor: Colors.deepPurple.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(75),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            // The iconBuilder itself will return a rounded container to make up the badge
            child: ClipOval(child: iconBuilder()),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // --- Composers for the Mockup Icons using Custom UI ---

  Widget _buildMemoryIcon() {
    return Container(
      color: const Color(0xFFC0AEEB),
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 2),
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Container(decoration: BoxDecoration(color: Colors.blue[300], border: Border.all(width: 1)), child: const Center(child: Icon(Icons.change_history, color: Colors.yellow)))),
                  Expanded(child: Container(decoration: BoxDecoration(color: Colors.green[300], border: Border.all(width: 1)), child: const Center(child: Icon(Icons.square, color: Colors.teal)))),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Container(decoration: BoxDecoration(color: Colors.teal[300], border: Border.all(width: 1)), child: const Center(child: Icon(Icons.circle, color: Colors.red)))),
                  Expanded(child: Container(decoration: BoxDecoration(color: Colors.yellow[600], border: Border.all(width: 1)), child: const Center(child: Icon(Icons.star, color: Colors.blue)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenObjectIcon() {
    return Container(
      color: const Color(0xFFB5B8DE),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 20, left: 30, child: Icon(Icons.directions_car, color: Colors.red, size: 24)),
          const Positioned(bottom: 20, right: 30, child: Icon(Icons.park, color: Colors.green, size: 28)),
          const Positioned(top: 30, right: 20, child: Icon(Icons.sports_basketball, color: Colors.orange, size: 24)),
          const Positioned(bottom: 30, left: 20, child: Icon(Icons.ac_unit, color: Colors.white, size: 24)),
          const Positioned(top: 50, left: 50, child: Icon(Icons.star, color: Colors.yellow, size: 40)),
          Icon(Icons.search, color: Colors.black.withValues(alpha: 0.8), size: 70),
        ],
      ),
    );
  }

  Widget _buildCrosswordIcon() {
    return Container(
      color: const Color(0xFFFA8E62),
      padding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2), color: Colors.white),
            child: GridView.count(
              crossAxisCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(9, (index) => Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
                child: Center(
                  child: Text(['B','E','A','H','H','C'][index % 6], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              )),
            ),
          ),
          const Positioned(
            bottom: -5,
            right: -5,
            child: Icon(Icons.edit, color: Colors.amber, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildSevenErrorsIcon() {
    return Container(
      color: const Color(0xFFB0CDED),
      child: const Center(
        child: Text(
          '≠', 
          style: TextStyle(
            fontSize: 100, 
            color: Color(0xFF6B8DB5), 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBingoIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE27C4E), width: 8),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'BINGO', 
            style: TextStyle(
              color: Color(0xFFE27C4E), 
              fontWeight: FontWeight.bold, 
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Column(
              children: List.generate(3, (j) => Container(
                margin: const EdgeInsets.all(1),
                width: 10,
                height: 10,
                color: const Color(0xFFE27C4E),
              )),
            )),
          )
        ],
      ),
    );
  }
}
