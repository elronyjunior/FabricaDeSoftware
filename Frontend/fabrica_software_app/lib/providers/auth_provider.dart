import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final _authService = AuthService.instance;
  
  bool _isLoading = false;
  String? _error;
  bool? _isAuthenticated;
  
  // --- CORREÇÃO: Adicionado o campo ID que faltava ---
  int? _userId; 
  String? _userNivel;
  String? _email;
  String? _nome;

  AuthProvider() {
    _init();
  }

  // Getters
  bool? get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // --- CORREÇÃO: Getter público para o ID ---
  int? get userId => _userId; 
  
  String? get userNivel => _userNivel;
  String? get email => _email;
  String? get nome => _nome;

  Future<void> _init() async {
    _isAuthenticated = await _authService.isAuthenticated;
    
    if (_isAuthenticated ?? false) {
      _userId = await _authService.userId; // Carrega ID ao iniciar
      _userNivel = await _authService.userNivel;
      _email = await _authService.userEmail;
      _nome = await _authService.userName;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String senha) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.login(email, senha);
      _isLoading = false;
      
      if (!success) {
        _error = 'Credenciais inválidas';
      } else {
        _isAuthenticated = true;
        // --- CORREÇÃO: Atualiza o ID imediatamente após login ---
        _userId = await _authService.userId; 
        _userNivel = await _authService.userNivel;
        _email = email; 
        _nome = await _authService.userName;
      }
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.loginWithGoogle();
      _isLoading = false;
      
      if (!success) {
        _error = 'Falha no login com Google.';
      } else {
        _isAuthenticated = true;
        // --- CORREÇÃO: Atualiza o ID aqui também ---
        _userId = await _authService.userId; 
        _userNivel = await _authService.userNivel;
        _email = await _authService.userEmail;
        _nome = await _authService.userName;
      }
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _userId = null; // Limpa o ID
    _userNivel = null;
    _email = null; 
    _nome = null;
    notifyListeners();
  }
}