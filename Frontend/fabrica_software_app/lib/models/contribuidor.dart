class Contribuidor {
  final int? id;
  final String nome;
  final String email;
  final String? cargo;
  final String? empresa;
  final bool ativo;

  Contribuidor({
    this.id,
    required this.nome,
    required this.email,
    this.cargo,
    this.empresa,
    this.ativo = true,
  });

  factory Contribuidor.fromJson(Map<String, dynamic> json) {
    // Helper para evitar erro "String is not subtype of int"
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Contribuidor(
      id: parseInt(json['id']),
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cargo: json['cargo'],
      empresa: json['empresa'],
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'cargo': cargo,
      'empresa': empresa,
      'ativo': ativo,
    };
  }
}