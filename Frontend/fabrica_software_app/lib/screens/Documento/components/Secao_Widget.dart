import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/models/documento_conteudo.dart';
import 'package:fabrica_software_app/providers/documento_editor_provider.dart';
import 'package:fabrica_software_app/providers/secao_hover_provider.dart';

const _corSelecionada = Color(0xFF8B5CF6);
const _corHover = Colors.amber;

int nivelClampSecao(int nivel) => nivel < 1 ? 1 : (nivel > 3 ? 3 : nivel);

TextStyle estiloTituloSecao(int nivel) {
  switch (nivelClampSecao(nivel)) {
    case 1:
      return const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87);
    case 2:
      return const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF434343));
    default:
      return const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF434343));
  }
}

// Renderização recursiva de uma seção (e de todas as suas subseções aninhadas).
// Fora do modo de edição não monta nenhum MouseRegion (custo zero de
// hover-tracking). No modo de edição, embrulha a si mesma + toda a sua
// subárvore num único MouseRegion — é isso que faz "hover num Título 1"
// contornar toda a sua árvore, e "hover num Título 2 aninhado" contornar só a
// dele: o SecaoHoverProvider resolve, entre todas as seções atualmente sob o
// cursor, qual é a de maior profundidade estrutural, e só ESSA ganha borda.
class SecaoWidget extends StatefulWidget {
  final SecaoDocumento secao;

  SecaoWidget({required this.secao}) : super(key: ValueKey(secao.localId));

  @override
  State<SecaoWidget> createState() => _SecaoWidgetState();
}

