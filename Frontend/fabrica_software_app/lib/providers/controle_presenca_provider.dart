import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fabrica_software_app/config/api_config.dart';
import 'package:fabrica_software_app/services/auth_service.dart';

class ControlePresencaProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  
  String? _sheetId;
  List<String> _headersDias = [];
  List<dynamic> _alunos = [];
  
  final Map<String, dynamic> _mudancasLocais = {};

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<String> get headersDias => _headersDias;
  List<dynamic> get alunos => _alunos;
  bool get temMudancasPendentes => _mudancasLocais.isNotEmpty;

  // Carregar Dados
  Future<void> carregarDados(int treinamentoId) async {
    _isLoading = true;
    _error = null;
    _mudancasLocais.clear();
    notifyListeners();

    try {
      final token = await AuthService.instance.token;
      final url = Uri.parse('${ApiConfig.baseUrl}/treinamentos/$treinamentoId/presenca');
      final response = await http.get(url, headers: ApiConfig.getAuthHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sheetId = data['sheetId'];
        _headersDias = List<String>.from(data['headers']);
        _alunos = data['alunos'];
      } else {
        _error = "Erro ao carregar (Status ${response.statusCode})";
      }
    } catch (e) {
      _error = "Erro de conexão: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CORREÇÃO AQUI: Lógica Direta ---
  void setPresenca(int rowIndex, int diaIndex, String novoStatus) {
    // 1. Atualiza visualmente na hora
    final aluno = _alunos.firstWhere((a) => a['rowIndex'] == rowIndex);
    String diaKey = _headersDias[diaIndex];
    
    // Se o status já é o mesmo, não faz nada (evita loop), a menos que seja para limpar
    if (aluno['presencas'][diaKey] == novoStatus && novoStatus != "") return;

    aluno['presencas'][diaKey] = novoStatus;

    // 2. Adiciona na fila de salvamento
    String key = "$rowIndex-$diaIndex";
    _mudancasLocais[key] = {
      "rowIndex": rowIndex,
      "diaIndex": diaIndex,
      "status": novoStatus
    };

    notifyListeners();
  }

  // Salvar
  Future<bool> salvarAlteracoes() async {
    if (_mudancasLocais.isEmpty) return true;
    _isSaving = true;
    notifyListeners();

    try {
      final token = await AuthService.instance.token;
      List<dynamic> listaMudancas = _mudancasLocais.values.toList();

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/treinamentos/presenca/lote'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode({"sheetId": _sheetId, "mudancas": listaMudancas}),
      );

      if (response.statusCode == 200) {
        _mudancasLocais.clear();
        return true;
      } else {
        throw Exception("Falha ao salvar");
      }
    } catch (e) {
      _error = "Erro ao salvar: $e";
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Adicionar Dia
  Future<void> adicionarDia(int treinamentoId, String dataFormatada) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await AuthService.instance.token;
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/treinamentos/dia'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode({"sheetId": _sheetId, "data": dataFormatada}),
      );
      if (!_disposed) await carregarDados(treinamentoId); 
    } catch (e) {
      _error = "Erro ao adicionar dia";
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adicionar Aluno
  Future<void> adicionarAluno(int treinamentoId, String nome, String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await AuthService.instance.token;
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/treinamentos/aluno'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode({"sheetId": _sheetId, "nome": nome, "email": email}),
      );
      if (!_disposed) await carregarDados(treinamentoId);
    } catch (e) {
      _error = "Erro ao adicionar aluno";
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remover Dia
  Future<void> removerDia(int treinamentoId, int index) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await AuthService.instance.token;
      final headers = ApiConfig.getAuthHeaders(token);
      headers['Content-Type'] = 'application/json'; 
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/treinamentos/dia').replace(queryParameters: {
          'sheetId': _sheetId,
          'diaIndex': index.toString(),
        }),
        headers: headers,
      );
      if (!_disposed) await carregarDados(treinamentoId);
    } catch (e) {
      _error = "Erro ao remover dia: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remover Aluno
  Future<void> removerAluno(int treinamentoId, int rowIndex) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await AuthService.instance.token;
      final headers = ApiConfig.getAuthHeaders(token);
      headers['Content-Type'] = 'application/json';
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/treinamentos/aluno').replace(queryParameters: {
          'sheetId': _sheetId,
          'rowIndex': rowIndex.toString(),
        }),
        headers: headers,
      );
      if (!_disposed) await carregarDados(treinamentoId);
    } catch (e) {
      _error = "Erro ao remover aluno: $e";
      _isLoading = false;
      notifyListeners();
    }
  }
}