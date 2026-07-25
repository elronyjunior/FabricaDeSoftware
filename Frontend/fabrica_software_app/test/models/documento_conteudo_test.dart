import 'package:flutter_test/flutter_test.dart';
import 'package:fabrica_software_app/models/documento_conteudo.dart';

void main() {
  final jsonExemplo = {
    'titulo': 'Documento de Teste',
    'tipo_documento': 'Requisitos',
    'versao': '1.0',
    'metadata': {'projeto': 'Projeto X', 'autor': 'IA', 'objetivo': 'Testar'},
    'sumario_executivo': 'Resumo.',
    'secoes': [
      {
        'titulo': '1. Introdução',
        'nivel': 1,
        'conteudo': 'Texto.',
        'itens': ['A', 'B'],
        'subsecoes': [
          {
            'titulo': '1.1 Objetivo',
            'nivel': 2,
            'conteudo': 'Texto do objetivo.',
            'itens': <String>[],
            'subsecoes': <Map<String, dynamic>>[],
          },
        ],
      },
      {
        'titulo': '2. Escopo',
        'nivel': 1,
        'conteudo': '',
        'itens': <String>[],
        'subsecoes': <Map<String, dynamic>>[],
      },
    ],
    'tabelas': [
      {
        'titulo': 'Tabela 1',
        'cabecalhos': ['Col A', 'Col B'],
        'linhas': [
          ['1', '2'],
        ],
      },
    ],
    'conclusao': 'Fim.',
  };

  group('DocumentoConteudo.fromJson', () {
    test('faz parse da árvore aninhada e atribui profundidade corretamente', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);

      expect(doc.titulo, 'Documento de Teste');
      expect(doc.secoes, hasLength(2));
      expect(doc.secoes[0].titulo, '1. Introdução');
      expect(doc.secoes[0].depth, 0);
      expect(doc.secoes[0].subsecoes, hasLength(1));
      expect(doc.secoes[0].subsecoes[0].depth, 1);
      expect(doc.secoes[0].subsecoes[0].parentLocalId, doc.secoes[0].localId);
      expect(doc.secoes[1].depth, 0);
      expect(doc.secoes[1].parentLocalId, isNull);
    });

    test('faz parse das tabelas como somente leitura', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      expect(doc.tabelas, hasLength(1));
      expect(doc.tabelas[0].cabecalhos, ['Col A', 'Col B']);
      expect(doc.tabelas[0].linhas, [
        ['1', '2'],
      ]);
    });

    test('localIds são únicos em toda a árvore', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final ids = [
        doc.secoes[0].localId,
        doc.secoes[0].subsecoes[0].localId,
        doc.secoes[1].localId,
      ];
      expect(ids.toSet().length, ids.length);
    });
  });

  group('DocumentoConteudo.toJson', () {
    test('não vaza localId/parentLocalId/depth (bookkeeping do cliente)', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final json = doc.toJson();
      final secaoJson = (json['secoes'] as List)[0] as Map<String, dynamic>;

      expect(secaoJson.containsKey('localId'), isFalse);
      expect(secaoJson.containsKey('parentLocalId'), isFalse);
      expect(secaoJson.containsKey('depth'), isFalse);
      expect(secaoJson.keys, containsAll(['titulo', 'nivel', 'conteudo', 'itens', 'subsecoes']));
    });

    test('round-trip preserva o conteúdo', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final json = doc.toJson();

      expect(json['titulo'], jsonExemplo['titulo']);
      expect((json['secoes'] as List).length, 2);
      expect(((json['secoes'] as List)[0] as Map)['subsecoes'], hasLength(1));
    });
  });

  group('Mutações estruturais', () {
    test('adicionarSecaoIrma insere logo depois, no mesmo nível', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final idIntroducao = doc.secoes[0].localId;

      doc.adicionarSecaoIrma(idIntroducao);

      expect(doc.secoes, hasLength(3));
      expect(doc.secoes[1].titulo, ''); // nova seção em branco
      expect(doc.secoes[1].nivel, 1); // mesmo nível da referência
      expect(doc.secoes[1].parentLocalId, isNull);
    });

    test('adicionarSubsecao cria filho com nivel = pai + 1 (capado em 3)', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final idObjetivo = doc.secoes[0].subsecoes[0].localId; // nivel 2

      doc.adicionarSubsecao(idObjetivo);

      final novaLista = doc.secoes[0].subsecoes[0].subsecoes;
      expect(novaLista, hasLength(1));
      expect(novaLista[0].nivel, 3);

      doc.adicionarSubsecao(novaLista[0].localId);
      expect(novaLista[0].subsecoes[0].nivel, 3); // capado, não vira 4
    });

    test('removerSecao remove a subárvore inteira', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final idIntroducao = doc.secoes[0].localId;
      final idObjetivo = doc.secoes[0].subsecoes[0].localId;

      doc.removerSecao(idIntroducao);

      expect(doc.secoes, hasLength(1));
      expect(doc.secoes[0].titulo, '2. Escopo');
      expect(doc.buscarPorLocalId(idIntroducao), isNull);
      expect(doc.buscarPorLocalId(idObjetivo), isNull);
    });

    test('buscarPorLocalId encontra seções em qualquer profundidade', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final idObjetivo = doc.secoes[0].subsecoes[0].localId;

      expect(doc.buscarPorLocalId(idObjetivo)?.titulo, '1.1 Objetivo');
      expect(doc.buscarPorLocalId(99999), isNull);
    });

    test('profundidadePorId reflete a árvore atual após mutações', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      doc.adicionarSubsecao(doc.secoes[0].subsecoes[0].localId);

      final novoId = doc.secoes[0].subsecoes[0].subsecoes[0].localId;
      expect(doc.profundidadePorId[novoId], 2);
    });
  });

  group('caminhoDoId / buscarPorCaminho (retrabalho com IA)', () {
    test('caminhoDoId encontra seções raiz e aninhadas', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);

      expect(doc.caminhoDoId(doc.secoes[0].localId), [0]);
      expect(doc.caminhoDoId(doc.secoes[0].subsecoes[0].localId), [0, 0]);
      expect(doc.caminhoDoId(doc.secoes[1].localId), [1]);
    });

    test('caminhoDoId retorna null para um id que não existe', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      expect(doc.caminhoDoId(99999), isNull);
    });

    test('buscarPorCaminho é o inverso de caminhoDoId', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final alvo = doc.secoes[0].subsecoes[0];

      final caminho = doc.caminhoDoId(alvo.localId)!;
      expect(doc.buscarPorCaminho(caminho), same(alvo));
    });

    test('buscarPorCaminho retorna null para caminho fora dos limites', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      expect(doc.buscarPorCaminho([99]), isNull);
      expect(doc.buscarPorCaminho([0, 99]), isNull);
    });
  });

  group('relacionadas (guard de seleção pra retrabalho com IA)', () {
    test('uma seção é relacionada a si mesma', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final id = doc.secoes[0].localId;
      expect(doc.relacionadas(id, id), isTrue);
    });

    test('pai e filha são relacionados', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final idPai = doc.secoes[0].localId;
      final idFilha = doc.secoes[0].subsecoes[0].localId;
      expect(doc.relacionadas(idPai, idFilha), isTrue);
      expect(doc.relacionadas(idFilha, idPai), isTrue);
    });

    test('seções irmãs não são relacionadas', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final idA = doc.secoes[0].localId;
      final idB = doc.secoes[1].localId;
      expect(doc.relacionadas(idA, idB), isFalse);
    });

    test('tio e sobrinha não são relacionados', () {
      final doc = DocumentoConteudo.fromJson(jsonExemplo);
      final idTio = doc.secoes[1].localId; // "2. Escopo", sem filhos
      final idSobrinha = doc.secoes[0].subsecoes[0].localId; // filha de "1. Introdução"
      expect(doc.relacionadas(idTio, idSobrinha), isFalse);
    });
  });
}
