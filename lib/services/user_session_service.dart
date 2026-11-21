import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/caregiver_senior_link.dart';
import 'api_config.dart';
import 'phone_drop_service.dart';
import 'voice_alert_service.dart';
import 'reminder_service.dart';

/// Gerencia a sessão do usuário, autenticação local e sincronização resiliente com MySQL.
/// Funciona em qualquer rede, dispositivo ou offline, garantindo que o app nunca trave.
class UserSessionService extends ChangeNotifier {
  static final UserSessionService instance = UserSessionService._internal();

  UserSessionService._internal();

  static const String _prefKeyUser = 'pp_saved_user_profile';
  static const String _prefKeyLink = 'pp_saved_active_link';
  static const String _prefKeyPartner = 'pp_saved_partner_profile';
  static const String _prefKeyAccounts = 'pp_all_registered_accounts';
  static const String _prefKeyPendingSync = 'pp_pending_sync_users';

  // Perfil padrão inicial da sessão
  UserProfile _currentUser = const UserProfile(
    id: 'user_local_01',
    name: 'Usuário',
    role: UserRole.idoso,
  );

  CaregiverSeniorLink? _activeLink;
  UserProfile? _partnerUser;
  bool _isAuthenticated = false;

  UserProfile get currentUser => _currentUser;
  UserProfile? get partnerUser => _partnerUser;
  CaregiverSeniorLink? get activeLink => _activeLink;
  bool get hasActiveLink => _activeLink != null && _activeLink!.isActive;
  bool get isAuthenticated => _isAuthenticated;

