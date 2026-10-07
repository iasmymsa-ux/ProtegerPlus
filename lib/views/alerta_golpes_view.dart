import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/golpe_analyzer_service.dart';

enum AnaliseStatus { nenhuma, carregando, seguro, suspeito, naoSeguro, naoFoiPossivelAnalisar }

class AlertaGolpesView extends StatefulWidget {
  const AlertaGolpesView({super.key});

  @override
  State<AlertaGolpesView> createState() => _AlertaGolpesViewState();
}

class _AlertaGolpesViewState extends State<AlertaGolpesView> {
  // Estado da seção de IMAGEM
  XFile? _imagemSelecionada;
  Uint8List? _imagemBytes;
  AnaliseStatus _analiseImagemStatus = AnaliseStatus.nenhuma;
  String _analiseImagemTexto = '';
  List<String> _alertasImagemEncontrados = [];
  bool _isAnalyzingImagem = false;

  // Estado da seção de LINK
  AnaliseStatus _analiseLinkStatus = AnaliseStatus.nenhuma;
  String _analiseLinkTexto = '';
  String _linkSubmetido = '';
  List<String> _alertasLinkEncontrados = [];
  bool _isAnalyzingLink = false;

  final TextEditingController _linkController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  // ── LÓGICA DE IMAGEM ─────────────────────────────────────────────

