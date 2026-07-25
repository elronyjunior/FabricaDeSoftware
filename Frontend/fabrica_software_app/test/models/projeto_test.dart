import 'package:flutter_test/flutter_test.dart';
import 'package:fabrica_software_app/models/projeto.dart';
import 'package:fabrica_software_app/models/enums.dart';

void main() {
  group('Projeto.fromJson', () {
    test('faz parse de um JSON completo vindo do backend', () {
      final projeto = Projeto.fromJson({
        'id': 1,
        'nome_projeto': 'Sistema X',
        'descricao': 'Descrição do projeto',
        'tipo': 'WEB',
        'modelo_projeto': 'Ágil',
        'metodologia': 'Scrum',
        'escopo': 'Escopo completo',
        'data_inicio': '2026-01-10',
        'data_final_previsto': '2026-06-10',
        'data_final': null,
        'complexidade': 'alta',
        'orcamento_estimado': 50000.5,
        'data_criacao': '2026-01-01T12:00:00.000Z',
        'cliente_id': 3,
        'cliente_nome': 'Cliente Teste',
        'responsavel_id': 7,
        'criado_por_id': 9,
      });

      expect(projeto.id, 1);
      expect(projeto.nomeProjeto, 'Sistema X');
      expect(projeto.complexidade, ComplexidadeProjeto.alta);
      expect(projeto.orcamentoEstimado, 50000.5);
      expect(projeto.clienteId, 3);
      expect(projeto.responsavelId, 7);
      expect(projeto.criadoPorId, 9);
      expect(projeto.dataInicio, DateTime.parse('2026-01-10'));
    });

    test('aceita orcamento_estimado como string (Postgres numeric)', () {
      final projeto = Projeto.fromJson({
        'nome_projeto': 'Sistema Y',
        'orcamento_estimado': '12345.67',
        'cliente_id': 1,
        'criado_por_id': 1,
      });

      expect(projeto.orcamentoEstimado, 12345.67);
    });

    test('usa valores padrão quando campos opcionais estão ausentes', () {
      final projeto = Projeto.fromJson({'cliente_id': 1, 'criado_por_id': 1});

      expect(projeto.nomeProjeto, 'Sem Nome');
      expect(projeto.descricao, isNull);
      expect(projeto.complexidade, isNull);
      expect(projeto.orcamentoEstimado, isNull);
      expect(projeto.dataInicio, isNull);
    });

    test('ids em formato string (bigint do Postgres) são convertidos para int', () {
      final projeto = Projeto.fromJson({
        'id': '42',
        'cliente_id': '3',
        'responsavel_id': '7',
        'criado_por_id': '9',
      });

      expect(projeto.id, 42);
      expect(projeto.clienteId, 3);
      expect(projeto.responsavelId, 7);
      expect(projeto.criadoPorId, 9);
    });

    test('complexidade desconhecida cai para null', () {
      final projeto = Projeto.fromJson({
        'cliente_id': 1,
        'criado_por_id': 1,
        'complexidade': 'inexistente',
      });

      expect(projeto.complexidade, isNull);
    });
  });

  group('Projeto.toJson', () {
    test('serializa de volta para o formato esperado pelo backend', () {
      final projeto = Projeto(
        id: 1,
        nomeProjeto: 'Sistema X',
        complexidade: ComplexidadeProjeto.media,
        orcamentoEstimado: 1000.0,
        clienteId: 2,
        criadoPorId: 3,
      );

      final json = projeto.toJson();

      expect(json['nome_projeto'], 'Sistema X');
      expect(json['complexidade'], 'media');
      expect(json['orcamento_estimado'], 1000.0);
      expect(json['cliente_id'], 2);
    });
  });

  group('Projeto.statusCalculado', () {
    test('retorna Concluído quando data_final está preenchida', () {
      final projeto = Projeto(
        nomeProjeto: 'X',
        clienteId: 1,
        criadoPorId: 1,
        dataFinal: DateTime(2026, 1, 1),
      );

      expect(projeto.statusCalculado, 'Concluído');
    });

    test('retorna Atrasado quando a previsão já passou e não há data final', () {
      final projeto = Projeto(
        nomeProjeto: 'X',
        clienteId: 1,
        criadoPorId: 1,
        dataFinalPrevisto: DateTime(2000, 1, 1),
      );

      expect(projeto.statusCalculado, 'Atrasado');
    });

    test('retorna Em processo quando ainda dentro do prazo', () {
      final projeto = Projeto(
        nomeProjeto: 'X',
        clienteId: 1,
        criadoPorId: 1,
        dataFinalPrevisto: DateTime(2999, 1, 1),
      );

      expect(projeto.statusCalculado, 'Em processo');
    });
  });
}
