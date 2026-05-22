import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fabrica_software_app/config/api_config.dart';
import 'package:fabrica_software_app/services/auth_service.dart';

class RelatoriosProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dados;

  // Getters para a tela acessar
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dados => _dados;

  // Método principal para carregar o dashboard
  Future<void> carregarDados() async {
    _isLoading = true;
    _error = null;
    // Avisa a tela que começou a carregar (para mostrar o spinner)
    notifyListeners(); 

    try {
      final token = await AuthService.instance.token;
      final url = Uri.parse('${ApiConfig.baseUrl}/relatorios/dashboard');
      
      final response = await http.get(
        url, 
        headers: ApiConfig.getAuthHeaders(token)
      );

      if (response.statusCode == 200) {
        _dados = jsonDecode(response.body);
        _error = null;
      } else {
        _error = 'Erro do servidor: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Erro de conexão: $e';
    } finally {
      _isLoading = false;
      notifyListeners(); // Avisa a tela que terminou (para mostrar os dados ou erro)
    }
  }
}