  void _mostrarOpcaoImagem() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecionar imagem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4C8A),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text(
                  'Escolher da galeria',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _selecionarImagem(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text(
                  'Tirar foto agora',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _selecionarImagem(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selecionarImagem(ImageSource source) async {
    final XFile? arquivo = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );

    if (arquivo == null) return;

    final bytes = await arquivo.readAsBytes();

    setState(() {
      _imagemSelecionada = arquivo;
      _imagemBytes = bytes;
      _analiseImagemStatus = AnaliseStatus.nenhuma;
      _analiseImagemTexto = '';
      _alertasImagemEncontrados = [];
      _isAnalyzingImagem = false;
    });
  }

  Future<void> _executarAnaliseImagem() async {
    if (_imagemBytes == null || _isAnalyzingImagem) return;

    setState(() {
      _isAnalyzingImagem = true;
      _analiseImagemStatus = AnaliseStatus.carregando;
      _analiseImagemTexto = '';
      _alertasImagemEncontrados = [];
    });

    final resultado = await GolpeAnalyzerService.analisarImagem(
      _imagemBytes!,
      nomeArquivo: _imagemSelecionada?.name ?? 'imagem.jpg',
      mimeType: _imagemSelecionada?.mimeType,
    );

    if (mounted) {
      setState(() {
        _isAnalyzingImagem = false;
        _analiseImagemTexto = resultado.explicacao;
        _alertasImagemEncontrados = resultado.alertasEncontrados;

        switch (resultado.status) {
          case ResultadoAnalise.seguro:
            _analiseImagemStatus = AnaliseStatus.seguro;
            break;
          case ResultadoAnalise.suspeito:
            _analiseImagemStatus = AnaliseStatus.suspeito;
            break;
          case ResultadoAnalise.naoSeguro:
            _analiseImagemStatus = AnaliseStatus.naoSeguro;
            break;
          case ResultadoAnalise.naoFoiPossivelAnalisar:
            _analiseImagemStatus = AnaliseStatus.naoFoiPossivelAnalisar;
            break;
        }
      });
    }
  }

  void _removerImagem() {
    setState(() {
      _imagemSelecionada = null;
      _imagemBytes = null;
      _analiseImagemStatus = AnaliseStatus.nenhuma;
      _analiseImagemTexto = '';
      _alertasImagemEncontrados = [];
      _isAnalyzingImagem = false;
    });
  }

  // ── LÓGICA DE LINK ───────────────────────────────────────────────

  Future<void> _executarAnaliseLink() async {
    final rawText = _linkController.text.trim();

    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite ou cole um link para que possamos analisar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final urlValidada = GolpeAnalyzerService.validarEFormatarUrl(rawText);
    if (urlValidada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Endereço de link com formato inválido. Confira o link digitado (exemplo: site.com).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_isAnalyzingLink) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isAnalyzingLink = true;
      _linkSubmetido = urlValidada;
      _analiseLinkStatus = AnaliseStatus.carregando;
      _analiseLinkTexto = '';
      _alertasLinkEncontrados = [];
    });

    final resultado = await GolpeAnalyzerService.analisarLink(urlValidada);

    if (mounted) {
      setState(() {
        _isAnalyzingLink = false;
        _analiseLinkTexto = resultado.explicacao;
        _alertasLinkEncontrados = resultado.alertasEncontrados;

        switch (resultado.status) {
          case ResultadoAnalise.seguro:
            _analiseLinkStatus = AnaliseStatus.seguro;
            break;
          case ResultadoAnalise.suspeito:
            _analiseLinkStatus = AnaliseStatus.suspeito;
            break;
          case ResultadoAnalise.naoSeguro:
            _analiseLinkStatus = AnaliseStatus.naoSeguro;
            break;
          case ResultadoAnalise.naoFoiPossivelAnalisar:
            _analiseLinkStatus = AnaliseStatus.naoFoiPossivelAnalisar;
            break;
        }
      });
    }
  }

  void _limparAnaliseLink() {
    setState(() {
      _linkController.clear();
      _linkSubmetido = '';
      _analiseLinkStatus = AnaliseStatus.nenhuma;
      _analiseLinkTexto = '';
      _alertasLinkEncontrados = [];
      _isAnalyzingLink = false;
    });
  }

  // ── POPUPS DE DICA ───────────────────────────────────────────────

  void _mostrarDicaPrint() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Como tirar print?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4C8A),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DicaItem(
              numero: '1',
              texto: 'Android: Pressione os botões de Volume Baixo + Ligar/Desligar ao mesmo tempo.',
            ),
            SizedBox(height: 12),
            _DicaItem(
              numero: '2',
              texto: 'iPhone: Pressione o botão lateral + Volume Cima ao mesmo tempo.',
            ),
            SizedBox(height: 12),
            _DicaItem(
              numero: '3',
              texto: 'A imagem será salva automaticamente na galeria de fotos.',
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Entendi!', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _mostrarDicaLink() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Como conseguir o link?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4C8A),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DicaItem(
              numero: '1',
              texto: 'No WhatsApp / Mensagens: Mantenha o dedo pressionado sobre a mensagem com o link e selecione "Copiar".',
            ),
            SizedBox(height: 12),
            _DicaItem(
              numero: '2',
              texto: 'No Instagram ou Facebook: Toque nos três pontos (...) da publicação e escolha "Copiar link".',
            ),
            SizedBox(height: 12),
            _DicaItem(
              numero: '3',
              texto: 'Depois, volte aqui e cole o endereço no campo de texto.',
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Entendi!', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ─────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Alerta de golpes',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white, size: 28),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidade de voz em breve!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── SEÇÃO: LINK (PARTE 2) ──────────────────────────
              _buildSectionCard(
                title: 'Analisar link / endereço de site',
                titleIcon: Icons.link,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Digite ou cole o link que você recebeu:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _linkController,
                      enabled: !_isAnalyzingLink,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(color: Colors.black87, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Ex: https://site.com ou bradesco.com.br',
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.link, color: Color(0xFF9C72AD)),
                        suffixIcon: _linkController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _linkController.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _mostrarDicaLink,
                          child: const Text(
                            'Como conseguir o link?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                        if (_analiseLinkStatus != AnaliseStatus.nenhuma)
                          GestureDetector(
                            onTap: _limparAnaliseLink,
                            child: const Text(
                              'Limpar análise',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzingLink ? null : _executarAnaliseLink,
                        icon: _isAnalyzingLink
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.shield_outlined, color: Colors.white),
                        label: Text(
                          _isAnalyzingLink ? 'Analisando link...' : 'Analisar Link',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B4C8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    if (_analiseLinkStatus != AnaliseStatus.nenhuma) ...[
                      const SizedBox(height: 20),
                      _buildAnaliseResultLink(
                        status: _analiseLinkStatus,
                        explicacao: _analiseLinkTexto,
                        urlSubmetida: _linkSubmetido,
                        alertas: _alertasLinkEncontrados,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── SEÇÃO: IMAGEM (PRINT) ──────────────────────────
              _buildSectionCard(
                title: 'Analisar imagem (print)',
                titleIcon: Icons.image_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_imagemBytes == null)
                      _buildAddButton(
                        label: 'Adicionar print/imagem do perfil',
                        onTap: _mostrarOpcaoImagem,
                        helpText: 'Como tirar print?',
                        onHelpTap: _mostrarDicaPrint,
                      )
                    else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imagemBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAnexadoChip(
                            label: 'Foto anexada ✓',
                            onRemove: _removerImagem,
                          ),
                          GestureDetector(
                            onTap: _isAnalyzingImagem ? null : _mostrarOpcaoImagem,
                            child: const Text(
                              'Trocar foto',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isAnalyzingImagem ? null : _executarAnaliseImagem,
                          icon: _isAnalyzingImagem
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.shield_outlined, color: Colors.white),
                          label: Text(
                            _isAnalyzingImagem ? 'Analisando imagem...' : 'Confirmar e Analisar Imagem',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B4C8A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_analiseImagemStatus != AnaliseStatus.nenhuma) ...[
                      const SizedBox(height: 16),
                      _buildAnaliseResultImagem(
                        status: _analiseImagemStatus,
                        explicacao: _analiseImagemTexto,
                        alertas: _alertasImagemEncontrados,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── DIVISOR ────────────────────────────────────────
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── NOVOS GOLPES ───────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Novos golpes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lendo notícias em voz alta...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildNoticiaCard(
                titulo: 'Especialista dá dica para evitar cair em golpes virtuais',
                fonte: 'Jornal Nacional · TV Globo',
                data: '08 Abr 2026',
                iconeCategoria: Icons.live_tv,
              ),
              const SizedBox(height: 12),
              _buildNoticiaCard(
                titulo: 'Golpe do falso familiar no WhatsApp atinge milhares de idosos',
                fonte: 'G1 · Portal de Notícias',
                data: '06 Abr 2026',
                iconeCategoria: Icons.article_outlined,
              ),
              const SizedBox(height: 12),
              _buildNoticiaCard(
                titulo: 'Como identificar perfis falsos em redes sociais',
                fonte: 'Fantástico · TV Globo',
                data: '02 Abr 2026',
                iconeCategoria: Icons.live_tv,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGETS AUXILIARES ──────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData titleIcon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(titleIcon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAddButton({
    required String label,
    required VoidCallback onTap,
    required String helpText,
    required VoidCallback onHelpTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFAA8ED6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onHelpTap,
          child: Text(
            helpText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnexadoChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF6B4C8A), size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4C8A),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, color: Colors.black38, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAnaliseResultLink({
    required AnaliseStatus status,
    required String explicacao,
    required String urlSubmetida,
    required List<String> alertas,
  }) {
    if (status == AnaliseStatus.carregando) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Analisando o link com atenção...',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    Color bgColor;
    String statusTitle;
    IconData statusIcon;

    switch (status) {
      case AnaliseStatus.seguro:
        bgColor = const Color(0xFF2E7D32);
        statusTitle = 'LINK AVALIADO COMO CONFIÁVEL';
        statusIcon = Icons.check_circle_outline;
        break;
      case AnaliseStatus.suspeito:
        bgColor = const Color(0xFFE65100);
        statusTitle = 'POSSÍVEIS SINAIS DE RISCO ENCONTRADOS';
        statusIcon = Icons.warning_amber_outlined;
        break;
      case AnaliseStatus.naoSeguro:
        bgColor = const Color(0xFFC62828);
        statusTitle = 'RISCO ALTO DE GOLPE DETECTADO';
        statusIcon = Icons.dangerous_outlined;
        break;
      case AnaliseStatus.naoFoiPossivelAnalisar:
      default:
        bgColor = const Color(0xFF546E7A);
        statusTitle = 'NÃO FOI POSSÍVEL CONCLUIR A ANÁLISE';
        statusIcon = Icons.help_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(statusIcon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explicacao,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (alertas.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Pontos observados:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 6),
            ...alertas.map(
              (alerta) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '• $alerta',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                ),
              ),
            ),
          ],
          const Divider(color: Colors.white38, height: 24),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dica de Segurança: Nunca informe senhas, códigos de SMS ou dados bancários por links. Em caso de dúvida, ligue diretamente para os canais oficiais.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnaliseResultImagem({
    required AnaliseStatus status,
    required String explicacao,
    required List<String> alertas,
  }) {
    if (status == AnaliseStatus.carregando) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'A IA está analisando a imagem...',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    Color bgColor;
    String statusTitle;
    IconData icon;

    switch (status) {
      case AnaliseStatus.seguro:
        bgColor = const Color(0xFF2E7D32);
        statusTitle = 'IMAGEM AVALIADA COMO CONFIÁVEL';
        icon = Icons.check_circle_outline;
        break;
      case AnaliseStatus.suspeito:
        bgColor = const Color(0xFFE65100);
        statusTitle = 'MENSAGEM SUSPEITA IDENTIFICADA';
        icon = Icons.warning_amber_outlined;
        break;
      case AnaliseStatus.naoSeguro:
        bgColor = const Color(0xFFC62828);
        statusTitle = 'RISCO ALTO DE GOLPE NA IMAGEM';
        icon = Icons.dangerous_outlined;
        break;
      case AnaliseStatus.naoFoiPossivelAnalisar:
      default:
        bgColor = const Color(0xFF546E7A);
        statusTitle = 'NÃO FOI POSSÍVEL ANALISAR A IMAGEM';
        icon = Icons.help_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explicacao,
            style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
          ),
          if (alertas.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Pontos observados:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 6),
            ...alertas.map(
              (alerta) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '• $alerta',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                ),
              ),
            ),
          ],
          const Divider(color: Colors.white38, height: 24),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dica de Segurança: Desconfie sempre de pedidos de dinheiro por mensagem (mesmo de familiares) e de avisos de compras ou bloqueios que você não reconhece.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoticiaCard({
    required String titulo,
    required String fonte,
    required String data,
    required IconData iconeCategoria,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 85,
            decoration: const BoxDecoration(
              color: Color(0xFF6B4C8A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(iconeCategoria, color: Colors.white.withValues(alpha: 0.3), size: 48),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Color(0xFF6B4C8A), size: 24),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$fonte · $data',
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DicaItem extends StatelessWidget {
  final String numero;
  final String texto;
  const _DicaItem({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF9C72AD),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              numero,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ),
      ],
    );
  }
}
