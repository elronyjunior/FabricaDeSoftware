import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fabrica_software_app/config/api_config.dart';
import 'package:fabrica_software_app/services/auth_service.dart';

class TreinamentosProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _treinamentos = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get treinamentos => _treinamentos;

  // 1. CARREGAR TREINAMENTOS (Filtrando por Projeto)
  Future<void> carregarTreinamentos(int projetoId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await AuthService.instance.token;
      // Busca todos (idealmente filtraria no backend, mas aqui filtramos na memória)
      final url = Uri.parse('${ApiConfig.baseUrl}/treinamentos');
      final response = await http.get(url, headers: ApiConfig.getAuthHeaders(token));

      if (response.statusCode == 200) {
        final List<dynamic> todos = jsonDecode(response.body);
        // Filtra apenas os deste projeto
        _treinamentos = todos.where((t) => t['projeto_id'].toString() == projetoId.toString()).toList();
      } else {
        _error = 'Erro ao carregar: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Erro de conexão: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. DELETAR TREINAMENTO (Novo)
  Future<bool> deletarTreinamento(int treinamentoId) async {
    // Não ativamos o isLoading geral para não piscar a tela toda, apenas removemos
    try {
      final token = await AuthService.instance.token;
      final url = Uri.parse('${ApiConfig.baseUrl}/treinamentos/$treinamentoId');
      
      final response = await http.delete(url, headers: ApiConfig.getAuthHeaders(token));

      if (response.statusCode == 200) {
        // Remove da lista localmente para atualizar a UI instantaneamente
        _treinamentos.removeWhere((t) => t['id'].toString() == treinamentoId.toString());
        notifyListeners();
        return true;
      } else {
        throw Exception("Falha ao deletar");
      }
    } catch (e) {
      _error = "Erro ao deletar: $e";
      notifyListeners();
      return false;
    }
  }
}