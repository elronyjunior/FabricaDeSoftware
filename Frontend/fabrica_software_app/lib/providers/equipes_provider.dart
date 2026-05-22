import 'package:fabrica_software_app/services/contribuidor_projeto_service.dart';
import 'package:flutter/material.dart';
import '../models/projeto.dart';
import '../models/contribuidor.dart';
import '../models/contribuidor_projeto.dart';
import '../services/projeto_service.dart';
import '../services/contribuidor_service.dart';


class EquipesProvider with ChangeNotifier {
  final _projetoService = ProjetoService();
  final _contribuidorService = ContribuidorService();
  final _vinculoService = ContribuidoresProjetoService.instance;

  bool _isLoading = false;
  String? _error;

  List<Projeto> _projetos = [];
  List<Contribuidor> _contribuidores = [];
  List<ContribuidorProjeto> _vinculos = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Projeto> get projetos => _projetos;
  List<Contribuidor> get contribuidores => _contribuidores;

  Future<void> carregarDados() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _projetoService.getProjetos(),
        _contribuidorService.getContribuidores(),
        _vinculoService.listarContribuidoresProjeto(),
      ]);

      _projetos = results[0] as List<Projeto>;
      _contribuidores = results[1] as List<Contribuidor>;
      _vinculos = results[2] as List<ContribuidorProjeto>;

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Contribuidor> getMembrosDoProjeto(int projetoId) {
    final vinculosDoProjeto = _vinculos.where((v) => v.projetoId == projetoId).toList();
    return _contribuidores.where((c) {
      return vinculosDoProjeto.any((v) => v.contribuidorId == c.id);
    }).toList();
  }

  // --- VINCULAR AO PROJETO ---
  Future<void> adicionarMembro(int projetoId, int contribuidorId) async {
    if (_vinculos.any((v) => v.projetoId == projetoId && v.contribuidorId == contribuidorId)) return; 

    try {
      final novoVinculo = await _vinculoService.adicionarContribuidorProjeto({
        "projeto_id": projetoId,
        "contribuidor_id": contribuidorId,
        "data_inicio": DateTime.now().toIso8601String(),
      });
      _vinculos.add(novoVinculo);
      notifyListeners();
    } catch (e) {
      _error = "Erro ao vincular: $e";
      notifyListeners();
    }
  }

  Future<void> removerMembro(int projetoId, int contribuidorId) async {
    try {
      await _vinculoService.removerVinculo(projetoId, contribuidorId);
      _vinculos.removeWhere((v) => v.projetoId == projetoId && v.contribuidorId == contribuidorId);
      notifyListeners();
    } catch (e) {
      _error = "Erro ao remover do projeto: $e";
      notifyListeners();
    }
  }

  // --- CRUD DE PESSOAS (BARRA LATERAL) ---
  Future<void> criarContribuidor(String nome, String email, String cargo) async {
    try {
      final novo = Contribuidor(nome: nome, email: email, cargo: cargo);
      final criado = await _contribuidorService.createContribuidor(novo);
      _contribuidores.add(criado);
      notifyListeners();
    } catch (e) {
      _error = "Erro ao criar: $e";
      notifyListeners();
    }
  }

  Future<void> atualizarContribuidor(int id, String nome, String email, String cargo) async {
    try {
      final att = Contribuidor(id: id, nome: nome, email: email, cargo: cargo);
      await _contribuidorService.updateContribuidor(att);
      final index = _contribuidores.indexWhere((c) => c.id == id);
      if (index != -1) {
        _contribuidores[index] = att;
        notifyListeners();
      }
    } catch (e) {
      _error = "Erro ao atualizar: $e";
      notifyListeners();
    }
  }

  Future<void> deletarContribuidor(int id) async {
    try {
      await _contribuidorService.deleteContribuidor(id);
      _contribuidores.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = "Erro ao deletar: $e";
      notifyListeners();
    }
  }
}