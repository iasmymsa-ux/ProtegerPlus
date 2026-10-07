import 'package:flutter/material.dart';
import '../app_theme_manager.dart';

class ProfileView extends StatefulWidget {
  final String profile; // 'Cuidador' or 'Usuario'

  const ProfileView({super.key, required this.profile});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // Configs de permissão
  bool get _isCaregiver => widget.profile == 'Cuidador';
  
  bool _isEditingCuidador = false;
  bool _isEditingUsuario = false;

  // Opções de Configuração
  // Não usa variáveis locais mais, usa o AppThemeManager.

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Configurações'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tamanho da Fonte:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: AppThemeManager.instance.fontScale,
                    min: 0.8,
                    max: 1.5,
                    onChanged: (val) {
                      setDialogState(() {
                        AppThemeManager.instance.setFontScale(val);
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Cor de Fundo:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            AppThemeManager.instance.setBackgroundColor(const Color(0xFFE4B1FA)); // Lilás claro (Padrão)
                          });
                          setState(() {});
                        },
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFE4B1FA),
                          child: AppThemeManager.instance.backgroundColor == const Color(0xFFE4B1FA) ? const Icon(Icons.check, color: Colors.black) : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            AppThemeManager.instance.setBackgroundColor(const Color(0xFFB3E5FC)); // Azul Bebê
                          });
                          setState(() {});
                        },
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFB3E5FC),
                          child: AppThemeManager.instance.backgroundColor == const Color(0xFFB3E5FC) ? const Icon(Icons.check, color: Colors.black) : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('FECHAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onEditPressed() {
    setState(() {
      if (_isCaregiver) {
        // Cuidador pode editar ambos
        _isEditingCuidador = !_isEditingCuidador;
        _isEditingUsuario = !_isEditingUsuario;
      } else {
        // Usuário só pode editar o próprio perfil
        _isEditingUsuario = !_isEditingUsuario;
      }
    });

    final editStatus = _isEditingCuidador || _isEditingUsuario;
    
    // Mostra um snackbar informando o modo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          editStatus 
            ? (_isCaregiver ? 'Modo de edição ativado para ambos os perfis.' : 'Modo de edição ativado para seu perfil.')
            : 'Modo de edição desativado.'
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeManager.instance.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 36),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'serif',
                        color: Colors.black,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _onEditPressed,
                      style: ElevatedButton.styleFrom(
                         // Cor do botão EDITAR
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: const Text('EDITAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.black, size: 36),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _showSettingsDialog,
                        ),
                        const SizedBox(height: 4),
                        const Text('Configurações', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Body - Split View
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Coluna Cuidador
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 12, right: 8, bottom: 24),
                      child: _buildProfileColumn(
                        isCuidadorSection: true,
                        title: 'Cuidador: Luciene\nAparecida de\nAlmeida',
                        cidade: 'Juatuba',
                        dataNascimento: '11/10/1979',
                        telefone: '(31)\n99976-4532',
                        isEditing: _isEditingCuidador,
                      ),
                    ),
                  ),
                  
                  // Dashed Central Line substituída por Container com largura
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(1, constraints.maxHeight),
                        painter: DashedLinePainter(),
                      );
                    }
                  ),
                  
                  // Coluna Usuário
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 8, right: 12, bottom: 24),
                      child: _buildProfileColumn(
                        isCuidadorSection: false,
                        title: 'Usuário: Maria\nHelena de\nAlmeida',
                        cidade: 'Juatuba',
                        dataNascimento: '10/06/1949',
                        telefone: '(31)\n99844-6228',
                        isEditing: _isEditingUsuario,
                        doencasCronicas: 'Diabetes e Pressão\nalta',
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

  Widget _buildProfileColumn({
    required bool isCuidadorSection,
    required String title,
    required String cidade,
    required String dataNascimento,
    required String telefone,
    required bool isEditing,
    String? doencasCronicas,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar circle
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2.5),
            color: Colors.white,
          ),
          child: Icon(
            isCuidadorSection ? Icons.face : Icons.person,
            size: 70,
            color: Colors.black.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black, height: 1.2),
        ),
        const SizedBox(height: 24),
        
        _buildInfoItem(Icons.location_on_outlined, 'Localidade', 'Cidade: ', cidade, isEditing),
        _buildInfoItem(Icons.person_outline, 'Data de\nnascimento:', '', dataNascimento, isEditing),
        _buildInfoItem(Icons.phone_outlined, 'Telefone', 'Número: ', telefone, isEditing),
        
        if (doencasCronicas != null)
          _buildInfoItem(Icons.medical_services_outlined, 'Doenças\nCrônicas', '', doencasCronicas, isEditing),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String prefix, String value, bool isEditing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black, size: 22),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (isEditing)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: TextFormField(
                initialValue: value.replaceAll('\n', ' '),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            )
          else
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Colors.black, height: 1.3),
                children: [
                  if (prefix.isNotEmpty)
                    TextSpan(text: prefix, style: const TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(text: value),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 4, startY = 0;
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
