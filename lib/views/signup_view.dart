import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/custom_logo.dart';
import '../widgets/custom_text_field.dart';
import 'permissions_view.dart';
import '../services/user_session_service.dart';
import '../models/user_profile.dart';

class SignupView extends StatefulWidget {
  final String profile;
  const SignupView({super.key, required this.profile});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  // Define se o cadastro atual é para um Cuidador (true) ou Idoso (false)
  bool _isCaregiver = false;
  bool _isLoading = false;

  // Código gerado para o idoso
  String _generatedCode = '';

  late final TextEditingController _emailController;
  late final TextEditingController _caregiverNameController;
  late final TextEditingController _caregiverPhoneController;
  late final TextEditingController _userNameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;
  late final TextEditingController _localityController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _seniorCodeInputController;

  final List<String> _diseasesList = [
    'Hipertensão (pressão alta)',
    'Diabetes tipo 2',
    'Doenças cardiovasculares (como infarto e insuficiência cardíaca)',
    'AVC (derrame)',
    'Alzheimer',
    'Parkinson',
    'Osteoporose',
    'Osteoartrose',
    'Depressão',
    'Câncer',
    'Colesterol alto (dislipidemia)',
    'Doenças respiratórias (como DPOC e pneumonia)',
    'Insuficiência renal',
    'Infecção urinária',
    'Catarata e problemas de visão',
  ];

  final Map<String, bool> _selectedDiseases = {};

  @override
  void initState() {
    super.initState();
    _isCaregiver = widget.profile.toLowerCase() == 'cuidador';
    _emailController = TextEditingController();
    _caregiverNameController = TextEditingController();
    _caregiverPhoneController = TextEditingController();
    _userNameController = TextEditingController();
    _passwordController = TextEditingController();
    _phoneController = TextEditingController();
    _localityController = TextEditingController();
    _birthDateController = TextEditingController();
    _seniorCodeInputController = TextEditingController();

    for (var disease in _diseasesList) {
      _selectedDiseases[disease] = false;
    }

    if (!_isCaregiver) {
      _generateCode();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _caregiverNameController.dispose();
    _caregiverPhoneController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _localityController.dispose();
    _birthDateController.dispose();
    _seniorCodeInputController.dispose();
    super.dispose();
  }

  void _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    final code = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    setState(() {
      _generatedCode = code;
    });
  }

