class ContribuidorProjeto {
  final int? id;
  final int projetoId;
  final int contribuidorId;
  final String? dataInicio;

  ContribuidorProjeto({this.id, required this.projetoId, required this.contribuidorId, this.dataInicio});

  factory ContribuidorProjeto.fromJson(Map<String, dynamic> json) {
    // Helper de segurança
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return ContribuidorProjeto(
      id: parseInt(json['id']), 
      projetoId: parseInt(json['projeto_id']) ?? 0, // Garante int
      contribuidorId: parseInt(json['contribuidor_id']) ?? 0, // Garante int
      dataInicio: json['data_inicio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projeto_id': projetoId,
      'contribuidor_id': contribuidorId,
      'data_inicio': dataInicio,
    };
  }
}