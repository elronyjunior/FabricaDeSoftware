import 'package:flutter_test/flutter_test.dart';
import 'package:fabrica_software_app/models/documento_conteudo.dart';
import 'package:fabrica_software_app/models/revisao_documento.dart';

DocumentoConteudo _documentoBase() {
  return DocumentoConteudo.fromJson({
    'titulo': 'Doc',
    'secoes': [
      {
        'titulo': '1. Introdução',
        'nivel': 1,
        'conteudo': 'Texto original.',
        'itens': ['Item A', 'Item B'],
        'subsecoes': [
          {
            'titulo': '1.1 Objetivo',
            'nivel': 2,
            'conteudo': 'Objetivo original.',
            'itens': <String>[],
            'subsecoes': <Map<String, dynamic>>[],
          },
        ],
      },
      {
        'titulo': '2. Escopo',
        'nivel': 1,
        'conteudo': 'Escopo original.',
        'itens': <String>[],
        'subsecoes': <Map<String, dynamic>>[],
      },
    ],
  });
}

void main() {
  group('SnapshotDocumento', () {
    test('sem mudanças, tudo fica inalterado', () {
      final doc = _documentoBase();
      final snapshot = SnapshotDocumento.capturar(doc);

      final arvore = snapshot.construirArvore(doc);

      expect(arvore.every((n) => n.status == StatusRevisao.inalterado), isTrue);
      expect(arvore[0].subsecoes.single.status, StatusRevisao.inalterado);
    });

    test('editar o título marca a seção como modificado', () {
      final doc = _documentoBase();
      final snapshot = SnapshotDocumento.capturar(doc);

      doc.secoes[0].titulo = '1. Introdução Editada';

      final arvore = snapshot.construirArvore(doc);
      expect(arvore[0].status, StatusRevisao.modificado);
      expect(arvore[1].status, StatusRevisao.inalterado); // não afeta a outra seção
    });

    test('nova seção aparece como novo', () {
      final doc = _documentoBase();
      final snapshot = SnapshotDocumento.capturar(doc);

      doc.adicionarSecaoIrma(doc.secoes[1].localId);

      final arvore = snapshot.construirArvore(doc);
      expect(arvore, hasLength(3));
      expect(arvore[2].status, StatusRevisao.novo);
    });

    test('nova subseção dentro de seção existente aparece como novo', () {
      final doc = _documentoBase();
      final snapshot = SnapshotDocumento.capturar(doc);

      doc.adicionarSubsecao(doc.secoes[0].localId);

      final arvore = snapshot.construirArvore(doc);
      expect(arvore[0].status, StatusRevisao.inalterado); // a seção pai em si não mudou
      expect(arvore[0].subsecoes, hasLength(2));
      expect(arvore[0].subsecoes[1].status, StatusRevisao.novo);
    });

    test('remover uma seção mostra ela de volta como removido, com o texto original', () {
      final doc = _documentoBase();
      final snapshot = SnapshotDocumento.capturar(doc);

      doc.removerSecao(doc.secoes[0].localId);

      final arvore = snapshot.construirArvore(doc);
      expect(arvore, hasLength(2)); // "1. Introdução" removida volta a aparecer
      expect(arvore[0].status, StatusRevisao.removido);
      expect(arvore[0].titulo, '1. Introdução');
      expect(arvore[1].titulo, '2. Escopo');
      expect(arvore[1].status, StatusRevisao.inalterado);
    });

    test('remover uma seção com subseções marca toda a subárvore como removido', () {
      final doc = _documentoBase();
      final snapshot = SnapshotDocumento.capturar(doc);

      doc.removerSecao(doc.secoes[0].localId);

      final arvore = snapshot.construirArvore(doc);
      final removida = arvore.firstWhere((n) => n.titulo == '1. Introdução');
      expect(removida.subsecoes, hasLength(1));
      expect(removida.subsecoes[0].status, StatusRevisao.removido);
      expect(removida.subsecoes[0].titulo, '1.1 Objetivo');
    });

    test('itens: item novo marca novo, item removido volta marcado como removido', () {
      final doc = _documentoBase();
      final snapshot = SnapshotDocumento.capturar(doc);

      final secao = doc.secoes[0];
      secao.itens.removeAt(0); // remove "Item A"
      secao.itens.add('Item C'); // adiciona novo

      final arvore = snapshot.construirArvore(doc);
      final itens = arvore[0].itens;

      expect(itens.firstWhere((i) => i.texto == 'Item B').status, StatusRevisao.inalterado);
      expect(itens.firstWhere((i) => i.texto == 'Item C').status, StatusRevisao.novo);
      expect(itens.firstWhere((i) => i.texto == 'Item A').status, StatusRevisao.removido);
    });
  });
}
