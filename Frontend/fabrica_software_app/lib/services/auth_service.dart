import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'base_api_service.dart';

// --- IMPORTS ADICIONADOS ---
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNivelKey = 'user_nivel';
  static const String _userNameKey = 'user_name';
  // --- ALTERAÇÃO ---
  static const String _userEmailKey = 'user_email'; // Chave para o email

  String? _cachedToken;
  int? _cachedUserId;
  String? _cachedUserNivel;
  String? _cachedUserName;
  // --- ALTERAÇÃO ---
  String? _cachedUserEmail; // Cache para o email
  DateTime? _lastTokenRefresh;

  AuthService._();
  static final AuthService instance = AuthService._();

  Future<bool> login(String email, String senha) async {
    try {
      final response = await http.post(
        // Corrigido para remover o /api duplicado
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'senha': senha,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        _cachedToken = json['token'];
        _cachedUserId = json['usuario']['id'];
        _cachedUserNivel = json['usuario']['nivel'];
        _cachedUserName = json['usuario']['nome'];
        _cachedUserEmail = json['usuario']['email'];
        _lastTokenRefresh = DateTime.now();

        await prefs.setString(_tokenKey, _cachedToken!);
        await prefs.setInt(_userIdKey, _cachedUserId!);
        await prefs.setString(_userNivelKey, _cachedUserNivel!);
        if (_cachedUserName != null) {
          await prefs.setString(_userNameKey, _cachedUserName!);
        }
        if (_cachedUserEmail != null) {
          await prefs.setString(_userEmailKey, _cachedUserEmail!);
        }
        return true;
      }

      String message = 'Email ou senha incorretos.';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          message = body['message'].toString();
        }
      } catch (_) {}
      throw ApiException(message);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro ao fazer login: ${e.toString()}');
    }
  }

  // --- MÉTODO NOVO ---
  Future<bool> loginWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      if (userCredential.user == null) {
        debugPrint("Login com Google cancelado.");
        return false;
      }

      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw ApiException("Não foi possível obter o ID Token do Google.");
      }

      final response = await http.post(
        // Corrigido para remover o /api duplicado
        Uri.parse('${ApiConfig.baseUrl}/auth/google-login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'googleIdToken': idToken,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        _cachedToken = json['token'];
        _cachedUserId = json['usuario']['id'];
        _cachedUserNivel = json['usuario']['nivel'];
        _cachedUserName = json['usuario']['nome'];
        // --- ALTERAÇÃO ---
        _cachedUserEmail = json['usuario']['email']; // Salva email no cache
        _lastTokenRefresh = DateTime.now();

        await prefs.setString(_tokenKey, _cachedToken!);
        await prefs.setInt(_userIdKey, _cachedUserId!);
        await prefs.setString(_userNivelKey, _cachedUserNivel!);
        if (_cachedUserName != null) {
          await prefs.setString(_userNameKey, _cachedUserName!);
        }
        // --- ALTERAÇÃO ---
        if (_cachedUserEmail != null) {
          await prefs.setString(_userEmailKey, _cachedUserEmail!);
        }
        return true;
      }
      String message = 'Falha no login com Google.';
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          message = (body['message'] ?? body['error'] ?? message).toString();
        }
      } catch (_) {}
      throw ApiException(message);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro no login com Google: ${e.toString()}');
    }
  }
  // --- FIM DO MÉTODO NOVO ---

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    _cachedToken = null;
    _cachedUserId = null;
    _cachedUserNivel = null;
    _cachedUserName = null;
    // --- ALTERAÇÃO ---
    _cachedUserEmail = null; // Limpa cache do email
    _lastTokenRefresh = null;

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNivelKey);
    await prefs.remove(_userNameKey);
    // --- ALTERAÇÃO ---
    await prefs.remove(_userEmailKey); // Remove email do SharedPreferences

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Erro ao fazer logout do Google: $e");
    }
  }

  Future<bool> get isAuthenticated async {
    final token = await this.token;
    return token != null;
  }

  Future<String?> get token async {
    if (_cachedToken != null && _lastTokenRefresh != null) {
      final difference = DateTime.now().difference(_lastTokenRefresh!);
      if (difference.inMinutes < 30) {
        return _cachedToken;
      }
      try {
        await refreshToken();
        return _cachedToken;
      } catch (e) {
        return null;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<int?> get userId async {
    if (_cachedUserId != null) return _cachedUserId;

    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getInt(_userIdKey);
    return _cachedUserId;
  }

  Future<String?> get userNivel async {
    if (_cachedUserNivel != null) return _cachedUserNivel;

    final prefs = await SharedPreferences.getInstance();
    _cachedUserNivel = prefs.getString(_userNivelKey);
    return _cachedUserNivel;
  }

  Future<String?> get userName async {
    if (_cachedUserName != null) return _cachedUserName;

    final prefs = await SharedPreferences.getInstance();
    _cachedUserName = prefs.getString(_userNameKey);
    return _cachedUserName;
  }

  // --- ALTERAÇÃO: NOVO GETTER PARA O EMAIL ---
  Future<String?> get userEmail async {
    if (_cachedUserEmail != null) return _cachedUserEmail;

    final prefs = await SharedPreferences.getInstance();
    _cachedUserEmail = prefs.getString(_userEmailKey);
    return _cachedUserEmail;
  }
  // --- FIM DA ALTERAÇÃO ---

  Future<bool> refreshToken() async {
    try {
      final oldToken = _cachedToken;
      if (oldToken == null) return false;

      final response = await http.post(
        // Corrigido para remover o /api duplicado
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $oldToken',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        _cachedToken = json['token'];
        _lastTokenRefresh = DateTime.now();

        await prefs.setString(_tokenKey, _cachedToken!);
        return true;
      }
      return false;
    } catch (e) {
      throw ApiException('Erro ao renovar token: ${e.toString()}');
    }
  }
}