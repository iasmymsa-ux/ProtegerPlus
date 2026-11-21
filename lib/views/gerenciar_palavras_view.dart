import 'package:flutter/material.dart';
import '../services/alert_sync_service.dart';
import '../services/user_session_service.dart';
import '../services/voice_alert_service.dart';

class GerenciarPalavrasView extends StatefulWidget {
  const GerenciarPalavrasView({super.key});

  @override
  State<GerenciarPalavrasView> createState() => _GerenciarPalavrasViewState();
}

class _GerenciarPalavrasViewState extends State<GerenciarPalavrasView> {
  final TextEditingController _palavraController = TextEditingController();
  List<String> _palavras = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarPalavras();
  }

  @override
  void dispose() {
    _palavraController.dispose();
    super.dispose();
  }

  Future<void> _carregarPalavras() async {
    setState(() => _isLoading = true);
    final session = UserSessionService.instance;
    final codigo = session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.currentUser.connectionCode ??
        '';

    List<String> lista = [];
    if (codigo.isNotEmpty) {
      lista = await AlertSyncService.instance.obterPalavrasAlerta(codigo: codigo);
    }

    if (lista.isEmpty) {
      // Carrega a lista base padrão se ainda não houver customização
      lista = List.from(VoiceAlertService.defaultKeywords.take(15));
    }

    if (mounted) {
      setState(() {
        _palavras = lista;
        _isLoading = false;
      });
    }
  }

  Future<void> _salvarNoServidor() async {
    final session = UserSessionService.instance;
    final codigo = session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.currentUser.connectionCode ??
        '';

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código de vínculo com o idoso não encontrado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final ok = await AlertSyncService.instance.salvarPalavrasAlerta(
      codigo: codigo,
      palavras: _palavras,
      seniorId: session.partnerUser?.id,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Palavras de alerta atualizadas com sucesso para o idoso!'
                : 'Salvo localmente (servidor em sincronização).',
          ),
          backgroundColor: ok ? const Color(0xFF16A34A) : Colors.orange.shade800,
        ),
      );
    }
  }

  void _adicionarPalavra() {
    final text = _palavraController.text.trim().toLowerCase();
    if (text.isEmpty) return;

    if (_palavras.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta palavra já está na lista!')),
      );
      return;
    }

    setState(() {
      _palavras.insert(0, text);
      _palavraController.clear();
    });

    _salvarNoServidor();
  }

  void _removerPalavra(String palavra) {
    setState(() {
      _palavras.remove(palavra);
    });
    _salvarNoServidor();
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionService.instance;
    final idosoNome = session.partnerUser?.name ?? 'Idoso Monitorado';
    final codigo = session.activeLink?.connectionCode ??
        session.partnerUser?.connectionCode ??
        session.currentUser.connectionCode ??
        'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fundo Navy Slate de Administrador
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Palavras de Alerta por Voz',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Painel do Cuidador • Administrador',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _carregarPalavras,
              tooltip: 'Recarregar palavras do servidor',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card de informações do idoso monitorado
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: Color(0xFF38BDF8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monitorando: $idosoNome',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Código de vínculo: $codigo',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quando o idoso pronunciar qualquer uma dessas palavras no aparelho dele, você receberá um alerta imediato de socorro.',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Campo para adicionar nova palavra
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _palavraController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ex: "dor no peito", "socorro", "caí"...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB)),
                        ),
                      ),
                      onSubmitted: (_) => _adicionarPalavra(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _adicionarPalavra,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Adicionar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Título da lista
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Palavras ativas (${_palavras.length})',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isSaving)
                    const Text(
                      'Sincronizando...',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Lista de palavras cadastradas
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                    )
                  : _palavras.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma palavra cadastrada ainda.\nAdicione palavras de emergência acima.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _palavras.length,
                          itemBuilder: (ctx, index) {
                            final palavra = _palavras[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mic,
                                    color: Color(0xFF38BDF8),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  palavra,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFEF4444),
                                  ),
                                  onPressed: () => _removerPalavra(palavra),
                                  tooltip: 'Remover palavra',
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