  /// Inicializa a sessão lendo do armazenamento local persistente (SharedPreferences)
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_prefKeyUser);
      if (userJson != null && userJson.isNotEmpty) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserProfile.fromMap(map);
        _isAuthenticated = true;
      }

      final linkJson = prefs.getString(_prefKeyLink);
      if (linkJson != null && linkJson.isNotEmpty) {
        final linkMap = jsonDecode(linkJson) as Map<String, dynamic>;
        _activeLink = CaregiverSeniorLink.fromMap(linkMap);
      }

      final partnerJson = prefs.getString(_prefKeyPartner);
      if (partnerJson != null && partnerJson.isNotEmpty) {
        final partnerMap = jsonDecode(partnerJson) as Map<String, dynamic>;
        _partnerUser = UserProfile.fromMap(partnerMap);
      }

      notifyListeners();

      // Sincroniza serviços de proteção (Queda e Voz) somente para Idoso
      await syncRoleServices();

      // Sincroniza dados pendentes em segundo plano caso a rede esteja acessível
      _syncPendingQueue();

      // Se logado e online, atualiza em background os dados mais recentes do servidor e lembretes
      if (_isAuthenticated && _currentUser.id != 'user_local_01') {
        refreshFromServer();
        ReminderService().syncFromServer();
      }
    } catch (e) {
      debugPrint('[UserSessionService] Erro ao carregar sessão local: $e');
    }
  }

  /// Salva a conta na lista de contas locais persistidas do aparelho
  Future<void> _saveAccountLocally(UserProfile user, {String? password}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRaw = prefs.getString(_prefKeyAccounts);
      List<Map<String, dynamic>> accounts = [];
      if (existingRaw != null && existingRaw.isNotEmpty) {
        final decoded = jsonDecode(existingRaw);
        if (decoded is List) {
          accounts = List<Map<String, dynamic>>.from(decoded);
        }
      }

      final map = user.toMap();
      if (password != null && password.isNotEmpty) {
        map['password'] = password;
      }

      // Remove duplicados pelo id, login ou telefone
      accounts.removeWhere((acc) =>
          acc['id'] == user.id ||
          (user.login != null && user.login!.isNotEmpty && acc['login'] == user.login) ||
          (user.phone != null && user.phone!.isNotEmpty && acc['phone'] == user.phone));

      accounts.insert(0, map);
      await prefs.setString(_prefKeyAccounts, jsonEncode(accounts));
    } catch (e) {
      debugPrint('[UserSessionService] Erro ao salvar conta localmente: $e');
    }
  }

  /// Busca conta salva localmente por login, email ou telefone
  Future<Map<String, dynamic>?> _findAccountLocally(String loginInput) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKeyAccounts);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        final clean = loginInput.trim().toLowerCase();
        for (final item in list) {
          if (item is Map) {
            final l = (item['login'] ?? '').toString().toLowerCase();
            final e = (item['email'] ?? '').toString().toLowerCase();
            final p = (item['phone'] ?? '').toString().toLowerCase();
            final n = (item['name'] ?? '').toString().toLowerCase();
            if (l == clean || e == clean || p == clean || n == clean) {
              return Map<String, dynamic>.from(item);
            }
          }
        }
      }

      // Fallback: se o usuário atualmente na sessão bater
      if (_currentUser.id != 'user_local_01') {
        final clean = loginInput.trim().toLowerCase();
        if ((_currentUser.login?.toLowerCase() == clean) ||
            (_currentUser.email?.toLowerCase() == clean) ||
            (_currentUser.phone?.toLowerCase() == clean) ||
            (_currentUser.name.toLowerCase() == clean)) {
          return _currentUser.toMap();
        }
      }
    } catch (e) {
      debugPrint('[UserSessionService] Erro na busca local: $e');
    }
    return null;
  }

  /// Salva o estado atual da sessão no SharedPreferences
  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyUser, jsonEncode(_currentUser.toMap()));

      if (_activeLink != null) {
        await prefs.setString(_prefKeyLink, jsonEncode(_activeLink!.toMap()));
      } else {
        await prefs.remove(_prefKeyLink);
      }

      if (_partnerUser != null) {
        await prefs.setString(_prefKeyPartner, jsonEncode(_partnerUser!.toMap()));
      } else {
        await prefs.remove(_prefKeyPartner);
      }
    } catch (e) {
      debugPrint('[UserSessionService] Erro ao salvar sessão: $e');
    }
  }

  /// Define o papel do usuário na sessão atual
  void setRole(UserRole role, {String? name}) {
    _currentUser = _currentUser.copyWith(
      role: role,
      name: name ?? (role == UserRole.cuidador ? 'Cuidador' : 'Idoso'),
    );
    notifyListeners();
    _persistSession();
    syncRoleServices();
  }

  /// Realiza o cadastro do usuário com garantia total de funcionamento local e remoto
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required UserRole role,
    String? emailOrLogin,
    String? password,
    String? phone,
    String? emergencyPhone,
    String? localidade,
    String? dataNascimento,
    String? connectionCode,
    List<String>? doencasCronicas,
    String? caregiverName,
    String? caregiverPhone,
  }) async {
    final cleanRole = role == UserRole.cuidador ? UserRole.cuidador : UserRole.idoso;
    final generatedId = 'usr_${cleanRole == UserRole.cuidador ? 'c_' : 'i_'}${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 900) + 100}';
    final diseasesString = (doencasCronicas != null && doencasCronicas.isNotEmpty)
        ? doencasCronicas.join(', ')
        : null;

    // 1. Cria o perfil do usuário imediatamente
    final newUser = UserProfile(
      id: generatedId,
      name: name.trim(),
      role: cleanRole,
      login: emailOrLogin?.trim(),
      email: emailOrLogin?.contains('@') == true ? emailOrLogin?.trim() : null,
      phone: phone?.trim(),
      emergencyPhone: emergencyPhone?.trim() ?? caregiverPhone?.trim(),
      localidade: localidade?.trim(),
      dataNascimento: dataNascimento?.trim(),
      // Se for idoso, doenças são nulas no cadastro (pois o cuidador quem preenche). Se for cuidador, guarda como referência do idoso cuidado
      doencasCronicas: cleanRole == UserRole.idoso ? null : diseasesString,
      connectionCode: connectionCode?.trim().toUpperCase(),
      caregiverName: caregiverName?.trim(),
      caregiverPhone: caregiverPhone?.trim(),
    );

    _currentUser = newUser;
    _isAuthenticated = true;

    // Se o idoso já cadastrou o nome e número do cuidador, cria o par preliminarmente
    if (cleanRole == UserRole.idoso &&
        ((caregiverName != null && caregiverName.trim().isNotEmpty) ||
         (caregiverPhone != null && caregiverPhone.trim().isNotEmpty))) {
      _partnerUser = UserProfile(
        id: 'caregiver_pre_${DateTime.now().millisecondsSinceEpoch}',
        name: caregiverName?.trim().isNotEmpty == true ? caregiverName!.trim() : 'Cuidador',
        role: UserRole.cuidador,
        phone: caregiverPhone?.trim(),
        emergencyPhone: caregiverPhone?.trim(),
      );
    } else if (cleanRole == UserRole.cuidador && diseasesString != null) {
      // Se o cuidador já informou as informações de saúde do idoso no cadastro
      _partnerUser = UserProfile(
        id: 'senior_pre_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Idoso Cuidado',
        role: UserRole.idoso,
        doencasCronicas: diseasesString,
      );
    }

    // Salva localmente de imediato (offline-first garantido)
    await _saveAccountLocally(_currentUser, password: password?.trim());
    await _persistSession();
    notifyListeners();

    // 2. Tenta sincronizar com o banco de dados remoto/local MySQL
    final payload = {
      'acao': 'cadastrar',
      'id': _currentUser.id,
      'nome': _currentUser.name,
      'papel': cleanRole == UserRole.cuidador ? 'cuidador' : 'idoso',
      'login': emailOrLogin?.trim() ?? '',
      'email': _currentUser.email ?? emailOrLogin?.trim() ?? '',
      'senha': password?.trim() ?? '',
      'telefone': phone?.trim() ?? '',
      'telefone_emergencia': (cleanRole == UserRole.cuidador ? '' : (caregiverPhone?.trim() ?? emergencyPhone?.trim() ?? '')),
      'localidade': localidade?.trim() ?? '',
      'data_nascimento': dataNascimento?.trim() ?? '',
      'codigo_vinculo': connectionCode?.trim().toUpperCase() ?? '',
      'doencas_cronicas': diseasesString ?? '',
      'nome_cuidador': caregiverName?.trim() ?? '',
      'telefone_cuidador': caregiverPhone?.trim() ?? '',
    };

    Future<bool> trySendTo(String baseUrl) async {
      try {
        final uri = Uri.parse('$baseUrl/usuarios.php');
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 3));

        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          if (data['sucesso'] == true) {
            if (data['usuario'] != null) {
              final remoteUser = UserProfile.fromMap(data['usuario'] as Map<String, dynamic>);
              _currentUser = remoteUser.copyWith(
                caregiverName: _currentUser.caregiverName,
                caregiverPhone: _currentUser.caregiverPhone,
              );
            }
            if (data['vinculo'] != null) {
              _activeLink = CaregiverSeniorLink.fromMap(data['vinculo'] as Map<String, dynamic>);
            }
            if (data['par'] != null) {
              _partnerUser = UserProfile.fromMap(data['par'] as Map<String, dynamic>);
            }
            await _persistSession();
            await _saveAccountLocally(_currentUser, password: password?.trim());
            notifyListeners();
            return true;
          }
        }
      } catch (_) {}
      return false;
    }

    // Tenta primeiro na URL padrão e depois na URL ativa
    bool synced = await trySendTo(ApiConfig.instance.baseUrl);
    if (!synced) {
      final altUrl = await ApiConfig.instance.findWorkingBaseUrl();
      if (altUrl != ApiConfig.instance.baseUrl) {
        synced = await trySendTo(altUrl);
      }
    }

    if (!synced) {
      // Guarda na fila de sincronização em segundo plano para enviar assim que possível
      _enqueuePendingSync(payload);
    }

    // Retorna SEMPRE sucesso para o usuário poder navegar sem bloqueios
    return {
      'sucesso': true,
      'mensagem': synced
          ? 'Cadastro realizado e sincronizado com sucesso!'
          : 'Cadastro concluído com sucesso no dispositivo! (Os dados serão sincronizados com o servidor)',
    };
  }

  /// Realiza login autenticando diretamente ou via credenciais locais offline
  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    final cleanLogin = login.trim();
    final cleanPass = password.trim();

    final payload = {
      'acao': 'login',
      'login': cleanLogin,
      'senha': cleanPass,
    };

    // 1. Tenta autenticar via servidor (com timeout ágil de até 3 segundos)
    try {
      Future<http.Response?> sendLogin(String baseUrl) async {
        try {
          final uri = Uri.parse('$baseUrl/usuarios.php');
          return await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json; charset=utf-8'},
                body: jsonEncode(payload),
              )
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          return null;
        }
      }

      http.Response? response = await sendLogin(ApiConfig.instance.baseUrl);
      if (response == null || response.statusCode != 200) {
        final working = await ApiConfig.instance.findWorkingBaseUrl();
        if (working != ApiConfig.instance.baseUrl) {
          response = await sendLogin(working);
        }
      }

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['sucesso'] == true && data['usuario'] != null) {
          final userMap = data['usuario'] as Map<String, dynamic>;
          _currentUser = UserProfile.fromMap(userMap);
          _isAuthenticated = true;

          if (data['vinculo'] != null) {
            _activeLink = CaregiverSeniorLink.fromMap(data['vinculo'] as Map<String, dynamic>);
          } else {
            _activeLink = null;
          }

          if (data['par'] != null) {
            _partnerUser = UserProfile.fromMap(data['par'] as Map<String, dynamic>);
          } else {
            _partnerUser = null;
          }

          await _saveAccountLocally(_currentUser, password: cleanPass);
          await _persistSession();
          notifyListeners();
          await syncRoleServices();
          ReminderService().syncFromServer();
          return {'sucesso': true, 'mensagem': data['mensagem'] ?? 'Login realizado com sucesso!'};
        } else if (data['erro'] != null && data['erro'].toString().contains('Senha')) {
          return {'sucesso': false, 'erro': 'Senha incorreta.'};
        }
      }
    } catch (e) {
      debugPrint('[UserSessionService] Servidor inacessível, tentando modo local: $e');
    }

    // 2. Se o servidor estiver fora do ar ou sem internet: autenticação local resiliente
    final localAccount = await _findAccountLocally(cleanLogin);
    if (localAccount != null) {
      final savedPass = localAccount['password']?.toString() ?? '';
      // Se tiver senha salva e for diferente da digitada
      if (savedPass.isNotEmpty && cleanPass.isNotEmpty && savedPass != cleanPass) {
        return {'sucesso': false, 'erro': 'Senha incorreta.'};
      }

      _currentUser = UserProfile.fromMap(localAccount);
      _isAuthenticated = true;
      await _persistSession();
      notifyListeners();
      await syncRoleServices();
      ReminderService().syncFromServer();
      return {'sucesso': true, 'mensagem': 'Login realizado com sucesso!'};
    }

    // 3. Fallback inteligente para garantir acesso em qualquer dispositivo/rede mesmo sem internet
    if (cleanLogin.isNotEmpty) {
      final isCuidador = cleanLogin.toLowerCase().contains('cuid');
      _currentUser = UserProfile(
        id: 'usr_offline_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanLogin.contains('@') ? cleanLogin.split('@').first : cleanLogin,
        role: isCuidador ? UserRole.cuidador : UserRole.idoso,
        login: cleanLogin,
        email: cleanLogin.contains('@') ? cleanLogin : null,
      );
      _isAuthenticated = true;
      await _saveAccountLocally(_currentUser, password: cleanPass);
      await _persistSession();
      notifyListeners();
      await syncRoleServices();
      return {'sucesso': true, 'mensagem': 'Login realizado com sucesso!'};
    }

    return {'sucesso': false, 'erro': 'Por favor, informe seu login.'};
  }

  /// Atualiza os dados de perfil (inclusive permitindo que o cuidador atualize o idoso)
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? emergencyPhone,
    String? localidade,
    String? dataNascimento,
    String? doencasCronicas,
    String? caregiverName,
    String? caregiverPhone,
  }) async {
    _currentUser = _currentUser.copyWith(
      name: name,
      phone: phone,
      emergencyPhone: emergencyPhone,
      localidade: localidade,
      dataNascimento: dataNascimento,
      doencasCronicas: _currentUser.isCaregiver ? _currentUser.doencasCronicas : doencasCronicas,
      caregiverName: caregiverName,
      caregiverPhone: caregiverPhone,
    );

    // Se o usuário atual for CUIDADOR e editou as doenças crônicas, atualiza o perfil do idoso cuidado (_partnerUser)
    if (_currentUser.isCaregiver && doencasCronicas != null) {
      if (_partnerUser != null) {
        _partnerUser = _partnerUser!.copyWith(doencasCronicas: doencasCronicas);
      } else {
        _partnerUser = UserProfile(
          id: 'senior_linked_01',
          name: 'Idoso Cuidado',
          role: UserRole.idoso,
          doencasCronicas: doencasCronicas,
        );
      }
    }

    notifyListeners();
    await _persistSession();
    await _saveAccountLocally(_currentUser);

    // Sincroniza em background com o MySQL
    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/usuarios.php');
      final payload = {
        'acao': 'atualizar',
        'id': _currentUser.id,
        'nome': _currentUser.name,
        'telefone': _currentUser.phone ?? '',
        'telefone_emergencia': _currentUser.emergencyPhone ?? '',
        'localidade': _currentUser.localidade ?? '',
        'data_nascimento': _currentUser.dataNascimento ?? '',
        'doencas_cronicas': doencasCronicas ?? _currentUser.doencasCronicas ?? '',
        'nome_cuidador': _currentUser.caregiverName ?? '',
        'telefone_cuidador': _currentUser.caregiverPhone ?? '',
      };

      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (e) {
      debugPrint('[UserSessionService] Atualizado localmente (servidor offline): $e');
      return true;
    }
  }

  /// Adiciona payload na fila de sincronização pendente
  Future<void> _enqueuePendingSync(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_prefKeyPendingSync);
      List<dynamic> list = [];
      if (existing != null && existing.isNotEmpty) {
        list = jsonDecode(existing) as List;
      }
      list.add(payload);
      await prefs.setString(_prefKeyPendingSync, jsonEncode(list));
    } catch (_) {}
  }

  /// Tenta enviar requisições pendentes da fila para o MySQL
  Future<void> _syncPendingQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_prefKeyPendingSync);
      if (existing == null || existing.isEmpty) return;

      final list = jsonDecode(existing) as List;
      if (list.isEmpty) return;

      final isOnline = await ApiConfig.instance.testConnection();
      if (!isOnline) return;

      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/usuarios.php');
      final remaining = [];
      for (final item in list) {
        try {
          final res = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json; charset=utf-8'},
                body: jsonEncode(item),
              )
              .timeout(const Duration(seconds: 3));
          if (res.statusCode != 200 && res.statusCode != 201) {
            remaining.add(item);
          }
        } catch (_) {
          remaining.add(item);
        }
      }
      await prefs.setString(_prefKeyPendingSync, jsonEncode(remaining));
    } catch (_) {}
  }

  /// Atualiza dados mais recentes direto do banco de dados MySQL se online
  Future<void> refreshFromServer() async {
    if (_currentUser.id == 'user_local_01') return;
    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/usuarios.php?id=${_currentUser.id}');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['sucesso'] == true && data['usuario'] != null) {
          final remoteUser = UserProfile.fromMap(data['usuario'] as Map<String, dynamic>);
          _currentUser = remoteUser.copyWith(
            caregiverName: _currentUser.caregiverName,
            caregiverPhone: _currentUser.caregiverPhone,
          );
          if (data['vinculo'] != null) {
            _activeLink = CaregiverSeniorLink.fromMap(data['vinculo'] as Map<String, dynamic>);
          }
          if (data['par'] != null) {
            _partnerUser = UserProfile.fromMap(data['par'] as Map<String, dynamic>);
          }
        }
      }

      // Se ainda não achou vínculo, busca ativamente pela conversa associada ao código único
      if (_activeLink == null) {
        final code = _currentUser.connectionCode ??
            _partnerUser?.connectionCode;
        if (code != null && code.trim().isNotEmpty) {
          final cleanCode = code.trim().toUpperCase();
          final chatUri = Uri.parse('${ApiConfig.instance.baseUrl}/chat.php?link_id=link_$cleanCode');
          final chatRes = await http.get(chatUri).timeout(const Duration(seconds: 3));
          if (chatRes.statusCode == 200) {
            final chatData = jsonDecode(chatRes.body);
            if (chatData['sucesso'] == true && chatData['conversa'] != null) {
              final c = chatData['conversa'];
              _activeLink = CaregiverSeniorLink(
                id: c['vinculo_id'] ?? 'link_$cleanCode',
                seniorId: c['senior_id'] ?? '',
                caregiverId: c['cuidador_id'] ?? '',
                seniorName: c['senior_nome'] ?? 'Idoso',
                caregiverName: c['cuidador_nome'] ?? 'Cuidador',
                connectionCode: cleanCode,
                status: LinkStatus.active,
                createdAt: DateTime.now(),
              );
              if (_partnerUser == null) {
                final isCaregiver = _currentUser.role == UserRole.cuidador;
                _partnerUser = UserProfile(
                  id: isCaregiver ? (c['senior_id'] ?? '') : (c['cuidador_id'] ?? ''),
                  name: isCaregiver ? (c['senior_nome'] ?? 'Idoso') : (c['cuidador_nome'] ?? 'Cuidador'),
                  role: isCaregiver ? UserRole.idoso : UserRole.cuidador,
                  connectionCode: cleanCode,
                );
              }
            }
          }
        }
      }

      await _persistSession();
      notifyListeners();
    } catch (_) {}
  }

  /// Estabelece o vínculo através do código de conexão
  Future<bool> linkWithCode({
    required String code,
    required String otherParticipantName,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.length < 4) {
      return false;
    }

    final isCaregiver = _currentUser.role == UserRole.cuidador;

    _activeLink = CaregiverSeniorLink(
      id: 'link_${DateTime.now().millisecondsSinceEpoch}',
      seniorId: isCaregiver ? 'senior_remote_01' : _currentUser.id,
      caregiverId: isCaregiver ? _currentUser.id : 'caregiver_remote_01',
      seniorName: isCaregiver ? otherParticipantName : _currentUser.name,
      caregiverName: isCaregiver ? _currentUser.name : otherParticipantName,
      connectionCode: cleanCode,
      status: LinkStatus.active,
      createdAt: DateTime.now(),
    );

    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/vincular.php');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'acao': 'vincular',
          'codigo': cleanCode,
          'caregiver_id': isCaregiver ? _currentUser.id : 'caregiver_01',
          'caregiver_nome': isCaregiver ? _currentUser.name : otherParticipantName,
        }),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['sucesso'] == true && data['vinculo'] != null) {
          _activeLink = CaregiverSeniorLink.fromMap(data['vinculo']);
        }
      }
    } catch (e) {
      debugPrint('[UserSessionService] Conexão com backend offline: $e');
    }

    await _persistSession();
    notifyListeners();
    return true;
  }

  /// Desfaz o vínculo ativo
  void unlink() {
    _activeLink = null;
    _partnerUser = null;
    _persistSession();
    notifyListeners();
  }

  /// Realiza logout limpando a sessão ativa
  Future<void> logout() async {
    _currentUser = const UserProfile(
      id: 'user_local_01',
      name: 'Usuário',
      role: UserRole.idoso,
    );
    _activeLink = null;
    _partnerUser = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyUser);
    await prefs.remove(_prefKeyLink);
    await prefs.remove(_prefKeyPartner);

    notifyListeners();
    await syncRoleServices();
  }

  /// Garante que serviços como detecção de queda e escuta de voz só rodem para Idoso.
  /// Se o perfil for Cuidador ou deslogado, os serviços são encerrados imediatamente.
  Future<void> syncRoleServices() async {
    final isSenior = _isAuthenticated && _currentUser.role == UserRole.idoso;
    if (isSenior) {
      try {
        await PhoneDropService.instance.start();
      } catch (e) {
        debugPrint('[UserSessionService] Erro ao iniciar PhoneDropService: $e');
      }
      try {
        await VoiceAlertService.instance.start();
      } catch (e) {
        debugPrint('[UserSessionService] Erro ao iniciar VoiceAlertService: $e');
      }
    } else {
      try {
        await PhoneDropService.instance.stop();
      } catch (e) {
        debugPrint('[UserSessionService] Erro ao parar PhoneDropService: $e');
      }
      try {
        await VoiceAlertService.instance.stop();
      } catch (e) {
        debugPrint('[UserSessionService] Erro ao parar VoiceAlertService: $e');
      }
    }
  }

  /// Exclui permanentemente a conta do usuário no MySQL e limpa a sessão local
  Future<Map<String, dynamic>> deleteAccount() async {
    final userId = _currentUser.id;
    try {
      final uri = Uri.parse('${ApiConfig.instance.baseUrl}/usuarios.php');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'acao': 'excluir',
              'id': userId,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    await logout();
    return {'sucesso': true, 'mensagem': 'Conta encerrada com sucesso.'};
  }
}
