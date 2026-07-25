import 'package:flutter_test/flutter_test.dart';
import 'package:fabrica_software_app/models/documento_conteudo.dart';
import 'package:fabrica_software_app/providers/documento_editor_provider.dart';
import 'package:fabrica_software_app/providers/secao_hover_provider.dart';

DocumentoConteudo _documentoComHierarquia() {
  return DocumentoConteudo.fromJson({
    'titulo': 'Doc',
    'secoes': [
      {
        'titulo': '1. Introdução',
        'nivel': 1,
        'conteudo': '',
        'itens': <String>[],
        'subsecoes': [
          {
            'titulo': '1.1 Objetivo',
            'nivel': 2,
            'conteudo': '',
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
  });
}

void main() {
  group('DocumentoEditorProvider.alternarSelecaoParaRetrabalho', () {
    late DocumentoEditorProvider provider;

    setUp(() {
      provider = DocumentoEditorProvider(documentoId: 1, hoverProvider: SecaoHoverProvider());
      provider.documento = _documentoComHierarquia();
    });

    test('permite selecionar seções sem relação', () {
      final idA = provider.documento!.secoes[0].localId;
      final idB = provider.documento!.secoes[1].localId;

      expect(provider.alternarSelecaoParaRetrabalho(idA), isTrue);
      expect(provider.alternarSelecaoParaRetrabalho(idB), isTrue);
      expect(provider.secoesSelecionadasParaRetrabalho, {idA, idB});
    });

    test('recusa selecionar uma seção junto com sua subseção', () {
      final idPai = provider.documento!.secoes[0].localId;
      final idFilha = provider.documento!.secoes[0].subsecoes[0].localId;

      expect(provider.alternarSelecaoParaRetrabalho(idPai), isTrue);
      expect(provider.alternarSelecaoParaRetrabalho(idFilha), isFalse);
      expect(provider.secoesSelecionadasParaRetrabalho, {idPai});
    });

    test('recusa na ordem inversa (filha primeiro, depois pai)', () {
      final idPai = provider.documento!.secoes[0].localId;
      final idFilha = provider.documento!.secoes[0].subsecoes[0].localId;

      expect(provider.alternarSelecaoParaRetrabalho(idFilha), isTrue);
      expect(provider.alternarSelecaoParaRetrabalho(idPai), isFalse);
      expect(provider.secoesSelecionadasParaRetrabalho, {idFilha});
    });

    test('clicar de novo numa seção já selecionada desmarca', () {
      final idA = provider.documento!.secoes[0].localId;

      expect(provider.alternarSelecaoParaRetrabalho(idA), isTrue);
      expect(provider.alternarSelecaoParaRetrabalho(idA), isTrue);
      expect(provider.secoesSelecionadasParaRetrabalho, isEmpty);
    });
  });
}