  Future<void> _handleRegister() async {
    final emailOrLogin = _emailController.text.trim();
    if (emailOrLogin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe seu email ou telefone de login.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, defina uma senha para a conta.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validações específicas por perfil
    if (_isCaregiver) {
      final caregiverName = _caregiverNameController.text.trim();
      if (caregiverName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, informe seu nome de cuidador.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    } else {
      final seniorName = _userNameController.text.trim();
      if (seniorName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, informe o nome do usuário idoso.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    // Lista de doenças: o idoso NÃO coloca. O cuidador que coloca as do idoso cuidado!
    final List<String> selectedDiseasesList = _isCaregiver
        ? _selectedDiseases.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList()
        : [];

    final result = await UserSessionService.instance.registerUser(
      name: _isCaregiver
          ? _caregiverNameController.text.trim()
          : _userNameController.text.trim(),
      role: _isCaregiver ? UserRole.cuidador : UserRole.idoso,
      emailOrLogin: emailOrLogin,
      password: password,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : (emailOrLogin.contains('@') ? '' : emailOrLogin),
      emergencyPhone: _isCaregiver
          ? '' // Cuidador não tem pergunta de contato de emergência!
          : _caregiverPhoneController.text.trim(), // Idoso usa telefone do cuidador
      localidade: _localityController.text.trim(),
      dataNascimento: _birthDateController.text.trim(),
      connectionCode: _isCaregiver
          ? _seniorCodeInputController.text.trim()
          : _generatedCode,
      doencasCronicas: _isCaregiver ? selectedDiseasesList : null,
      caregiverName: _isCaregiver
          ? null
          : _caregiverNameController.text.trim(),
      caregiverPhone: _isCaregiver
          ? null
          : _caregiverPhoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['mensagem'] ?? 'Cadastro concluído com sucesso!'),
          backgroundColor: const Color(0xFF9C72AD),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PermissionsView(
            profile: _isCaregiver ? 'Cuidador' : 'Idoso',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['erro'] ?? 'Erro ao cadastrar usuário.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF9C72AD)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Center(child: CustomLogo(size: 180)),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF9C72AD),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: const Text(
                  'Cadastrar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Alternador de Perfil: Idoso ou Cuidador
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isCaregiver = false;
                        if (_generatedCode.isEmpty) {
                          _generateCode();
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isCaregiver ? const Color(0xFF9C72AD) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF9C72AD)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Idoso (Usuário)',
                          style: TextStyle(
                            color: !_isCaregiver ? Colors.white : const Color(0xFF9C72AD),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isCaregiver = true;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isCaregiver ? const Color(0xFF9C72AD) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF9C72AD)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cuidador',
                          style: TextStyle(
                            color: _isCaregiver ? Colors.white : const Color(0xFF9C72AD),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Campo de login
              CustomTextField(
                hintText: 'Email ou telefone de login:',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              // ==========================================
              // SE FOR CUIDADOR:
              // ==========================================
              if (_isCaregiver) ...[
                CustomTextField(
                  hintText: 'Nome do cuidador:',
                  controller: _caregiverNameController,
                ),
                // "No cadastro do cuidador, tire a pergunta de contato de emergencia. e sim, 'telefone'."
                CustomTextField(
                  hintText: 'Telefone:',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                CustomTextField(
                  hintText: 'Senha da conta:',
                  obscureText: true,
                  controller: _passwordController,
                ),
                CustomTextField(
                  hintText: 'Nome do idoso cuidado:',
                  controller: _userNameController,
                ),
                CustomTextField(
                  hintText: 'Localidade (Cidade/Estado):',
                  controller: _localityController,
                ),
                CustomTextField(
                  hintText: 'Data de nascimento (dd/mm/aaaa):',
                  controller: _birthDateController,
                  keyboardType: TextInputType.datetime,
                ),
                CustomTextField(
                  hintText: 'Adicione o código do idoso:',
                  controller: _seniorCodeInputController,
                ),
              ],

              // ==========================================
              // SE FOR IDOSO:
              // ==========================================
              if (!_isCaregiver) ...[
                CustomTextField(
                  hintText: 'Nome do usuário:',
                  controller: _userNameController,
                ),
                CustomTextField(
                  hintText: 'Senha da conta:',
                  obscureText: true,
                  controller: _passwordController,
                ),
                // "no cadastro do idoso deve ter tambem alem de contato do cuidador, o numero dele."
                CustomTextField(
                  hintText: 'Contato do cuidador (Nome):',
                  controller: _caregiverNameController,
                ),
                CustomTextField(
                  hintText: 'Número do cuidador (Telefone):',
                  controller: _caregiverPhoneController,
                  keyboardType: TextInputType.phone,
                ),
                CustomTextField(
                  hintText: 'Telefone do idoso (opcional):',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                CustomTextField(
                  hintText: 'Localidade (Cidade/Estado):',
                  controller: _localityController,
                ),
                CustomTextField(
                  hintText: 'Data de nascimento (dd/mm/aaaa):',
                  controller: _birthDateController,
                  keyboardType: TextInputType.datetime,
                ),
              ],

              const SizedBox(height: 10),

              // Caixa de Código de Conexão do Idoso
              if (!_isCaregiver)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: const Color(0xFF9C72AD)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Código de conexão do idoso:',
                        style: TextStyle(
                          color: Color(0xFF9C72AD),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_generatedCode.isNotEmpty) ...[
                        Text(
                          _generatedCode,
                          style: const TextStyle(
                            color: Color(0xFF9C72AD),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Compartilhe este código com seu cuidador para que ele possa se vincular à sua conta.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ] else ...[
                        ElevatedButton(
                          onPressed: _generateCode,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                          child: const Text('Gerar Código', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  ),
                ),

              // ==========================================
              // INFORMAÇÕES DE SAÚDE:
              // "o idoso nao coloca informação de saude dele, o cuidador vai colocar as informações de saude do idoso"
              // ==========================================
              if (_isCaregiver) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      title: const Text(
                        'Informações de Saúde do Idoso Cuidado',
                        style: TextStyle(
                          color: Color(0xFF9C72AD),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        'Preencha as condições de saúde do idoso sob seus cuidados',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      iconColor: const Color(0xFF9C72AD),
                      collapsedIconColor: const Color(0xFF9C72AD),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Selecione as condições pré-existentes do idoso para personalização e alertas:',
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._diseasesList.map((disease) {
                          return CheckboxListTile(
                            title: Text(
                              disease,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            value: _selectedDiseases[disease] ?? false,
                            activeColor: const Color(0xFF9C72AD),
                            checkColor: Colors.white,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? value) {
                              setState(() {
                                _selectedDiseases[disease] = value ?? false;
                              });
                            },
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Cadastrar no Sistema',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
