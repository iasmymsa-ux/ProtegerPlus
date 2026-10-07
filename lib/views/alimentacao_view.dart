import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AlimentacaoView extends StatefulWidget {
  const AlimentacaoView({super.key});

  @override
  State<AlimentacaoView> createState() => _AlimentacaoViewState();
}

class _AlimentacaoViewState extends State<AlimentacaoView> {
  String _filtroSelecionado = 'Todos';

  final List<String> _filtros = [
    'Todos',
    'Anemia',
    'Diabetes',
    'Hipertensão',
    'Colesterol',
    'Osteoporose',
    'Artrite',
    'Gastrite',
    'Insônia',
    'Depressão',
    'Obesidade',
    'Tireoide',
  ];

  final Map<String, String> _dicasPorCategoria = {
    'Todos': '💡 Escolha uma categoria acima para ver receitas e dicas específicas para sua condição de saúde.',
    'Anemia': '🩸 Dica: Alimentos ricos em ferro como feijão, espinafre e beterraba ajudam no combate à anemia.',
    'Diabetes': '🩺 Dica: Prefira alimentos com baixo índice glicêmico e evite açúcar refinado.',
    'Hipertensão': '💓 Dica: Reduza o consumo de sal e alimentos industrializados.',
    'Colesterol': '🫀 Dica: Evite frituras e gorduras saturadas. Aumente o consumo de fibras.',
    'Osteoporose': '🦴 Dica: Consuma alimentos ricos em cálcio e vitamina D.',
    'Artrite': '🦵 Dica: Alimentos anti-inflamatórios como cúrcuma e gengibre podem ajudar.',
    'Gastrite': '🫃 Dica: Evite alimentos ácidos, café e frituras.',
    'Insônia': '😴 Dica: Chás de camomila e maracujá antes de dormir podem ajudar.',
    'Depressão': '🧠 Dica: Alimentos ricos em triptofano (banana, aveia) auxiliam no humor.',
    'Obesidade': '⚖️ Dica: Prefira alimentos naturais e integrais. Beba bastante água.',
    'Tireoide': '🦋 Dica: Alimentos ricos em selênio e iodo são importantes.',
  };

  final List<Map<String, dynamic>> _todasReceitas = [
    {'nome': 'Vitamina de Beterraba', 'categorias': ['Todos', 'Anemia'], 'icone': Icons.local_cafe, 'descricao': 'Rica em ferro e vitamina C'},
    {'nome': 'Salada de Espinafre', 'categorias': ['Todos', 'Anemia', 'Hipertensão'], 'icone': Icons.eco, 'descricao': 'Folhas verdes ricas em ferro'},
    {'nome': 'Suco Verde Nutritivo', 'categorias': ['Todos', 'Anemia'], 'icone': Icons.local_drink, 'descricao': 'Ferro + Vitamina C para absorção'},
    {'nome': 'Mousse de Cacau (Sem Açúcar)', 'categorias': ['Todos', 'Diabetes', 'Colesterol'], 'icone': Icons.icecream, 'descricao': 'Baixo índice glicêmico'},
    {'nome': 'Omelete de Legumes', 'categorias': ['Todos', 'Diabetes'], 'icone': Icons.egg, 'descricao': 'Proteína e fibras'},
    {'nome': 'Pudim de Chia', 'categorias': ['Todos', 'Diabetes', 'Colesterol'], 'icone': Icons.breakfast_dining, 'descricao': 'Controle glicêmico'},
    {'nome': 'Sopa de Legumes (Sem Sal)', 'categorias': ['Todos', 'Hipertensão', 'Colesterol'], 'icone': Icons.soup_kitchen, 'descricao': 'Temperada com ervas naturais'},
    {'nome': 'Água de Coco com Limão', 'categorias': ['Todos', 'Hipertensão'], 'icone': Icons.local_drink, 'descricao': 'Hidratação e potássio'},
    {'nome': 'Banana Assada com Canela', 'categorias': ['Todos', 'Hipertensão'], 'icone': Icons.cake, 'descricao': 'Regula a pressão arterial'},
    {'nome': 'Salmão Grelhado', 'categorias': ['Todos', 'Colesterol', 'Artrite'], 'icone': Icons.set_meal, 'descricao': 'Rico em ômega-3'},
    {'nome': 'Mix de Castanhas', 'categorias': ['Todos', 'Tireoide', 'Depressão'], 'icone': Icons.grain, 'descricao': 'Selênio e gorduras boas'},
    {'nome': 'Chá de Camomila com Mel', 'categorias': ['Todos', 'Insônia', 'Gastrite'], 'icone': Icons.local_drink, 'descricao': 'Calmante natural'},
  ];

