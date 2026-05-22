import 'package:fabrica_software_app/services/projeto_service.dart';
import 'package:flutter/foundation.dart';
import '../models/projeto.dart';
import '../services/projetos_service.dart';

class ProjetosProvider with ChangeNotifier {
  final _service = ProjetoService();
  
  bool _isLoading = false;
  String? _error;
  List<Projeto> _projetos = []; // Lista original (Cache)
  
  // Variáveis de Filtro
  String _filtroNome = '';
  String _filtroCliente = '';
  String _filtroTipo = 'Todos os tipos';
  String _filtroStatus = 'Todos os status';

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Getter Mágico: Retorna a lista já filtrada
  List<Projeto> get projetos {
    if (_projetos.isEmpty) return [];

    return _projetos.where((projeto) {
      // 1. Filtro de Nome
      final nomeMatch = projeto.nomeProjeto.toLowerCase().contains(_filtroNome.toLowerCase());
      
      // 2. Filtro de Cliente (trata nulos)
      final clienteMatch = (projeto.clienteNome ?? '').toLowerCase().contains(_filtroCliente.toLowerCase());
      
      // 3. Filtro de Tipo (Modelo)
      bool tipoMatch = true;
      if (_filtroTipo != 'Todos os tipos') {
        // Compara ignorando maiusculas/minusculas
        tipoMatch = (projeto.modeloProjeto ?? '').toLowerCase() == _filtroTipo.toLowerCase();
        // Ou se preferir "contains":
        // tipoMatch = (projeto.modeloProjeto ?? '').toLowerCase().contains(_filtroTipo.toLowerCase());
      }

      // 4. Filtro de Status
      bool statusMatch = true;
      if (_filtroStatus != 'Todos os status') {
        // Usa o getter calculado que criamos no Model
        statusMatch = projeto.statusCalculado.toLowerCase() == _filtroStatus.toLowerCase();
      }

      return nomeMatch && clienteMatch && tipoMatch && statusMatch;
    }).toList();
  }

  // Ações
  Future<void> carregarProjetos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _projetos = await _service.getProjetos(); // Verifique o nome do método no seu Service
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para atualizar os filtros via Interface
  void setFiltroNome(String valor) {
    _filtroNome = valor;
    notifyListeners(); // Avisa a tela para redesenhar a lista
  }

  void setFiltroCliente(String valor) {
    _filtroCliente = valor;
    notifyListeners();
  }

  void setFiltroTipo(String? valor) {
    if (valor != null) {
      _filtroTipo = valor;
      notifyListeners();
    }
  }

  void setFiltroStatus(String? valor) {
    if (valor != null) {
      _filtroStatus = valor;
      notifyListeners();
    }
  }

  void limparFiltros() {
    _filtroNome = '';
    _filtroCliente = '';
    _filtroTipo = 'Todos os tipos';
    _filtroStatus = 'Todos os status';
    notifyListeners();
  }

  // No arquivo providers/projetos_provider.dart

Future<void> excluirProjeto(int id) async {
  try {
    await _service.deleteProjeto(id); // Chama a API
    
    // Remove da lista localmente para não precisar recarregar tudo
    _projetos.removeWhere((p) => p.id == id);
    
    notifyListeners(); // Atualiza a tela
  } catch (e) {
    _error = "Erro ao excluir: $e";
    notifyListeners();
  }
}
}