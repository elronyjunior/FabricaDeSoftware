import 'package:flutter/foundation.dart';
import '../models/recurso.dart';
import '../services/recursos_service.dart';

class RecursosProvider with ChangeNotifier {
  final _service = RecursosService.instance;
  
  bool _isLoading = false;
  String? _error;
  List<Recurso>? _recursos;
  Recurso? _recursoSelecionado;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Recurso>? get recursos => _recursos;
  Recurso? get recursoSelecionado => _recursoSelecionado;

  // Carrega TODOS os recursos (Uso: Menu Lateral)
  Future<void> carregarRecursos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recursos = await _service.listarRecursos();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NOVO: Carrega recursos APENAS do projeto (Uso: Visualizar Projeto) ---
  Future<void> carregarRecursosPorProjeto(int projetoId) async {
    _isLoading = true;
    _error = null;
    // Limpa a lista anterior para não mostrar dados errados enquanto carrega
    _recursos = []; 
    notifyListeners();

    try {
      _recursos = await _service.listarRecursosPorProjeto(projetoId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarRecurso(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recursoSelecionado = await _service.buscarRecurso(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> criarRecurso(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recurso = await _service.criarRecurso(data);
      _recursos?.add(recurso);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarRecurso(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recurso = await _service.atualizarRecurso(id, data);
      final index = _recursos?.indexWhere((p) => p.id == id);
      if (index != null && index != -1) {
        _recursos?[index] = recurso;
      }
      if (_recursoSelecionado?.id == id) {
        _recursoSelecionado = recurso;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> excluirRecurso(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.excluirRecurso(id);
      _recursos?.removeWhere((p) => p.id == id);
      if (_recursoSelecionado?.id == id) {
        _recursoSelecionado = null;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limparErro() {
    _error = null;
    notifyListeners();
  }

  void limparRecursoSelecionado() {
    _recursoSelecionado = null;
    notifyListeners();
  }
}