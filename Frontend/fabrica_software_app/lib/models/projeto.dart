import 'package:fabrica_software_app/models/enums.dart'; // Certifique-se de ter seu enum criado

class Projeto {
  final int? id;
  final String nomeProjeto;
  final String? descricao;
  final String? tipo; 
  final String? modeloProjeto;
  final String? metodologia;
  final String? escopo;
  final DateTime? dataInicio;
  final DateTime? dataFinalPrevisto;
  final DateTime? dataFinal;
  final ComplexidadeProjeto? complexidade; // Enum aqui
  final double? orcamentoEstimado;
  final DateTime? dataCriacao;
  final int clienteId;
  final String? clienteNome;
  final int? responsavelId;
  final int criadoPorId;

  Projeto({
    this.id,
    required this.nomeProjeto,
    this.descricao,
    this.tipo,
    this.modeloProjeto,
    this.metodologia,
    this.escopo,
    this.dataInicio,
    this.dataFinalPrevisto,
    this.dataFinal,
    this.complexidade,
    this.orcamentoEstimado,
    this.dataCriacao,
    required this.clienteId,
    this.clienteNome,
    this.responsavelId,
    required this.criadoPorId,
  });

  // Getter para Status visual
  String get statusCalculado {
    if (dataFinal != null) return 'Concluído';
    if (dataFinalPrevisto != null && DateTime.now().isAfter(dataFinalPrevisto!)) {
      return 'Atrasado'; 
    }
    return 'Em processo';
  }

  factory Projeto.fromJson(Map<String, dynamic> json) {
    // Helper para converter inteiros com segurança
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper para converter String -> Enum
    ComplexidadeProjeto? parseComplexidade(String? value) {
      if (value == null) return null;
      try {
        return ComplexidadeProjeto.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toLowerCase()
        );
      } catch (e) {
        return null;
      }
    }

    return Projeto(
      id: parseInt(json['id']),
      nomeProjeto: json['nome_projeto'] ?? 'Sem Nome',
      descricao: json['descricao'],
      tipo: json['tipo'],
      modeloProjeto: json['modelo_projeto'],
      metodologia: json['metodologia'],
      escopo: json['escopo'],
      
      dataInicio: json['data_inicio'] != null 
          ? DateTime.tryParse(json['data_inicio'].toString()) 
          : null,
      dataFinalPrevisto: json['data_final_previsto'] != null 
          ? DateTime.tryParse(json['data_final_previsto'].toString()) 
          : null,
      dataFinal: json['data_final'] != null 
          ? DateTime.tryParse(json['data_final'].toString()) 
          : null,
          
      complexidade: parseComplexidade(json['complexidade']), // Uso do helper
          
      orcamentoEstimado: json['orcamento_estimado'] != null 
          ? double.tryParse(json['orcamento_estimado'].toString())
          : null,
          
      dataCriacao: json['data_criacao'] != null 
          ? DateTime.tryParse(json['data_criacao'].toString()) 
          : null,
          
      clienteId: parseInt(json['cliente_id']) ?? 0,
      clienteNome: json['cliente_nome'], 
      responsavelId: parseInt(json['responsavel_id']),
      criadoPorId: parseInt(json['criado_por_id']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_projeto': nomeProjeto,
      'descricao': descricao,
      'tipo': tipo,
      'modelo_projeto': modeloProjeto,
      'metodologia': metodologia,
      'escopo': escopo,
      'data_inicio': dataInicio?.toIso8601String(),
      'data_final_previsto': dataFinalPrevisto?.toIso8601String(),
      'data_final': dataFinal?.toIso8601String(),
      'complexidade': complexidade?.name, // Converte Enum -> String ('alta', 'media')
      'orcamento_estimado': orcamentoEstimado,
      'data_criacao': dataCriacao?.toIso8601String(),
      'cliente_id': clienteId,
      'responsavel_id': responsavelId,
      'criado_por_id': criadoPorId,
    };
  }
}