import 'package:fabrica_software_app/models/documento_conteudo.dart';

// Suporte para a visão "Ver Alterações": compara o estado ATUAL do
// documento contra um snapshot tirado no momento em que foi carregado nesta
// sessão de edição. Vive só na memória - nunca é enviado ao backend, e some
// quando a tela fecha (não é a rastreabilidade permanente combinada para uma
// etapa futura, é só um "o que mudou desde que abri" temporário).

enum StatusRevisao { novo, modificado, inalterado, removido }

class ItemRevisao {
  final String texto;
  final StatusRevisao status;

  ItemRevisao(this.texto, this.status);
}

class NoRevisao {
  final int localId;
  final String titulo;
  final int nivel;
  final String conteudo;
  final int depth;
  final StatusRevisao status;
  final List<ItemRevisao> itens;
  final List<NoRevisao> subsecoes;

  NoRevisao({
    required this.localId,
    required this.titulo,
    required this.nivel,
    required this.conteudo,
    required this.depth,
    required this.status,
    required this.itens,
    required this.subsecoes,
  });
}

class _SecaoSnapshot {
  final String titulo;
  final int nivel;
  final String conteudo;
  final List<String> itens;
  final List<int> filhosOriginais;

  _SecaoSnapshot({
    required this.titulo,
    required this.nivel,
    required this.conteudo,
    required this.itens,
    required this.filhosOriginais,
  });
}

class SnapshotDocumento {
  final Map<int, _SecaoSnapshot> _porId = {};
  final List<int> _raizOriginal = [];

  SnapshotDocumento.capturar(DocumentoConteudo documento) {
    _raizOriginal.addAll(documento.secoes.map((s) => s.localId));
    for (final secao in documento.secoes) {
      _capturarRecursivo(secao);
    }
  }

  void _capturarRecursivo(SecaoDocumento secao) {
    _porId[secao.localId] = _SecaoSnapshot(
      titulo: secao.titulo,
      nivel: secao.nivel,
      conteudo: secao.conteudo,
      itens: List.of(secao.itens),
      filhosOriginais: secao.subsecoes.map((s) => s.localId).toList(),
    );
    for (final sub in secao.subsecoes) {
      _capturarRecursivo(sub);
    }
  }

  // Mescla a árvore atual com o snapshot original: seções removidas voltam a
  // aparecer (marcadas), na posição relativa em que estavam originalmente.
  List<NoRevisao> construirArvore(DocumentoConteudo atual) {
    return _mesclarNivel(_raizOriginal, atual.secoes, 0);
  }

  List<NoRevisao> _mesclarNivel(List<int> idsOriginaisNivel, List<SecaoDocumento> atuaisNivel, int depth) {
    final resultado = <NoRevisao>[];
    final idsAtuais = atuaisNivel.map((s) => s.localId).toSet();
    final emitidos = <int>{};

    void emitirRemovidosAte(int? idAlvo) {
      for (final idOriginal in idsOriginaisNivel) {
        if (emitidos.contains(idOriginal)) continue;
        if (idAlvo != null && idOriginal == idAlvo) break;
        if (!idsAtuais.contains(idOriginal)) {
          resultado.add(_construirRemovido(idOriginal, depth));
          emitidos.add(idOriginal);
        } else {
          break;
        }
      }
    }

    for (final secaoAtual in atuaisNivel) {
      emitirRemovidosAte(secaoAtual.localId);
      resultado.add(_construirAtual(secaoAtual, depth));
      emitidos.add(secaoAtual.localId);
    }
    emitirRemovidosAte(null);

    return resultado;
  }

  NoRevisao _construirAtual(SecaoDocumento secao, int depth) {
    final original = _porId[secao.localId];
    final status = original == null
        ? StatusRevisao.novo
        : (_secaoMudou(original, secao) ? StatusRevisao.modificado : StatusRevisao.inalterado);

    return NoRevisao(
      localId: secao.localId,
      titulo: secao.titulo,
      nivel: secao.nivel,
      conteudo: secao.conteudo,
      depth: depth,
      status: status,
      itens: _mesclarItens(original?.itens ?? const [], secao.itens),
      subsecoes: _mesclarNivel(original?.filhosOriginais ?? const [], secao.subsecoes, depth + 1),
    );
  }

  NoRevisao _construirRemovido(int localId, int depth) {
    final original = _porId[localId];
    if (original == null) {
      return NoRevisao(
        localId: localId,
        titulo: '',
        nivel: 1,
        conteudo: '',
        depth: depth,
        status: StatusRevisao.removido,
        itens: const [],
        subsecoes: const [],
      );
    }

    return NoRevisao(
      localId: localId,
      titulo: original.titulo,
      nivel: original.nivel,
      conteudo: original.conteudo,
      depth: depth,
      status: StatusRevisao.removido,
      itens: original.itens.map((texto) => ItemRevisao(texto, StatusRevisao.removido)).toList(),
      subsecoes: _mesclarNivel(original.filhosOriginais, const [], depth + 1),
    );
  }

  bool _secaoMudou(_SecaoSnapshot original, SecaoDocumento atual) {
    if (original.titulo != atual.titulo) return true;
    if (original.nivel != atual.nivel) return true;
    if (original.conteudo != atual.conteudo) return true;
    if (!_listasIguais(original.itens, atual.itens)) return true;
    return false;
  }

  bool _listasIguais(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Itens de uma seção não têm id próprio - tratados como multiconjunto:
  // presente nos dois = inalterado, só no atual = novo, só no original =
  // removido (aparece ao final, riscado).
  List<ItemRevisao> _mesclarItens(List<String> originais, List<String> atuais) {
    final restantesOriginais = List.of(originais);
    final resultado = <ItemRevisao>[];

    for (final texto in atuais) {
      final indice = restantesOriginais.indexOf(texto);
      if (indice >= 0) {
        resultado.add(ItemRevisao(texto, StatusRevisao.inalterado));
        restantesOriginais.removeAt(indice);
      } else {
        resultado.add(ItemRevisao(texto, StatusRevisao.novo));
      }
    }

    for (final restante in restantesOriginais) {
      resultado.add(ItemRevisao(restante, StatusRevisao.removido));
    }

    return resultado;
  }
}
