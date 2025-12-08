class Usuario {
  final int? id;
  final String nome;
  final String email;
  final String? nivel; // 'admin', 'colaborador', etc.
  final String? telefone;
  final String? senha; // Usado apenas para envio (Create/Update)

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    this.nivel,
    this.telefone,
    this.senha,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      // CORREÇÃO: Verifica se 'id' é String e faz o parse, ou usa como int se já for número
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      nome: json['nome'] ?? '', // Garante que não quebre se vier null
      email: json['email'] ?? '',
      nivel: json['nivel'],
      telefone: json['telefone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'nivel': nivel,
      'telefone': telefone,
      'senha': senha,
    };
  }
}