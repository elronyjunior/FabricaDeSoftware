import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fabrica_software_app/models/documento_conteudo.dart';
import 'package:fabrica_software_app/providers/documento_editor_provider.dart';
import 'package:fabrica_software_app/providers/secao_hover_provider.dart';
import 'package:fabrica_software_app/screens/Documento/components/Secao_Widget.dart';
import 'package:fabrica_software_app/screens/Documento/components/SecaoRevisao_Widget.dart';
import 'package:fabrica_software_app/services/documento_pdf_builder.dart';

const _corPrimaria = Color(0xFF8B5CF6);

class VisualizarDocumentoScreen extends StatefulWidget {
  final int documentoId;
  final String nomeArquivo;
  final String arquivoUrl;

  const VisualizarDocumentoScreen({
    super.key,
    required this.documentoId,
    required this.nomeArquivo,
    required this.arquivoUrl,
  });

  @override
  State<VisualizarDocumentoScreen> createState() => _VisualizarDocumentoScreenState();
}

class _VisualizarDocumentoScreenState extends State<VisualizarDocumentoScreen> {
  late final SecaoHoverProvider _hoverProvider;
  late final DocumentoEditorProvider _editorProvider;

  @override
  void initState() {
    super.initState();
    _hoverProvider = SecaoHoverProvider();
    _editorProvider = DocumentoEditorProvider(documentoId: widget.documentoId, hoverProvider: _hoverProvider);
    _editorProvider.carregar();
  }

  @override
  void dispose() {
    _hoverProvider.dispose();
    _editorProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _hoverProvider),
        ChangeNotifierProvider.value(value: _editorProvider),
      ],
      child: _VisualizarDocumentoBody(nomeArquivo: widget.nomeArquivo, arquivoUrl: widget.arquivoUrl),
    );
  }
}

class _VisualizarDocumentoBody extends StatefulWidget {
  final String nomeArquivo;
  final String arquivoUrl;

  const _VisualizarDocumentoBody({required this.nomeArquivo, required this.arquivoUrl});

  @override
  State<_VisualizarDocumentoBody> createState() => _VisualizarDocumentoBodyState();
}

class _VisualizarDocumentoBodyState extends State<_VisualizarDocumentoBody> {
  static const double _larguraPagina = 820;
  static const double _zoomMinimo = 0.5;
  static const double _zoomMaximo = 1.5;

  double _zoom = 1.0;

  void _diminuirZoom() => setState(() {
        final novo = _zoom - 0.1;
        _zoom = novo < _zoomMinimo ? _zoomMinimo : novo;
      });

  void _aumentarZoom() => setState(() {
        final novo = _zoom + 0.1;
        _zoom = novo > _zoomMaximo ? _zoomMaximo : novo;
      });

  void _resetarZoom() => setState(() => _zoom = 1.0);

