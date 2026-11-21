import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medical_exam_model.dart';
import '../services/medical_exam_service.dart';
import '../services/user_session_service.dart';
import '../app_theme_manager.dart';

/// Tela dedicada à Saúde do Idoso, Prontuário Clínico e Arquivo de Exames com Foto.
/// Acessada pelo Cuidador para acompanhar condições pré-existentes e laudos médicos.
/// Design padronizado 100% com a identidade visual clara e acessível do Proteger+.
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

  /// Abre diálogo para editar doenças pré-existentes com tema claro
  Future<void> _abrirDialogEditarDoencas() async {
    final atuais = _obterDoencasIdoso();
    final Map<String, bool> selecoes = {};

    for (final d in _todasDoencas) {
      selecoes[d] = atuais.any((item) =>
          item.toLowerCase().contains(d.toLowerCase()) ||
          d.toLowerCase().contains(item.toLowerCase()));
    }

    // Preserva doenças personalizadas que não estão na lista fixa
    final personalizadas = atuais.where((item) => !_todasDoencas.any((d) =>
        item.toLowerCase().contains(d.toLowerCase()) ||
        d.toLowerCase().contains(item.toLowerCase()))).toList();

    final novaDoencaController = TextEditingController();

    final salvo = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppThemeManager.instance.borderColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.healing_rounded,
                      color: AppThemeManager.instance.borderColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Condições de Saúde',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Marque as doenças e diagnósticos do idoso:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._todasDoencas.map((d) {
                        final marcado = selecoes[d] ?? false;
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppThemeManager.instance.borderColor,
                          title: Text(
                            d,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: marcado ? FontWeight.bold : FontWeight.normal,
                              color: marcado ? Colors.black87 : Colors.black54,
                            ),
                          ),
                          value: marcado,
                          onChanged: (val) {
                            setDialogState(() {
                              selecoes[d] = val ?? false;
                            });
                          },
                        );
                      }),
                      if (personalizadas.isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text(
                          'Outras condições registradas:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: personalizadas.map((p) {
                            return Chip(
                              backgroundColor: Colors.grey.shade100,
                              label: Text(p, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setDialogState(() {
                                  personalizadas.remove(p);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: novaDoencaController,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Outra condição...',
                                isDense: true,
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: AppThemeManager.instance.borderColor),
                            onPressed: () {
                              final txt = novaDoencaController.text.trim();
                              if (txt.isNotEmpty && !personalizadas.contains(txt)) {
                                setDialogState(() {
                                  personalizadas.add(txt);
                                  novaDoencaController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeManager.instance.borderColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final selecionadas = selecoes.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();
                    selecionadas.addAll(personalizadas);

                    Navigator.pop(ctx, true);
                    await _salvarDoencas(selecionadas);
                  },
                  child: const Text('Salvar'),
                ),
              ],
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Condições de saúde atualizadas com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {});
    }
  }

  /// Abre o modal para adicionar um novo exame com foto (Tema Claro)
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
      backgroundColor: Colors.white,
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
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
                              color: AppThemeManager.instance.borderColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.post_add_rounded,
                              color: AppThemeManager.instance.borderColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Novo Exame ou Laudo Médico',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Título do exame
                      const Text(
                        'Nome do Exame *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: tituloController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ex: Hemograma completo, Tomografia, etc.',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Categoria
                      const Text(
                        'Categoria do Exame',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: categorias.map((cat) {
                          final sel = cat == categoriaSelecionada;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: sel,
                            selectedColor: AppThemeManager.instance.borderColor,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: sel ? Colors.white : Colors.black87,
                              fontSize: 12,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) => setModalState(() => categoriaSelecionada = cat),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Data e Médico
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Data do Exame',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
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
                                    );
                                    if (picked != null) {
                                      setModalState(() => dataSelecionada = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formatarData(dataSelecionada),
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: medicoController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Ex: Fleury, Dr. Silva',
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Observações
                      const Text(
                        'Observações e Laudo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: obsController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Informações relevantes, dosagens ou orientações do médico...',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Foto do Exame
                      const Text(
                        'Foto do Exame / Laudo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (fotoBase64 == null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey.shade500),
                              const SizedBox(height: 8),
                              const Text(
                                'Fotografe ou anexe a foto do laudo ou receita médica',
                                style: TextStyle(color: Colors.black54, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppThemeManager.instance.borderColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.camera_alt, size: 18),
                                      label: const Text('Câmera'),
                                      onPressed: () => escolherFoto(ImageSource.camera),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppThemeManager.instance.borderColor,
                                        side: BorderSide(color: AppThemeManager.instance.borderColor),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.photo_library, size: 18),
                                      label: const Text('Galeria'),
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
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(fotoBase64!),
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton.icon(
                                    icon: Icon(Icons.refresh, size: 16, color: AppThemeManager.instance.borderColor),
                                    label: Text('Trocar Foto', style: TextStyle(color: AppThemeManager.instance.borderColor, fontSize: 13)),
                                    onPressed: () => escolherFoto(ImageSource.camera),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    label: const Text('Remover', style: TextStyle(color: Colors.red, fontSize: 13)),
                                    onPressed: () => setModalState(() => fotoBase64 = null),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeManager.instance.borderColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final titulo = tituloController.text.trim();
                            if (titulo.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor, informe o nome do exame.'),
                                  backgroundColor: Colors.red,
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
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Exame médico arquivado com sucesso!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Salvar Exame',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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
                          'Não foi possível carregar a imagem',
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          titulo,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
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

  Future<void> _excluirExame(MedicalExamModel exam) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Excluir Exame', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          content: Text('Deseja realmente remover o exame "${exam.titulo}"? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir'),
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
          SnackBar(
            content: const Text('Exame excluído com sucesso.'),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Color _corCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'sangue':
        return const Color(0xFFDC2626);
      case 'imagem / raio-x':
      case 'imagem':
        return const Color(0xFF2563EB);
      case 'cardiológico':
        return const Color(0xFF7C3AED);
      case 'urina / fezes':
        return const Color(0xFFD97706);
      case 'consulta / laudo':
      case 'consulta':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF0284C7);
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
      backgroundColor: AppThemeManager.instance.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saúde do Idoso',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'serif',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.sync, color: AppThemeManager.instance.borderColor),
            tooltip: 'Sincronizar dados',
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppThemeManager.instance.borderColor),
            )
          : RefreshIndicator(
              color: AppThemeManager.instance.borderColor,
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // ── 1. CABEÇALHO RESUMO DO IDOSO MONITORADO (Tema Claro) ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppThemeManager.instance.secondaryColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppThemeManager.instance.borderColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
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
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppThemeManager.instance.borderColor,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.elderly_rounded,
                                color: AppThemeManager.instance.borderColor,
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
                                      color: Colors.black87,
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
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Prontuário Ativo',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (code.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppThemeManager.instance.borderColor.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  code,
                                  style: TextStyle(
                                    color: AppThemeManager.instance.borderColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (dataNasc.isNotEmpty || phone.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey.shade300, height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (dataNasc.isNotEmpty) ...[
                                const Icon(Icons.cake_outlined, color: Colors.black54, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  'Nasc: $dataNasc',
                                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                                ),
                                const SizedBox(width: 14),
                              ],
                              if (phone.isNotEmpty) ...[
                                const Icon(Icons.phone_outlined, color: Colors.black54, size: 15),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    phone,
                                    style: const TextStyle(color: Colors.black87, fontSize: 12),
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

                  const SizedBox(height: 18),

                  // ── 2. SEÇÃO DE DOENÇAS PRÉ-EXISTENTES (Tema Claro) ───────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppThemeManager.instance.secondaryColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppThemeManager.instance.borderColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.health_and_safety_rounded,
                                  color: AppThemeManager.instance.borderColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Condições Pré-existentes',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppThemeManager.instance.borderColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Editar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              onPressed: _abrirDialogEditarDoencas,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Informadas pelo cuidador no cadastro do idoso',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 12),

                        if (doencas.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Nenhuma condição informada ainda. Toque em "Editar" para registrar diagnósticos como Hipertensão, Diabetes, etc.',
                                    style: TextStyle(color: Colors.black87, fontSize: 12),
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppThemeManager.instance.borderColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: AppThemeManager.instance.borderColor,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      doenca,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
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

                  const SizedBox(height: 22),

                  // ── 3. SEÇÃO DE EXAMES E LAUDOS MÉDICOS COM FOTO ──────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            color: AppThemeManager.instance.borderColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Exames & Laudos',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppThemeManager.instance.secondaryColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppThemeManager.instance.borderColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${_exams.length}',
                              style: TextStyle(
                                color: AppThemeManager.instance.borderColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeManager.instance.borderColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: const Text(
                          '+ Adicionar Exame',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _abrirModalAdicionarExame,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── 4. LISTA DE EXAMES SALVOS (Tema Claro) ────────────────
                  if (_exams.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppThemeManager.instance.secondaryColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppThemeManager.instance.borderColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppThemeManager.instance.borderColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.document_scanner_outlined,
                              color: AppThemeManager.instance.borderColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Nenhum exame anexado ainda',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Guarde fotos de exames de sangue, laudos de raio-X, receitas e eletrocardiogramas para tê-los sempre à mão.',
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemeManager.instance.borderColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.camera_alt, size: 16),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                          color: corCat.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: corCat.withValues(alpha: 0.4)),
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
                                          const Icon(Icons.event, color: Colors.black54, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            exam.dataExame,
                                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    tooltip: 'Excluir Exame',
                                    onPressed: () => _excluirExame(exam),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                exam.titulo,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            if (exam.medicoLaboratorio.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.local_hospital_outlined, color: AppThemeManager.instance.borderColor, size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        exam.medicoLaboratorio,
                                        style: TextStyle(
                                          color: AppThemeManager.instance.borderColor,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (exam.observacoes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 14, right: 14, top: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Text(
                                    exam.observacoes,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),

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
                                              Colors.black.withValues(alpha: 0.8),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.zoom_in, color: Colors.white, size: 16),
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
