import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medical_exam_model.dart';
import '../services/medical_exam_service.dart';
import '../services/user_session_service.dart';

/// Tela dedicada à Saúde do Idoso, Prontuário Clínico e Arquivo de Exames com Foto.
/// Acessada pelo Cuidador para acompanhar condições pré-existentes e laudos médicos.
class SaudeIdosoView extends StatefulWidget {
  const SaudeIdosoView({super.key});

  @override
  State<SaudeIdosoView> createState() => _SaudeIdosoViewState();
}

class _SaudeIdosoViewState extends State<SaudeIdosoView> {
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  List<MedicalExamModel> _exams = [];

  // Lista de doenças pré-existentes padrão para edição rápida
  final List<String> _todasDoencas = [
    'Hipertensão (pressão alta)',
    'Diabetes tipo 2',
    'Doenças cardiovasculares (infarto / insuficiência)',
    'AVC (derrame)',
    'Alzheimer',
    'Parkinson',
    'Osteoporose',
    'Osteoartrose',
    'Depressão',
    'Câncer',
    'Colesterol alto (dislipidemia)',
    'Doenças respiratórias (DPOC / bronquite)',
    'Insuficiência renal',
    'Infecção urinária frequente',
    'Catarata e problemas de visão',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    // Atualiza perfil em segundo plano caso online
    await UserSessionService.instance.refreshFromServer();

    final session = UserSessionService.instance;
    final seniorId = session.partnerUser?.id ??
        session.activeLink?.seniorId ??
        'senior_local';
    final code = session.partnerUser?.connectionCode ??
        session.activeLink?.connectionCode ??
        session.currentUser.connectionCode ??
        '';

    final list = await MedicalExamService.instance.getExams(
      seniorId: seniorId,
      connectionCode: code,
    );

    if (mounted) {
      setState(() {
        _exams = list;
        _isLoading = false;
      });
    }
  }

