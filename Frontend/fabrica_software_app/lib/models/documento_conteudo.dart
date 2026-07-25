// Modelo do JSON estruturado de um documento (o mesmo shape gerado pela IA
// em backend/service/ai/aiPrompts.js - DOCUMENTO_SCHEMA). Árvore mutável de
// propósito: com profundidade arbitrária e edições frequentes, reconstruir a
// cadeia de ancestrais a cada tecla (estilo copyWith imutável) não compensa -
// nada aqui depende de garantias de imutabilidade.

class DocumentoMetadata {
  String? projeto;
  String? autor;
  String? objetivo;

  DocumentoMetadata({this.projeto, this.autor, this.objetivo});

  factory DocumentoMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentoMetadata(
      projeto: json['projeto'] as String?,
      autor: json['autor'] as String?,
      objetivo: json['objetivo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'projeto': projeto,
        'autor': autor,
        'objetivo': objetivo,
      };
}

class SecaoDocumento {
  String titulo;
  int nivel;
  String conteudo;
  List<String> itens;
  List<SecaoDocumento> subsecoes;

  // Bookkeeping só do cliente - NUNCA deve ser serializado de volta pro
  // backend (ver toJson: whitelist explícito dos campos do schema).
  int localId = -1;
  int? parentLocalId;
  int depth = 0;

  SecaoDocumento({
    this.titulo = '',
    this.nivel = 1,
    this.conteudo = '',
    List<String>? itens,
    List<SecaoDocumento>? subsecoes,
  })  : itens = itens ?? [],
        subsecoes = subsecoes ?? [];