class _SecaoWidgetState extends State<SecaoWidget> {
  late TextEditingController _tituloCtrl;
  late TextEditingController _conteudoCtrl;
  List<TextEditingController> _itemCtrls = [];

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.secao.titulo);
    _conteudoCtrl = TextEditingController(text: widget.secao.conteudo);
    _sincronizarControladoresDeItens();
  }

  void _sincronizarControladoresDeItens() {
    final itens = widget.secao.itens;
    if (_itemCtrls.length == itens.length) return;
    for (final controlador in _itemCtrls) {
      controlador.dispose();
    }
    _itemCtrls = itens.map((texto) => TextEditingController(text: texto)).toList();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _conteudoCtrl.dispose();
    for (final controlador in _itemCtrls) {
      controlador.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sincronizarControladoresDeItens();

    final provider = context.watch<DocumentoEditorProvider>();
    final editMode = provider.editMode;
    final isSelected = editMode && provider.selectedSecaoId == widget.secao.localId;

    final conteudo = _buildConteudo(context, provider, isSelected);

    if (!editMode) {
      return conteudo;
    }

    return MouseRegion(
      onEnter: (_) => context.read<SecaoHoverProvider>().setHover(widget.secao.localId, true),
      onExit: (_) => context.read<SecaoHoverProvider>().setHover(widget.secao.localId, false),
      child: Selector<SecaoHoverProvider, bool>(
        selector: (_, hover) => hover.isDeepestHovered(widget.secao.localId),
        builder: (context, isHovered, child) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: (isHovered && !isSelected) ? () => provider.selecionar(widget.secao.localId) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? _corSelecionada : (isHovered ? _corHover : Colors.transparent),
                  width: isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: child,
            ),
          );
        },
        child: conteudo,
      ),
    );
  }

  Widget _buildConteudo(BuildContext context, DocumentoEditorProvider provider, bool isSelected) {
    final secao = widget.secao;

    return Padding(
      padding: EdgeInsets.only(left: (secao.depth * 16).toDouble()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSelected) _buildBarraDeAcoes(context, provider),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.editMode) _buildCheckboxRetrabalho(context, provider),
              Expanded(child: _buildTitulo(provider, isSelected)),
            ],
          ),
          if (secao.conteudo.isNotEmpty || isSelected) ...[
            const SizedBox(height: 4),
            _buildConteudoTexto(provider, isSelected),
          ],
          if (secao.itens.isNotEmpty || isSelected) ...[
            const SizedBox(height: 4),
            isSelected ? _buildItensEdicao(provider) : _buildItensLeitura(),
          ],
          for (final sub in secao.subsecoes) SecaoWidget(secao: sub),
        ],
      ),
    );
  }

  Widget _buildTitulo(DocumentoEditorProvider provider, bool isSelected) {
    final secao = widget.secao;

    if (isSelected) {
      return TextField(
        controller: _tituloCtrl,
        style: estiloTituloSecao(secao.nivel),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Título da seção',
        ),
        onChanged: (texto) => provider.atualizarTitulo(secao.localId, texto),
      );
    }

    final vazio = secao.titulo.trim().isEmpty;
    final estilo = estiloTituloSecao(secao.nivel);
    return Text(
      vazio ? 'Sem título' : secao.titulo,
      style: vazio
          ? estilo.copyWith(color: Colors.grey.shade400, fontStyle: FontStyle.italic)
          : estilo,
    );
  }

  Widget _buildConteudoTexto(DocumentoEditorProvider provider, bool isSelected) {
    final secao = widget.secao;

    if (isSelected) {
      return TextField(
        controller: _conteudoCtrl,
        maxLines: null,
        style: const TextStyle(fontSize: 14, height: 1.4),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Clique para escrever o conteúdo desta seção...',
        ),
        onChanged: (texto) => provider.atualizarConteudo(secao.localId, texto),
      );
    }

    return Text(secao.conteudo, style: const TextStyle(fontSize: 14, height: 1.4));
  }

  Widget _buildItensLeitura() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.secao.itens
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(fontSize: 13)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildItensEdicao(DocumentoEditorProvider provider) {
    final secao = widget.secao;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < secao.itens.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Text('•  ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: TextField(
                    controller: _itemCtrls[i],
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    onChanged: (texto) => provider.atualizarItem(secao.localId, i, texto),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => provider.removerItem(secao.localId, i),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () => provider.adicionarItem(secao.localId),
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Item', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
        ),
      ],
    );
  }

  Widget _buildBarraDeAcoes(BuildContext context, DocumentoEditorProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildSeletorNivel(provider),
          _buildBotaoAcao(
            icon: Icons.subdirectory_arrow_right,
            tooltip: 'Adicionar subseção',
            onTap: () => provider.adicionarSubsecao(widget.secao.localId),
          ),
          _buildBotaoAcao(
            icon: Icons.playlist_add,
            tooltip: 'Adicionar seção irmã',
            onTap: () => provider.adicionarSecaoIrma(widget.secao.localId),
          ),
          _buildBotaoAcao(
            icon: Icons.delete_outline,
            tooltip: 'Remover seção',
            color: Colors.red,
            onTap: () => _confirmarRemocao(context, provider),
          ),
          _buildBotaoAcao(
            icon: Icons.check,
            tooltip: 'Concluir edição desta seção',
            color: Colors.green,
            onTap: () => provider.selecionar(null),
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorNivel(DocumentoEditorProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [1, 2, 3].map((n) {
        final ativo = widget.secao.nivel == n;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: InkWell(
            onTap: () => provider.atualizarNivel(widget.secao.localId, n),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ativo ? _corSelecionada : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'H$n',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: ativo ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBotaoAcao({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.grey,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Future<void> _confirmarRemocao(BuildContext context, DocumentoEditorProvider provider) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Remover seção'),
        content: const Text('Isso remove esta seção e tudo que estiver dentro dela. Tem certeza?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      provider.removerSecao(widget.secao.localId);
    }
  }

  // Checkbox de seleção pra retrabalho com IA — independente da seleção de
  // edição inline (selectedSecaoId): dá pra marcar várias seções mesmo sem
  // estar editando o texto de nenhuma delas.
  Widget _buildCheckboxRetrabalho(BuildContext context, DocumentoEditorProvider provider) {
    final marcada = provider.secoesSelecionadasParaRetrabalho.contains(widget.secao.localId);

    return Padding(
      padding: const EdgeInsets.only(right: 4, top: 2),
      child: SizedBox(
        width: 20,
        height: 20,
        child: Tooltip(
          message: 'Selecionar para retrabalhar com IA',
          child: Checkbox(
            value: marcada,
            onChanged: provider.retrabalhandoComIA
                ? null
                : (_) {
                    final aceita = provider.alternarSelecaoParaRetrabalho(widget.secao.localId);
                    if (!aceita) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Não dá pra selecionar uma seção junto com sua seção pai ou subseção.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}
