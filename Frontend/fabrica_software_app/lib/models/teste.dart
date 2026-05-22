class Teste {
  final int? id;
  final String nome;
  final String? descricao;
  final int projetoId;
  final String situacao; // Novo campo

  Teste({
    this.id,
    required this.nome,
    this.descricao,
    required this.projetoId,
    this.situacao = 'pendente', // Default para criar novos
  });

  factory Teste.fromJson(Map<String, dynamic> json) {
    return Teste(
      // Converte para String primeiro e depois tenta parsear para int
      // Isso funciona tanto se vier número (1) quanto texto ("1")
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      
      nome: json['nome'],
      descricao: json['descricao'],
      
      // Mesma proteção para o ID do projeto
      projetoId: json['projeto_id'] != null 
          ? int.parse(json['projeto_id'].toString()) 
          : 0,
          
      situacao: json['situacao'] ?? 'pendente',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'projeto_id': projetoId,
      'situacao': situacao,
    };
  }

  Teste copyWith({
    int? id,
    String? nome,
    String? descricao,
    int? projetoId,
    String? situacao,
  }) {
    return Teste(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      projetoId: projetoId ?? this.projetoId,
      situacao: situacao ?? this.situacao,
    );
  }
}