  factory SecaoDocumento.fromJson(Map<String, dynamic> json) {
    return SecaoDocumento(
      titulo: json['titulo'] as String? ?? '',
      nivel: (json['nivel'] as num?)?.toInt() ?? 1,
      conteudo: json['conteudo'] as String? ?? '',
      itens: (json['itens'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      subsecoes: (json['subsecoes'] as List<dynamic>? ?? [])
          .map((s) => SecaoDocumento.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'nivel': nivel,
        'conteudo': conteudo,
        'itens': itens,
        'subsecoes': subsecoes.map((s) => s.toJson()).toList(),
      };
}

class TabelaDocumento {
  final String? titulo;
  final List<String> cabecalhos;
  final List<List<String>> linhas;

  TabelaDocumento({this.titulo, List<String>? cabecalhos, List<List<String>>? linhas})
      : cabecalhos = cabecalhos ?? [],
        linhas = linhas ?? [];

  factory TabelaDocumento.fromJson(Map<String, dynamic> json) {
    return TabelaDocumento(
      titulo: json['titulo'] as String?,
      cabecalhos: (json['cabecalhos'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      linhas: (json['linhas'] as List<dynamic>? ?? [])
          .map((linha) => (linha as List<dynamic>).map((e) => e.toString()).toList())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'cabecalhos': cabecalhos,
        'linhas': linhas,
      };
}

class DocumentoConteudo {
  String titulo;
  String? tipoDocumento;
  String? versao;
  DocumentoMetadata metadata;
  String? sumarioExecutivo;
  List<SecaoDocumento> secoes;
  List<TabelaDocumento> tabelas;
  String? conclusao;

  int _proximoLocalId = 0;
  final Map<int, SecaoDocumento> _registro = {};

  DocumentoConteudo({
    this.titulo = 'Documento',
    this.tipoDocumento,
    this.versao,
    DocumentoMetadata? metadata,
    this.sumarioExecutivo,
    List<SecaoDocumento>? secoes,
    List<TabelaDocumento>? tabelas,
    this.conclusao,
  })  : metadata = metadata ?? DocumentoMetadata(),
        secoes = secoes ?? [],
        tabelas = tabelas ?? [] {
    reanotar();
  }

  factory DocumentoConteudo.fromJson(Map<String, dynamic> json) {
    return DocumentoConteudo(
      titulo: json['titulo'] as String? ?? 'Documento',
      tipoDocumento: json['tipo_documento'] as String?,
      versao: json['versao'] as String?,
      metadata: DocumentoMetadata.fromJson((json['metadata'] as Map<String, dynamic>?) ?? {}),
      sumarioExecutivo: json['sumario_executivo'] as String?,
      secoes: (json['secoes'] as List<dynamic>? ?? [])
          .map((s) => SecaoDocumento.fromJson(s as Map<String, dynamic>))
          .toList(),
      tabelas: (json['tabelas'] as List<dynamic>? ?? [])
          .map((t) => TabelaDocumento.fromJson(t as Map<String, dynamic>))
          .toList(),
      conclusao: json['conclusao'] as String?,
    );
  }

  // Whitelist explícito: localId/parentLocalId/depth de SecaoDocumento nunca
  // devem vazar pro JSON enviado ao backend.
  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'tipo_documento': tipoDocumento,
        'versao': versao,
        'metadata': metadata.toJson(),
        'sumario_executivo': sumarioExecutivo,
        'secoes': secoes.map((s) => s.toJson()).toList(),
        'tabelas': tabelas.map((t) => t.toJson()).toList(),
        'conclusao': conclusao,
      };

  // Recomputa parentLocalId/depth em toda a árvore e reconstrói o registro.
  // Chamado no construtor e depois de qualquer mutação estrutural (add/remove
  // seção). NÃO reatribui localId de seções que já têm um (só novas seções,
  // ainda no valor-sentinela -1, ganham um id novo) — os ids precisam ser
  // estáveis entre mutações, senão um add/remove numa parte da árvore
  // reciclaria o número de uma seção removida para uma seção sobrevivente
  // sem relação nenhuma, corrompendo qualquer referência guardada (ex:
  // selectedSecaoId no editor) para a seção errada.
  void reanotar() {
    _registro.clear();
    for (final secao in secoes) {
      _anotarSecao(secao, null, 0);
    }
  }

  void _anotarSecao(SecaoDocumento secao, int? parentLocalId, int profundidade) {
    if (secao.localId == -1) {
      secao.localId = _proximoLocalId;
      _proximoLocalId += 1;
    }
    secao.parentLocalId = parentLocalId;
    secao.depth = profundidade;
    _registro[secao.localId] = secao;
    for (final sub in secao.subsecoes) {
      _anotarSecao(sub, secao.localId, profundidade + 1);
    }
  }

  SecaoDocumento? buscarPorLocalId(int localId) => _registro[localId];

  Map<int, int> get profundidadePorId => {
        for (final entrada in _registro.entries) entrada.key: entrada.value.depth,
      };

  // Caminho (índices por nível) até a seção com esse localId — usado para
  // pedir retrabalho de seções específicas à IA: o backend não conhece
  // localId (é só bookkeeping do cliente), então o caminho é a forma de
  // identificar "esta seção exata" na estrutura enviada.
  List<int>? caminhoDoId(int localId) {
    List<int>? buscar(List<SecaoDocumento> nivel, List<int> caminhoAtual) {
      for (var i = 0; i < nivel.length; i++) {
        final caminho = [...caminhoAtual, i];
        if (nivel[i].localId == localId) return caminho;
        final encontrado = buscar(nivel[i].subsecoes, caminho);
        if (encontrado != null) return encontrado;
      }
      return null;
    }

    return buscar(secoes, []);
  }

  // Inverso de caminhoDoId — usado para aplicar de volta o resultado do
  // retrabalho com IA na seção correta.
  SecaoDocumento? buscarPorCaminho(List<int> caminho) {
    List<SecaoDocumento> nivelAtual = secoes;
    SecaoDocumento? secao;

    for (final indice in caminho) {
      if (indice < 0 || indice >= nivelAtual.length) return null;
      secao = nivelAtual[indice];
      nivelAtual = secao.subsecoes;
    }

    return secao;
  }

  // true se uma das seções é ancestral da outra (ou são a mesma). Usado
  // pra bloquear selecionar uma seção junto com seu pai/filha pra retrabalho
  // com IA: se a IA reescrever o pai e devolver uma lista de subseções
  // diferente (mesmo instruída a não reestruturar, não dá pra confiar 100%
  // nisso), o resultado do retrabalho independente da filha se perderia ao
  // aplicar o do pai por cima.
  bool relacionadas(int idA, int idB) {
    if (idA == idB) return true;

    final caminhoA = caminhoDoId(idA);
    final caminhoB = caminhoDoId(idB);
    if (caminhoA == null || caminhoB == null) return false;

    final menor = caminhoA.length <= caminhoB.length ? caminhoA : caminhoB;
    final maior = caminhoA.length <= caminhoB.length ? caminhoB : caminhoA;

    for (var i = 0; i < menor.length; i++) {
      if (menor[i] != maior[i]) return false;
    }
    return true;
  }

  List<SecaoDocumento>? _listaContendo(int localId) {
    final secao = _registro[localId];
    if (secao == null) return null;
    if (secao.parentLocalId == null) return secoes;
    return _registro[secao.parentLocalId]?.subsecoes;
  }

  void adicionarSecaoIrma(int localId) {
    final lista = _listaContendo(localId);
    final referencia = _registro[localId];
    if (lista == null || referencia == null) return;

    final indice = lista.indexWhere((s) => s.localId == localId);
    lista.insert(indice + 1, SecaoDocumento(nivel: referencia.nivel));
    reanotar();
  }

  void adicionarSubsecao(int localId) {
    final pai = _registro[localId];
    if (pai == null) return;

    pai.subsecoes.add(SecaoDocumento(nivel: pai.nivel >= 3 ? 3 : pai.nivel + 1));
    reanotar();
  }

  void removerSecao(int localId) {
    final lista = _listaContendo(localId);
    if (lista == null) return;

    lista.removeWhere((s) => s.localId == localId);
    reanotar();
  }
}
