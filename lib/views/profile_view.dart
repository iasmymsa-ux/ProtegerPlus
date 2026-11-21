import 'package:flutter/material.dart';
import 'configuracoes_view.dart';
import 'initial_view.dart';
import 'saude_idoso_view.dart';
import '../app_theme_manager.dart';
import '../services/user_session_service.dart';

class ProfileView extends StatefulWidget {
  final String profile; // 'Cuidador' or 'Usuario'

  const ProfileView({super.key, required this.profile});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isEditing = false;
  bool _isSaving = false;

  late final TextEditingController _nameController;
  late final TextEditingController _cidadeController;
  late final TextEditingController _dataNascimentoController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _doencasController;

  @override
  void initState() {
    super.initState();
    final user = UserSessionService.instance.currentUser;
    final partner = UserSessionService.instance.partnerUser;
    _nameController = TextEditingController(text: user.name);
    _cidadeController = TextEditingController(text: user.localidade ?? '');
    _dataNascimentoController = TextEditingController(text: user.dataNascimento ?? '');
    _telefoneController = TextEditingController(text: user.phone ?? '');
    
    // As informações de saúde pertencem ao idoso, preenchidas/gerenciadas pelo cuidador
    _doencasController = TextEditingController(
      text: user.isCaregiver
          ? (partner?.doencasCronicas ?? user.doencasCronicas ?? '')
          : (user.doencasCronicas ?? partner?.doencasCronicas ?? ''),
    );

    // Atualiza do servidor em background caso esteja online
    UserSessionService.instance.refreshFromServer().then((_) {
      if (mounted) {
        final u = UserSessionService.instance.currentUser;
        final p = UserSessionService.instance.partnerUser;
        _nameController.text = u.name;
        _cidadeController.text = u.localidade ?? '';
        _dataNascimentoController.text = u.dataNascimento ?? '';
        _telefoneController.text = u.phone ?? '';
        _doencasController.text = u.isCaregiver
            ? (p?.doencasCronicas ?? u.doencasCronicas ?? '')
            : (u.doencasCronicas ?? p?.doencasCronicas ?? '');
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cidadeController.dispose();
    _dataNascimentoController.dispose();
    _telefoneController.dispose();
    _doencasController.dispose();
    super.dispose();
  }

  Future<void> _onEditPressed() async {
    if (_isEditing) {
      // Salva as alterações
      setState(() => _isSaving = true);
      await UserSessionService.instance.updateProfile(
        name: _nameController.text.trim(),
        localidade: _cidadeController.text.trim(),
        dataNascimento: _dataNascimentoController.text.trim(),
        phone: _telefoneController.text.trim(),
        doencasCronicas: _doencasController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Color(0xFF9C72AD),
          ),
        );
      }
    } else {
      setState(() {
        _isEditing = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo de edição ativado. Altere os campos e clique em SALVAR.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await UserSessionService.instance.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InitialView()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Excluir conta permanentemente',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Atenção: esta ação é irreversível!\n\n'
          'Todos os seus dados cadastrais, lembretes, conversas e vínculos serão excluídos definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Definitivamente', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final res = await UserSessionService.instance.deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['mensagem'] ?? 'Conta excluída com sucesso.'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InitialView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserSessionService.instance,
      builder: (context, _) {
        final currentUser = UserSessionService.instance.currentUser;
        final partner = UserSessionService.instance.partnerUser;

        final isUserCaregiver = currentUser.isCaregiver;

        // Dados do Cuidador
        final cuidadorNome = isUserCaregiver
            ? (_isEditing ? _nameController.text : currentUser.name)
            : (currentUser.caregiverName?.isNotEmpty == true
                ? currentUser.caregiverName!
                : (partner?.name ?? 'Não vinculado'));

        final cuidadorCidade = isUserCaregiver
            ? (_isEditing ? _cidadeController.text : (currentUser.localidade ?? 'Não informado'))
            : (partner?.localidade ?? '-');

        final cuidadorDataNasc = isUserCaregiver
            ? (_isEditing ? _dataNascimentoController.text : (currentUser.dataNascimento ?? 'Não informado'))
            : (partner?.dataNascimento ?? '-');

        final cuidadorTelefone = isUserCaregiver
            ? (_isEditing ? _telefoneController.text : (currentUser.phone ?? 'Não informado'))
            : (currentUser.caregiverPhone?.isNotEmpty == true
                ? currentUser.caregiverPhone!
                : (partner?.phone ?? '-'));

        // Dados do Idoso
        final idosoNome = !isUserCaregiver
            ? (_isEditing ? _nameController.text : currentUser.name)
            : (partner?.name ?? 'Idoso vinculado');

        final idosoCidade = !isUserCaregiver
            ? (_isEditing ? _cidadeController.text : (currentUser.localidade ?? 'Não informado'))
            : (partner?.localidade ?? '-');

        final idosoDataNasc = !isUserCaregiver
            ? (_isEditing ? _dataNascimentoController.text : (currentUser.dataNascimento ?? 'Não informado'))
            : (partner?.dataNascimento ?? '-');

        final idosoTelefone = !isUserCaregiver
            ? (_isEditing ? _telefoneController.text : (currentUser.phone ?? 'Não informado'))
            : (partner?.phone ?? '-');

        // Doenças do Idoso: o cuidador gerencia, o idoso apenas visualiza
        final idosoDoencas = _isEditing
            ? _doencasController.text
            : (currentUser.isCaregiver
                ? (partner?.doencasCronicas ?? currentUser.doencasCronicas ?? 'Nenhuma informada')
                : (currentUser.doencasCronicas ?? partner?.doencasCronicas ?? 'Preenchido pelo cuidador'));

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
                        onPressed: _isSaving ? null : _onEditPressed,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _isEditing ? 'SALVAR' : 'EDITAR',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                              ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.black, size: 36),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ConfiguracoesView()),
                              );
                            },
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
                            title: 'Cuidador:\n$cuidadorNome',
                            cidade: cuidadorCidade,
                            dataNascimento: cuidadorDataNasc,
                            telefone: cuidadorTelefone,
                            isEditing: _isEditing && isUserCaregiver,
                            cidadeController: isUserCaregiver ? _cidadeController : null,
                            dataNascController: isUserCaregiver ? _dataNascimentoController : null,
                            telController: isUserCaregiver ? _telefoneController : null,
                          ),
                        ),
                      ),

                      // Linha Divisória Tracejada
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return CustomPaint(
                            size: Size(1, constraints.maxHeight),
                            painter: DashedLinePainter(),
                          );
                        },
                      ),

                      // Coluna Idoso
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(left: 8, right: 12, bottom: 24),
                          child: _buildProfileColumn(
                            isCuidadorSection: false,
                            title: 'Idoso:\n$idosoNome',
                            cidade: idosoCidade,
                            dataNascimento: idosoDataNasc,
                            telefone: idosoTelefone,
                            isEditing: _isEditing,
                            doencasCronicas: idosoDoencas,
                            cidadeController: !isUserCaregiver ? _cidadeController : null,
                            dataNascController: !isUserCaregiver ? _dataNascimentoController : null,
                            telController: !isUserCaregiver ? _telefoneController : null,
                            // O idoso NÃO edita saúde dele: apenas o CUIDADOR pode editar as doenças do idoso!
                            doencasController: isUserCaregiver ? _doencasController : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, size: 20, color: Colors.black87),
                      label: const Text(
                        'Sair da Conta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.black38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleDeleteAccount,
                      icon: const Icon(Icons.delete_forever, size: 20, color: Colors.red),
                      label: const Text(
                        'Excluir Conta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
  }

  Widget _buildProfileColumn({
    required bool isCuidadorSection,
    required String title,
    required String cidade,
    required String dataNascimento,
    required String telefone,
    required bool isEditing,
    String? doencasCronicas,
    TextEditingController? cidadeController,
    TextEditingController? dataNascController,
    TextEditingController? telController,
    TextEditingController? doencasController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
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

        _buildInfoItem(Icons.location_on_outlined, 'Localidade', 'Cidade: ', cidade, isEditing, cidadeController),
        _buildInfoItem(Icons.person_outline, 'Data de\nnascimento:', '', dataNascimento, isEditing, dataNascController),
        _buildInfoItem(Icons.phone_outlined, 'Telefone', 'Número: ', telefone, isEditing, telController),

        if (doencasCronicas != null)
          _buildInfoItem(
            Icons.medical_services_outlined,
            'Doenças\nCrônicas',
            '',
            doencasCronicas,
            isEditing,
            doencasController,
            doencasController == null ? '(Informado pelo cuidador)' : '(Editável pelo cuidador)',
          ),

        if (!isCuidadorSection) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.assignment_rounded, size: 18),
              label: const Text(
                'Prontuário & Exames com Foto',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SaudeIdosoView()),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String title,
    String prefix,
    String value,
    bool isEditing,
    [TextEditingController? controller, String? helperText]
  ) {
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

          if (isEditing && controller != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  TextFormField(
                    controller: controller,
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
                  if (helperText != null) ...[
                    const SizedBox(height: 4),
                    Text(helperText, style: const TextStyle(fontSize: 11, color: Color(0xFF6A1B9A), fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            )
          else
            Column(
              children: [
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
                if (helperText != null && isEditing) ...[
                  const SizedBox(height: 4),
                  Text(helperText, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ],
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