  Future<void> _abrirNoGoogleDocs(BuildContext context) async {
    final uri = Uri.parse(widget.arquivoUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Não foi possível abrir';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir o Google Docs'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportarPdf(BuildContext context, DocumentoEditorProvider provider) async {
    final documento = provider.documento;
    if (documento == null) return;

    try {
      final bytes = await construirPdfDocumento(documento);
      await Printing.sharePdf(bytes: bytes, filename: '${widget.nomeArquivo}.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao gerar o PDF'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _confirmarSaidaComAlteracoesPendentes(BuildContext context) async {
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Alterações não salvas'),
        content: const Text('Deseja salvar suas alterações antes de sair?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancelar'), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'descartar'),
            child: const Text('Descartar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'salvar'),
            style: ElevatedButton.styleFrom(backgroundColor: _corPrimaria, foregroundColor: Colors.white),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (resultado == 'salvar') {
      if (!context.mounted) return false;
      return context.read<DocumentoEditorProvider>().salvar();
    }
    return resultado == 'descartar';
  }

  Future<void> _salvar(BuildContext context, DocumentoEditorProvider provider) async {
    final sucesso = await provider.salvar();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sucesso ? 'Documento salvo!' : 'Erro ao salvar documento'),
        backgroundColor: sucesso ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentoEditorProvider>();

    return PopScope(
      canPop: !provider.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final podeSair = await _confirmarSaidaComAlteracoesPendentes(context);
        if (podeSair && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade300,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            widget.nomeArquivo,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _abrirNoGoogleDocs(context),
              icon: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
              label: const Text('Abrir no Google Docs', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _buildToolbar(context, provider),
            Expanded(child: _buildCorpo(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, DocumentoEditorProvider provider) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (provider.documento == null || provider.modoRevisao) ? null : provider.alternarEdicao,
                  icon: Icon(provider.editMode ? Icons.visibility : Icons.edit, size: 16),
                  label: Text(provider.editMode ? 'Sair da Edição' : 'Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.editMode ? Colors.grey.shade200 : _corPrimaria,
                    foregroundColor: provider.editMode ? Colors.black87 : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                if (provider.editMode) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: provider.adicionarSecaoRaiz,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Seção'),
                  ),
                ],
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: provider.documento == null ? null : provider.alternarModoRevisao,
                  icon: Icon(provider.modoRevisao ? Icons.visibility_off_outlined : Icons.difference_outlined, size: 16),
                  label: Text(provider.modoRevisao ? 'Ver Documento' : 'Ver Alterações'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: provider.modoRevisao ? Colors.white : Colors.deepOrange,
                    backgroundColor: provider.modoRevisao ? Colors.deepOrange : null,
                    side: const BorderSide(color: Colors.deepOrange),
                  ),
                ),
                const Spacer(),
                if (provider.editMode) ...[
                  Text(
                    provider.isDirty ? 'Alterações não salvas' : 'Tudo salvo',
                    style: TextStyle(
                      fontSize: 12,
                      color: provider.isDirty ? Colors.orange.shade800 : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: (provider.isDirty && !provider.isSaving) ? () => _salvar(context, provider) : null,
                    icon: provider.isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save, size: 16),
                    label: const Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                OutlinedButton.icon(
                  onPressed: provider.documento == null ? null : () => _exportarPdf(context, provider),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Salvar PDF'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                _buildControleZoom(),
                if (provider.modoRevisao) ...[
                  const Spacer(),
                  _buildLegenda(),
                ],
              ],
            ),
          ),
          if (provider.secoesSelecionadasParaRetrabalho.isNotEmpty) _buildBarraRetrabalhoIA(context, provider),
        ],
      ),
    );
  }

  Widget _buildBarraRetrabalhoIA(BuildContext context, DocumentoEditorProvider provider) {
    final quantidade = provider.secoesSelecionadasParaRetrabalho.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: _corPrimaria.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 16, color: _corPrimaria),
          const SizedBox(width: 8),
          Text(
            provider.retrabalhandoComIA
                ? (provider.estagioRetrabalho == 'gerando_reescrita_com_ia'
                    ? 'Reescrevendo com IA...'
                    : 'Processando...')
                : '$quantidade seção(ões) selecionada(s)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (provider.retrabalhandoComIA)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          else ...[
            TextButton(
              onPressed: provider.limparSelecaoParaRetrabalho,
              child: const Text('Limpar seleção'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _abrirDialogoRetrabalho(context, provider),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Retrabalhar com IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _corPrimaria,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _abrirDialogoRetrabalho(BuildContext context, DocumentoEditorProvider provider) async {
    final controlador = TextEditingController();
    final quantidade = provider.secoesSelecionadasParaRetrabalho.length;

    final instrucao = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Retrabalhar $quantidade seção(ões) com IA'),
        content: TextField(
          controller: controlador,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'O que a IA deve mudar nessa(s) seção(ões)? (opcional)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controlador.text),
            style: ElevatedButton.styleFrom(backgroundColor: _corPrimaria, foregroundColor: Colors.white),
            child: const Text('Enviar para IA'),
          ),
        ],
      ),
    );

    if (instrucao == null || !context.mounted) return;

    final sucesso = await provider.retrabalharSelecionadasComIA(instrucao);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sucesso ? 'Seções reescritas! Revise e clique em Salvar.' : 'Erro ao retrabalhar seções com IA'),
        backgroundColor: sucesso ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildControleZoom() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _zoom > _zoomMinimo ? _diminuirZoom : null,
          icon: const Icon(Icons.remove, size: 16),
          visualDensity: VisualDensity.compact,
          tooltip: 'Diminuir zoom',
        ),
        InkWell(
          onTap: _resetarZoom,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '${(_zoom * 100).round()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          onPressed: _zoom < _zoomMaximo ? _aumentarZoom : null,
          icon: const Icon(Icons.add, size: 16),
          visualDensity: VisualDensity.compact,
          tooltip: 'Aumentar zoom',
        ),
      ],
    );
  }

  Widget _buildLegenda() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendaItem(corFundoAlteracao, 'Adicionado/Alterado'),
        const SizedBox(width: 12),
        _buildLegendaItem(corFundoRemovido, 'Removido'),
      ],
    );
  }

  Widget _buildLegendaItem(Color cor, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildCorpo(BuildContext context, DocumentoEditorProvider provider) {
    if (provider.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.erro != null) {
      return Center(child: Text(provider.erro!, style: TextStyle(color: Colors.red.shade700)));
    }

    final documento = provider.documento;
    if (documento == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Este documento não tem conteúdo editável no app.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Documentos gerados antes desta atualização só podem ser vistos no Google Docs.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _abrirNoGoogleDocs(context),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Abrir no Google Docs'),
              style: ElevatedButton.styleFrom(backgroundColor: _corPrimaria, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return _buildPagina(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(documento.titulo, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if ((documento.sumarioExecutivo ?? '').isNotEmpty) ...[
            Text(
              'Sumário Executivo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(documento.sumarioExecutivo!, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 20),
          ],
          if (provider.modoRevisao)
            for (final no in provider.arvoreRevisao) SecaoRevisaoWidget(no: no)
          else
            for (final secao in documento.secoes) SecaoWidget(secao: secao),
          if (documento.tabelas.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._buildTabelas(documento.tabelas),
          ],
          if ((documento.conclusao ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Conclusão',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(documento.conclusao!, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ],
      ),
    );
  }

  // Embrulha o conteúdo numa "folha" branca de proporção A4, centralizada
  // num fundo cinza (como Word/Google Docs), escalada pelo nível de zoom.
  Widget _buildPagina(Widget conteudo) {
    const alturaMinima = _larguraPagina * 1.414;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: SizedBox(
          width: _larguraPagina * _zoom,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: _larguraPagina,
              child: Container(
                constraints: const BoxConstraints(minHeight: alturaMinima),
                padding: const EdgeInsets.all(72),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 6)),
                  ],
                ),
                child: conteudo,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabelas(List<TabelaDocumento> tabelas) {
    return tabelas.map((tabela) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if ((tabela.titulo ?? '').isNotEmpty)
                  Text(tabela.titulo!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                  child: Text('não editável', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: tabela.cabecalhos
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      )
                      .toList(),
                ),
                for (final linha in tabela.linhas)
                  TableRow(
                    children: linha
                        .map(
                          (celula) => Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(celula, style: const TextStyle(fontSize: 12)),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
