import 'package:flutter/material.dart';
import '../models/teste.dart';
import '../services/testes_service.dart';

class TestesProvider with ChangeNotifier {
  final TestesService _service = TestesService.instance;
  
  List<Teste> _testes = [];
  bool _isLoading = false;
  String? _erro;

  List<Teste> get testes => _testes;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  // Carrega e já notifica
  Future<void> carregarTestes(int projetoId) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _testes = await _service.listarPorProjeto(projetoId);
    } catch (e) {
      _erro = 'Erro: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarTeste(Teste teste) async {
    try {
      final novo = await _service.criarTeste(teste.toJson());
      _testes.add(novo);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> atualizarTeste(Teste teste) async {
    try {
      final atualizado = await _service.atualizarTeste(teste.id!, teste.toJson());
      final index = _testes.indexWhere((t) => t.id == teste.id);
      if (index >= 0) {
        _testes[index] = atualizado;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> excluirTeste(int id) async {
    try {
      await _service.excluirTeste(id);
      _testes.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}