  final Map<String, Map<String, dynamic>> _detalhesReceitas = {
    'Vitamina de Beterraba': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder1',
      'tempo': '5 min',
      'calorias': '150 kcal',
      'ingredientes': ['1 beterraba cozida', '1 banana', 'Suco de 1 laranja', '200ml de leite vegetal'],
      'preparo': ['Descasque e pique as frutas.', 'Bata tudo no liquidificador.', 'Sirva bem gelado.'],
    },
    'Salada de Espinafre': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder2',
      'tempo': '15 min',
      'calorias': '120 kcal',
      'ingredientes': ['1 maço de espinafre', '1 beterraba ralada', 'Azeite e limão'],
      'preparo': ['Lave as folhas.', 'Refogue o espinafre rapidamente no azeite.', 'Misture com a beterraba e limão.'],
    },
    'Suco Verde Nutritivo': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder3',
      'tempo': '5 min',
      'calorias': '90 kcal',
      'ingredientes': ['2 folhas de couve', '1 maçã', 'Gengibre', 'Suco de 1 limão', '300ml de água'],
      'preparo': ['Lave bem tudo.', 'Bata no liquidificador por 2 min.', 'Beba sem coar.'],
    },
    'Mousse de Cacau (Sem Açúcar)': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder4',
      'tempo': '10 min',
      'calorias': '210 kcal',
      'ingredientes': ['1 abacate maduro', '3 colheres de cacau 70%', '2 colheres de mel', 'Baunilha'],
      'preparo': ['Amasse o abacate.', 'Bata com o cacau e o mel.', 'Gele por 1 hora.'],
    },
    'Omelete de Legumes': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder5',
      'tempo': '10 min',
      'calorias': '200 kcal',
      'ingredientes': ['2 ovos', 'Tomate, cebola e abobrinha picados', 'Salsinha', 'Azeite'],
      'preparo': ['Bata os ovos com os legumes.', 'Grelhe na frigideira dos dois lados.'],
    },
    'Pudim de Chia': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder6',
      'tempo': '5 min (+espera)',
      'calorias': '180 kcal',
      'ingredientes': ['3 colheres de chia', '200ml de leite de coco', 'Mel', 'Frutas vermelhas'],
      'preparo': ['Misture tudo em um pote.', 'Gele por 4 horas.', 'Decore com as frutas.'],
    },
    'Sopa de Legumes (Sem Sal)': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder7',
      'tempo': '30 min',
      'calorias': '180 kcal',
      'ingredientes': ['Batata', 'Cenoura', 'Abobrinha', 'Alho e cebola', 'Ervas frescas'],
      'preparo': ['Refogue os temperos.', 'Cozinhe os legumes em água.', 'Finalize com as ervas.'],
    },
    'Água de Coco com Limão': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder8',
      'tempo': '2 min',
      'calorias': '50 kcal',
      'ingredientes': ['300ml de água de coco', 'Meio limão', 'Gelo'],
      'preparo': ['Misture o limão na água de coco.', 'Sirva bem gelado.'],
    },
    'Banana Assada com Canela': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder9',
      'tempo': '10 min',
      'calorias': '110 kcal',
      'ingredientes': ['1 banana', 'Canela em pó', 'Mel'],
      'preparo': ['Polvilhe canela na banana.', 'Aqueça por 1 min no micro-ondas.'],
    },
    'Salmão Grelhado': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder10',
      'tempo': '20 min',
      'calorias': '250 kcal',
      'ingredientes': ['1 filé de salmão', 'Azeite', 'Alecrim', 'Limão'],
      'preparo': ['Tempere o peixe.', 'Grelhe 5 min de cada lado.'],
    },
    'Mix de Castanhas': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder11',
      'tempo': '2 min',
      'calorias': '130 kcal',
      'ingredientes': ['Castanha-do-pará', 'Nozes', 'Amêndoas'],
      'preparo': ['Misture as castanhas.', 'Consuma uma porção pequena por dia.'],
    },
    'Chá de Camomila com Mel': {
      'videoUrl': 'https://www.youtube.com/watch?v=placeholder12',
      'tempo': '8 min',
      'calorias': '40 kcal',
      'ingredientes': ['Camomila', 'Água quente', 'Mel'],
      'preparo': ['Faça a infusão por 5 min.', 'Coe e adoce.'],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterMenu(),
            const SizedBox(height: 12),
            _buildTipBox(),
            const SizedBox(height: 12),
            _buildRecipeList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Cuidados com a Saúde',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif'),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFilterMenu() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
      ),
      child: SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filtros.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final filtro = _filtros[index];
            final selecionado = filtro == _filtroSelecionado;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _filtroSelecionado = filtro),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: selecionado ? const Color(0xFFAA8ED6) : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: selecionado ? const Color(0xFF4B3269) : Colors.white.withValues(alpha: 0.9), width: 2.5),
                    boxShadow: selecionado ? [BoxShadow(color: const Color(0xFFAA8ED6).withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))] : [],
                  ),
                  child: Text(filtro, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: selecionado ? Colors.white : const Color(0xFF4B3269))),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTipBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF7B4FA2)),
          const SizedBox(width: 10),
          Expanded(child: Text(_dicasPorCategoria[_filtroSelecionado] ?? '')),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    final receitas = _filtroSelecionado == 'Todos' 
        ? _todasReceitas 
        : _todasReceitas.where((r) => (r['categorias'] as List<String>).contains(_filtroSelecionado)).toList();

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: receitas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final r = receitas[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              onTap: () => _mostrarDetalhes(r),
              leading: CircleAvatar( child: Icon(r['icone'] as IconData, color: const Color(0xFF7B4FA2))),
              title: Text(r['nome'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(r['descricao'] as String),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDetalhes(Map<String, dynamic> item) {
    final detalhes = _detalhesReceitas[item['nome']] ?? {
      'tempo': '20 min',
      'calorias': '---',
      'ingredientes': ['Consulte o nutricionista para detalhes.'],
      'preparo': ['Modo de preparo em atualização.'],
      'videoUrl': 'https://youtube.com',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            Center(child: Container(margin: const EdgeInsets.all(12), width: 60, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['nome'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF4B3269))),
                    const SizedBox(height: 8),
                    Text('${detalhes['tempo']} • ${detalhes['calorias']}', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    _buildVideoPlaceholder(detalhes['videoUrl']),
                    const SizedBox(height: 32),
                    const Text('Ingredientes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ...(detalhes['ingredientes'] as List<String>).map((ing) => ListTile(leading: const Icon(Icons.check, color: Colors.green), title: Text(ing))),
                    const SizedBox(height: 16),
                    const Text('Modo de Preparo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ...(detalhes['preparo'] as List<String>).asMap().entries.map((e) => ListTile(leading: CircleAvatar(child: Text('${e.key + 1}')), title: Text(e.value))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(), child: const Text('CONCLUÍDO', style: TextStyle(color: Colors.white)))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder(String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=400'), fit: BoxFit.cover, opacity: 0.5)),
        child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 64)),
      ),
    );
  }
}