  /// Retorna a lista de doenças do idoso extraídas do perfil
  List<String> _obterDoencasIdoso() {
    final session = UserSessionService.instance;
    final raw = session.partnerUser?.doencasCronicas ??
        session.currentUser.doencasCronicas ??
        '';

    if (raw.trim().isEmpty) return [];

    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Abre diálogo para editar doenças pré-existentes
  Future<void> _abrirDialogEditarDoencas() async {
    final atuais = _obterDoencasIdoso();
    final Map<String, bool> selecoes = {};

    for (final d in _todasDoencas) {
      selecoes[d] = atuais.any((item) =>
          item.toLowerCase().contains(d.toLowerCase()) ||
          d.toLowerCase().contains(item.toLowerCase()));
    }

    final customController = TextEditingController();
    // Doenças extras que não estavam na lista padrão
    final extras = atuais
        .where((item) => !_todasDoencas.any((d) =>
            item.toLowerCase().contains(d.toLowerCase()) ||
            d.toLowerCase().contains(item.toLowerCase())))
        .toList();
    if (extras.isNotEmpty) {
      customController.text = extras.join(', ');
    }

    final bool? salvo = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.82,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.healing_rounded,
                            color: Color(0xFFF97316),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Condições Pré-existentes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecione as condições médicas do idoso para acompanhamento clínico:',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ..._todasDoencas.map((doenca) {
                            final selecionada = selecoes[doenca] ?? false;
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  selecoes[doenca] = !selecionada;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selecionada
                                      ? const Color(0xFFEA580C).withValues(alpha: 0.15)
                                      : const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selecionada
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selecionada
                                          ? Icons.check_box_rounded
                                          : Icons.check_box_outline_blank_rounded,
                                      color: selecionada
                                          ? const Color(0xFFF97316)
                                          : const Color(0xFF64748B),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        doenca,
                                        style: TextStyle(
                                          color: selecionada
                                              ? Colors.white
                                              : const Color(0xFFCBD5E1),
                                          fontSize: 13.5,
                                          fontWeight: selecionada
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                          const Text(
                            'Outras condições ou observações adicionais:',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: customController,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Ex: Alergia a Penicilina, Prótese no fêmur',
                              hintStyle: const TextStyle(color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF334155)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF334155)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFF97316)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final List<String> finalDoencas = [];
                          selecoes.forEach((k, v) {
                            if (v) finalDoencas.add(k);
                          });

                          final extrasText = customController.text.trim();
                          if (extrasText.isNotEmpty) {
                            final customItems = extrasText
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty);
                            for (final c in customItems) {
                              if (!finalDoencas.contains(c)) {
                                finalDoencas.add(c);
                              }
                            }
                          }

                          Navigator.pop(ctx, true);
                          _salvarDoencas(finalDoencas);
                        },
                        child: const Text(
                          'Salvar Condições de Saúde',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (salvo == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _salvarDoencas(List<String> doencas) async {
    final str = doencas.join(', ');
    await UserSessionService.instance.updateProfile(doencasCronicas: str);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Condições de saúde atualizadas e sincronizadas com sucesso!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      setState(() {});
    }
  }

  /// Abre o modal para adicionar um novo exame com foto
  Future<void> _abrirModalAdicionarExame() async {
    final tituloController = TextEditingController();
    final medicoController = TextEditingController();
    final obsController = TextEditingController();
    String categoriaSelecionada = 'Geral';
    DateTime dataSelecionada = DateTime.now();
    String? fotoBase64;

    final List<String> categorias = [
      'Geral',
      'Sangue',
      'Imagem / Raio-X',
      'Cardiológico',
      'Urina / Fezes',
      'Consulta / Laudo',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String formatarData(DateTime dt) {
              return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
            }

            Future<void> escolherFoto(ImageSource source) async {
              try {
                final XFile? file = await _picker.pickImage(
                  source: source,
                  imageQuality: 82,
                  maxWidth: 1280,
                );
                if (file != null) {
                  final bytes = await file.readAsBytes();
                  setModalState(() {
                    fotoBase64 = base64Encode(bytes);
                  });
                }
              } catch (e) {
                debugPrint('Erro ao selecionar foto do exame: $e');
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.post_add_rounded,
                            color: Color(0xFF38BDF8),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Novo Exame ou Laudo Médico',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView(
                        children: [
                          // Título do Exame
                          const Text(
                            'Nome / Tipo do Exame *',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: tituloController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Ex: Hemograma, Tomografia, ECG',
                              hintStyle: const TextStyle(color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF334155)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF334155)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Categoria
                          const Text(
                            'Categoria do Exame',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categorias.map((cat) {
                              final sel = cat == categoriaSelecionada;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: sel,
                                selectedColor: const Color(0xFF0284C7),
                                backgroundColor: const Color(0xFF0F172A),
                                labelStyle: TextStyle(
                                  color: sel ? Colors.white : const Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: sel ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                                ),
                                onSelected: (_) {
                                  setModalState(() => categoriaSelecionada = cat);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Data do Exame
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Data do Exame',
                                      style: TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: dataSelecionada,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                          builder: (context, child) {
                                            return Theme(
                                              data: ThemeData.dark().copyWith(
                                                colorScheme: const ColorScheme.dark(
                                                  primary: Color(0xFF38BDF8),
                                                  surface: Color(0xFF1E293B),
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          setModalState(() => dataSelecionada = picked);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF334155)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              formatarData(dataSelecionada),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              color: Color(0xFF38BDF8),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Médico / Laboratório',
                                      style: TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: medicoController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                      decoration: InputDecoration(
                                        hintText: 'Ex: Dr. Roberto / Fleury',
                                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                        filled: true,
                                        fillColor: const Color(0xFF0F172A),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFF334155)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFF334155)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Observações / Resultados
                          const Text(
                            'Laudo / Observações do Exame',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: obsController,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Ex: Taxas de glicemia dentro da meta. Retornar em 6 meses com novo exame.',
                              hintStyle: const TextStyle(color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF334155)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF334155)),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── FOTO DO EXAME ────────────────────────────────
                          const Text(
                            'Foto do Exame / Laudo',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (fotoBase64 == null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF334155),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Color(0xFF94A3B8),
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Fotografe ou anexe a foto do laudo médico',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0284C7),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                          label: const Text('Câmera', style: TextStyle(fontSize: 12.5)),
                                          onPressed: () => escolherFoto(ImageSource.camera),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF38BDF8),
                                            side: const BorderSide(color: Color(0xFF0284C7)),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(Icons.photo_library_rounded, size: 18),
                                          label: const Text('Galeria', style: TextStyle(fontSize: 12.5)),
                                          onPressed: () => escolherFoto(ImageSource.gallery),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(fotoBase64!),
                                      height: 170,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF38BDF8)),
                                        label: const Text('Trocar Foto', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                                        onPressed: () => escolherFoto(ImageSource.camera),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                        label: const Text('Remover', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                        onPressed: () {
                                          setModalState(() {
                                            fotoBase64 = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final titulo = tituloController.text.trim();
                          if (titulo.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor, informe o nome do exame.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          final session = UserSessionService.instance;
                          final seniorId = session.partnerUser?.id ??
                              session.activeLink?.seniorId ??
                              'senior_local';
                          final code = session.partnerUser?.connectionCode ??
                              session.activeLink?.connectionCode ??
                              session.currentUser.connectionCode ??
                              '';

                          final novoExame = MedicalExamModel(
                            id: 'ex_${DateTime.now().millisecondsSinceEpoch}',
                            seniorId: seniorId,
                            codigoVinculo: code,
                            titulo: titulo,
                            categoria: categoriaSelecionada,
                            dataExame: formatarData(dataSelecionada),
                            medicoLaboratorio: medicoController.text.trim(),
                            observacoes: obsController.text.trim(),
                            imagemBase64: fotoBase64,
                            criadoEm: DateTime.now(),
                          );

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);

                          setState(() => _isLoading = true);
                          await MedicalExamService.instance.saveExam(novoExame);
                          await _carregarDados();

                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Exame médico arquivado com sucesso!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Salvar e Guardar Exame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Visualizador da imagem do exame em tela cheia com zoom interativo
  void _mostrarImagemEmTelaCheia(String base64Img, String titulo) {
    try {
      final bytes = base64Decode(base64Img);
      showDialog(
        context: context,
        builder: (ctx) {
          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(0),
            child: Stack(
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text(
                          'Não foi possível renderizar a imagem',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Erro ao abrir visualizador de imagem: $e');
    }
  }

  /// Exclui o exame selecionado
  Future<void> _excluirExame(MedicalExamModel exam) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Excluir Exame',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Deseja realmente remover o exame "${exam.titulo}"? Esta ação não pode ser desfeita.',
            style: const TextStyle(color: Color(0xFFCBD5E1)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      await MedicalExamService.instance.deleteExam(
        exam.id,
        seniorId: exam.seniorId,
        connectionCode: exam.codigoVinculo,
      );
      await _carregarDados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exame excluído com sucesso.'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  Color _corCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'sangue':
        return const Color(0xFFEF4444);
      case 'imagem / raio-x':
      case 'imagem':
        return const Color(0xFF3B82F6);
      case 'cardiológico':
        return const Color(0xFF8B5CF6);
      case 'urina / fezes':
        return const Color(0xFFF59E0B);
      case 'consulta / laudo':
      case 'consulta':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionService.instance;
    final seniorName = session.partnerUser?.name ??
        session.activeLink?.seniorName ??
        'Idoso Monitorado';
    final code = session.partnerUser?.connectionCode ??
        session.activeLink?.connectionCode ??
        session.currentUser.connectionCode ??
        '';
    final dataNasc = session.partnerUser?.dataNascimento ??
        session.currentUser.dataNascimento ??
        '';
    final phone = session.partnerUser?.phone ??
        session.partnerUser?.emergencyPhone ??
        session.currentUser.emergencyPhone ??
        '';

    final doencas = _obterDoencasIdoso();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saúde do Idoso',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Prontuário & Arquivo de Exames',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'Sincronizar com Banco de Dados',
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)),
            )
          : RefreshIndicator(
              color: const Color(0xFFF97316),
              backgroundColor: const Color(0xFF1E293B),
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // ── 1. CABEÇALHO RESUMO DO IDOSO MONITORADO ────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF172554)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFF97316), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.elderly_rounded,
                                color: Color(0xFFF97316),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    seniorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Monitoramento Ativo',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (code.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF38BDF8)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.vpn_key_rounded,
                                      color: Color(0xFF38BDF8),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      code,
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (dataNasc.isNotEmpty || phone.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF334155), height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (dataNasc.isNotEmpty) ...[
                                const Icon(Icons.cake_outlined, color: Color(0xFF94A3B8), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Nasc: $dataNasc',
                                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                                ),
                                const SizedBox(width: 14),
                              ],
                              if (phone.isNotEmpty) ...[
                                const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    phone,
                                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 2. SEÇÃO DE DOENÇAS PRÉ-EXISTENTES ───────────────────────
                  Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.health_and_safety_rounded,
                                    color: Color(0xFFF97316),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Condições Pré-existentes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFF97316),
                                side: const BorderSide(color: Color(0xFFEA580C)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.edit_note_rounded, size: 16),
                              label: const Text('Editar', style: TextStyle(fontSize: 12)),
                              onPressed: _abrirDialogEditarDoencas,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Informadas pelo cuidador no cadastro do idoso',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        const SizedBox(height: 12),

                        if (doencas.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Nenhuma doença informada ainda. Toque em "Editar" para registrar diagnósticos como Hipertensão, Diabetes, etc.',
                                    style: TextStyle(color: Colors.blueGrey.shade200, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: doencas.map((doenca) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.medical_information_rounded,
                                      color: Color(0xFFF97316),
                                      size: 15,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        doenca,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 3. CABEÇALHO DA SEÇÃO DE EXAMES MÉDICOS ─────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.assignment_rounded,
                              color: Color(0xFF38BDF8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Exames & Laudos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_exams.length}',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 17),
                        label: const Text(
                          '+ Adicionar Exame',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _abrirModalAdicionarExame,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── 4. LISTA DE EXAMES SALVOS ──────────────────────────────
                  if (_exams.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: const Icon(
                              Icons.document_scanner_outlined,
                              color: Color(0xFF64748B),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Nenhum exame anexado ainda',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Guarde fotos de exames de sangue, laudos de raio-X, receitas e eletrocardiogramas para tê-los sempre à mão.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.camera_alt_rounded, size: 16),
                            label: const Text('Fotografar Primeiro Exame'),
                            onPressed: _abrirModalAdicionarExame,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._exams.map((exam) {
                      final corCat = _corCategoria(exam.categoria);
                      final bool temFoto = exam.hasImage && exam.imagemBase64 != null && exam.imagemBase64!.isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Topo do card
                            Padding(
                              padding: const EdgeInsets.only(left: 14, right: 8, top: 12, bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: corCat.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: corCat.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          exam.categoria,
                                          style: TextStyle(
                                            color: corCat,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.event_outlined, color: Color(0xFF94A3B8), size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            exam.dataExame,
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    tooltip: 'Excluir Exame',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _excluirExame(exam),
                                  ),
                                ],
                              ),
                            ),

                            // Título do Exame
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                exam.titulo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Médico ou Laboratório
                            if (exam.medicoLaboratorio.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_hospital_outlined, color: Color(0xFF38BDF8), size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        exam.medicoLaboratorio,
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Laudo / Observações
                            if (exam.observacoes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 14, right: 14, top: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    exam.observacoes,
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),

                            // Foto Anexada
                            if (temFoto) ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: InkWell(
                                  onTap: () => _mostrarImagemEmTelaCheia(
                                    exam.imagemBase64!,
                                    exam.titulo,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.memory(
                                          base64Decode(exam.imagemBase64!),
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.85),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                                            SizedBox(width: 6),
                                            Text(
                                              'Toque para ampliar o laudo em tela cheia',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
