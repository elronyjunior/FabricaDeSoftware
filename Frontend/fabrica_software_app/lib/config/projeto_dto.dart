import 'package:fabrica_software_app/models/projeto.dart';

class ProjetoDTO {
  int? id; 
  String? nome;
  String? descricao;
  String? modelo;
  String? tipo;
  String? metodologia;
  
  // --- NOVOS CAMPOS ---
  Map<String, dynamic>? cliente;
  Map<String, dynamic>? responsavel; // <--- NOVO: Guarda {id: 1, nome: "João"}

  String? escopo;
  List<Map<String, dynamic>> requisitos = [];
  List<Map<String, dynamic>> tecnologias = [];
  List<Map<String, dynamic>> equipe = [];
  List<Map<String, dynamic>> recursos = [];

  DateTime? dataInicio;
  DateTime? dataFinalPrevista;
  double? orcamentoEstimado;
  String? complexidade;

  void clear() {
    id = null;
    nome = null;
    descricao = null;
    modelo = null;
    tipo = null;
    metodologia = null;
    cliente = null;
    responsavel = null; // <--- Limpar
    escopo = null;
    tecnologias = [];
    equipe = [];
    recursos = [];
    requisitos = [];
    dataInicio = null;
    dataFinalPrevista = null;
    orcamentoEstimado = null;
    complexidade = null;
  }

  void loadFromModel(Projeto p) {
    id = p.id;
    nome = p.nomeProjeto;
    descricao = p.descricao;
    tipo = _normalizarOpcao(p.tipo, ['Web', 'Mobile', 'Desktop', 'API', 'Híbrido', 'Outro']);
    modelo = _normalizarOpcao(p.modeloProjeto, ['SaaS', 'Marketplace', 'E-commerce', 'B2B', 'Institucional', 'Interno', 'Outros']);
    metodologia = p.metodologia;
    escopo = p.escopo;
    dataInicio = p.dataInicio;
    dataFinalPrevista = p.dataFinalPrevisto;
    orcamentoEstimado = p.orcamentoEstimado;
    complexidade = p.complexidade?.name; 

    // Cliente
    if (p.clienteId != 0) {
      cliente = {
        'id': p.clienteId,
        'razao_social': p.clienteNome ?? 'Cliente Atual'
      };
    }

    // Responsável (Novo)
    if (p.responsavelId != null && p.responsavelId != 0) {
      responsavel = {
        'id': p.responsavelId,
        // Como o Model Projeto básico as vezes não tem o nome do responsável, 
        // colocamos um placeholder que será corrigido pelo Dropdown ao carregar a lista de usuários
        'nome': 'Responsável Atual' 
      };
    }
  }

  String? _normalizarOpcao(String? valorBanco, List<String> opcoesDropdown) {
    if (valorBanco == null) return null;
    try {
      return opcoesDropdown.firstWhere(
        (opcao) => opcao.toUpperCase() == valorBanco.toUpperCase()
      );
    } catch (e) {
      return null; 
    }
  }
}

final projetoDraft = ProjetoDTO();