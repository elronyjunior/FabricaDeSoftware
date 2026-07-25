import 'package:flutter/foundation.dart';
import 'package:fabrica_software_app/models/documento_conteudo.dart';
import 'package:fabrica_software_app/models/revisao_documento.dart';
import 'package:fabrica_software_app/services/documento_service.dart';
import 'package:fabrica_software_app/providers/secao_hover_provider.dart';

// Dono do estado do editor de documento: a árvore em si, modo de edição,
// seleção atual e todas as mutações. Criado localmente na tela do editor
// (não registrado globalmente em main.dart), como o padrão já usado para
// ModalCriacaoProjetoProvider.
class DocumentoEditorProvider extends ChangeNotifier {
  final int documentoId;
  final DocumentoService _service;
  final SecaoHoverProvider hoverProvider;

  DocumentoEditorProvider({
    required this.documentoId,
    required this.hoverProvider,
    DocumentoService? service,
  }) : _service = service ?? DocumentoService();

  DocumentoConteudo? documento;
  bool carregando = true;
  bool isSaving = false;
  bool isDirty = false;
  bool editMode = false;
  bool modoRevisao = false;
  String? erro;
  int? selectedSecaoId;

  // Retrabalho de seções com IA: seleção múltipla (independente da seleção
  // de edição inline) + estado do job em andamento.
  final Set<int> secoesSelecionadasParaRetrabalho = {};
  bool retrabalhandoComIA = false;
  String? estagioRetrabalho;

  // Snapshot do documento no momento em que foi carregado nesta sessão, só
  // para a visão "Ver Alterações". Vive na memória, nunca é enviado ao
  // backend e some quando a tela fecha (não é a rastreabilidade permanente,
  // que fica pra uma etapa futura, combinada à parte).
  SnapshotDocumento? _snapshot;

  List<NoRevisao> get arvoreRevisao {
    final doc = documento;
    final snapshot = _snapshot;
    if (doc == null || snapshot == null) return const [];
    return snapshot.construirArvore(doc);
  }

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();

