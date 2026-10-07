import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/custom_logo.dart';
import '../widgets/custom_text_field.dart';
import 'permissions_view.dart';

class SignupView extends StatefulWidget {
  final String profile;
  const SignupView({super.key, required this.profile});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  // Define se o cadastro atual é para um Cuidador (true) ou Idoso (false)
  bool _isCaregiver = false;
  
  // Código gerado para o idoso
  String _generatedCode = '';

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
    for (var disease in _diseasesList) {
      _selectedDiseases[disease] = false;
    }
  }

  void _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    // Gera um código de 6 caracteres aleatórios
    final code = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
    setState(() {
      _generatedCode = code;
    });
  }

  void _navigateToPermissions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PermissionsView(profile: widget.profile)),
    );
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
              
              // Seleção de Perfil
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isCaregiver = false;
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

              const CustomTextField(hintText: 'Email/telefone:'),
              // O campo "Nome do cuidador" só deve aparecer para o cuidador
              if (_isCaregiver)
                const CustomTextField(hintText: 'Nome do cuidador:'),
                
              const CustomTextField(hintText: 'Nome do usuário:'),
              const CustomTextField(
                hintText: 'Senha da conta do usuário:',
                obscureText: true,
              ),
              const CustomTextField(hintText: 'Telefone de emergência:'),
              const CustomTextField(hintText: 'Localidade:'),
              const CustomTextField(hintText: 'Data de nascimento:'),
              
              const SizedBox(height: 10),

              // Lógica da geração do código vs input do código
              if (_isCaregiver)
                const CustomTextField(hintText: 'Adicione o código do idoso:')
              else
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
                        const SizedBox(height: 8),
                        const Text(
                          'Clique para gerar um novo código de vinculação.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ]
                    ],
                  ),
                ),

              if (_isCaregiver) ...[
                const SizedBox(height: 20),
                // Seção opcional do cuidador para informações de saúde
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
                      title: const Text(
                        'Informações de Saúde (Opcional)',
                        style: TextStyle(
                          color: Color(0xFF9C72AD),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      iconColor: const Color(0xFF9C72AD),
                      collapsedIconColor: const Color(0xFF9C72AD),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Esta seção permite adicionar dados médicos do idoso para um melhor acompanhamento.',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // Botão para anexar exames
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('A funcionalidade de galeria/câmera será implementada em breve!')),
                              );
                            },
                            icon: const Icon(Icons.camera_alt, color: Color(0xFF9C72AD)),
                            label: const Text(
                              'Anexar exames (Galeria/Câmera)',
                              style: TextStyle(color: Color(0xFF9C72AD), fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF9C72AD), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Selecione as condições pré-existentes:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C72AD)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Lista de doenças usando CheckboxListTile
                        ..._diseasesList.map((disease) {
                          return CheckboxListTile(
                            title: Text(
                              disease, 
                              style: const TextStyle(fontSize: 14, color: Colors.black87)
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
                onPressed: () => _navigateToPermissions(context),
                style: ElevatedButton.styleFrom(
                  
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Continuar',
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