    try {
      final json = await _service.getConteudoDocumento(documentoId);
      documento = json != null ? DocumentoConteudo.fromJson(json) : null;
      _sincronizarProfundidades();
      if (documento != null) {
        _snapshot = SnapshotDocumento.capturar(documento!);
      }
    } catch (e) {
      erro = 'Não foi possível carregar o documento.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<bool> salvar() async {
    final doc = documento;
    if (doc == null) return false;

    isSaving = true;
    notifyListeners();

    try {
      await _service.salvarConteudoDocumento(documentoId, doc.toJson());
      isDirty = false;
      return true;
    } catch (e) {
      erro = 'Não foi possível salvar as alterações.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void alternarEdicao() {
    if (modoRevisao) return; // edição fica desabilitada enquanto "Ver Alterações" está ativo
    editMode = !editMode;
    if (!editMode) {
      selectedSecaoId = null;
      hoverProvider.limpar();
    }
    notifyListeners();
  }

  void alternarModoRevisao() {
    modoRevisao = !modoRevisao;
    if (modoRevisao) {
      editMode = false;
      selectedSecaoId = null;
      hoverProvider.limpar();
    }
    notifyListeners();
  }

  void selecionar(int? localId) {
    selectedSecaoId = localId;
    notifyListeners();
  }

  void _marcarAlterado() {
    isDirty = true;
    notifyListeners();
  }

  void _sincronizarProfundidades() {
    final doc = documento;
    if (doc != null) {
      hoverProvider.atualizarProfundidades(doc.profundidadePorId);
    }
  }

  void atualizarTitulo(int localId, String texto) {
    final secao = documento?.buscarPorLocalId(localId);
    if (secao == null) return;
    secao.titulo = texto;
    _marcarAlterado();
  }

  void atualizarConteudo(int localId, String texto) {
    final secao = documento?.buscarPorLocalId(localId);
    if (secao == null) return;
    secao.conteudo = texto;
    _marcarAlterado();
  }

  void atualizarNivel(int localId, int nivel) {
    final secao = documento?.buscarPorLocalId(localId);
    if (secao == null) return;
    secao.nivel = nivel.clamp(1, 3).toInt();
    _marcarAlterado();
  }

  void atualizarItem(int localId, int indice, String texto) {
    final secao = documento?.buscarPorLocalId(localId);
    if (secao == null || indice < 0 || indice >= secao.itens.length) return;
    secao.itens[indice] = texto;
    _marcarAlterado();
  }

  void adicionarItem(int localId) {
    final secao = documento?.buscarPorLocalId(localId);
    if (secao == null) return;
    secao.itens.add('');
    _marcarAlterado();
  }

  void removerItem(int localId, int indice) {
    final secao = documento?.buscarPorLocalId(localId);
    if (secao == null || indice < 0 || indice >= secao.itens.length) return;
    secao.itens.removeAt(indice);
    _marcarAlterado();
  }

  void adicionarSecaoIrma(int localId) {
    documento?.adicionarSecaoIrma(localId);
    _sincronizarProfundidades();
    _marcarAlterado();
  }

  void adicionarSubsecao(int localId) {
    documento?.adicionarSubsecao(localId);
    _sincronizarProfundidades();
    _marcarAlterado();
  }

  void removerSecao(int localId) {
    documento?.removerSecao(localId);
    if (selectedSecaoId == localId) selectedSecaoId = null;
    secoesSelecionadasParaRetrabalho.remove(localId);
    _sincronizarProfundidades();
    _marcarAlterado();
  }

  // Retorna false quando a seleção foi recusada (seção pai/filha de alguma
  // já selecionada — ver o comentário em DocumentoConteudo.relacionadas) pra
  // a UI poder avisar o usuário.
  bool alternarSelecaoParaRetrabalho(int localId) {
    if (retrabalhandoComIA) return false;

    if (secoesSelecionadasParaRetrabalho.remove(localId)) {
      notifyListeners();
      return true;
    }

    final doc = documento;
    if (doc != null && secoesSelecionadasParaRetrabalho.any((id) => doc.relacionadas(id, localId))) {
      return false;
    }

    secoesSelecionadasParaRetrabalho.add(localId);
    notifyListeners();
    return true;
  }

  void limparSelecaoParaRetrabalho() {
    secoesSelecionadasParaRetrabalho.clear();
    notifyListeners();
  }

  // Pede pra IA reescrever as seções selecionadas. O documento inteiro
  // (inclusive edições ainda não salvas) vai como contexto, mas a IA
  // devolve só as seções selecionadas — o custo/tempo escala com o que foi
  // selecionado, não com o tamanho do documento todo. O resultado é
  // aplicado na árvore em memória, preservando o localId de cada seção
  // alvo; salvar continua sendo uma ação explícita separada.
  Future<bool> retrabalharSelecionadasComIA(String instrucao) async {
    final doc = documento;
    if (doc == null || secoesSelecionadasParaRetrabalho.isEmpty) return false;

    final caminhos = secoesSelecionadasParaRetrabalho
        .map((id) => doc.caminhoDoId(id))
        .whereType<List<int>>()
        .toList();

    if (caminhos.isEmpty) return false;

    retrabalhandoComIA = true;
    estagioRetrabalho = null;
    notifyListeners();

    try {
      final resultado = await _service.retrabalharSecoesComIA(
        documento: doc.toJson(),
        caminhos: caminhos,
        instrucao: instrucao,
        onStatusUpdate: (estagio) {
          estagioRetrabalho = estagio;
          notifyListeners();
        },
      );

      final secoesRetornadas = resultado['secoes'] as List<dynamic>? ?? [];
      for (final item in secoesRetornadas) {
        final caminho = (item['caminho'] as List<dynamic>).map((e) => (e as num).toInt()).toList();
        final novaSecaoJson = item['secao'] as Map<String, dynamic>;
        _aplicarRetrabalho(caminho, novaSecaoJson);
      }

      secoesSelecionadasParaRetrabalho.clear();
      return true;
    } catch (e) {
      erro = 'Não foi possível retrabalhar as seções com a IA.';
      return false;
    } finally {
      retrabalhandoComIA = false;
      notifyListeners();
    }
  }

  void _aplicarRetrabalho(List<int> caminho, Map<String, dynamic> novaSecaoJson) {
    final doc = documento;
    if (doc == null) return;

    final existente = doc.buscarPorCaminho(caminho);
    if (existente == null) return;

    final nova = SecaoDocumento.fromJson(novaSecaoJson);
    existente.titulo = nova.titulo;
    existente.nivel = nova.nivel;
    existente.conteudo = nova.conteudo;
    existente.itens = nova.itens;
    existente.subsecoes = nova.subsecoes;

    doc.reanotar();
    _sincronizarProfundidades();
    _marcarAlterado();
  }

  // Adiciona uma nova seção de nível 1 direto na raiz do documento — usada
  // pelo botão "+ Seção" da toolbar (não depende de haver uma seção
  // selecionada, cobre o caso de um documento ainda vazio).
  void adicionarSecaoRaiz() {
    final doc = documento;
    if (doc == null) return;
    doc.secoes.add(SecaoDocumento(nivel: 1));
    doc.reanotar();
    _sincronizarProfundidades();
    _marcarAlterado();
  }
}
