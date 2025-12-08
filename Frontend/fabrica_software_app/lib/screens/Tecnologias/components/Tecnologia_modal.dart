import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fabrica_software_app/models/tecnologia.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/providers/tecnologias_provider.dart';

enum TecnologiaModalMode {
  view,
  edit,
  delete,
  create,
}

class TecnologiaModal extends StatefulWidget {
  final TecnologiaModalMode mode;
  final Tecnologia? tecnologia;

  const TecnologiaModal({
    super.key,
    required this.mode,
    this.tecnologia,
  });

  @override
  State<TecnologiaModal> createState() => _TecnologiaModalState();
}

class _TecnologiaModalState extends State<TecnologiaModal> {
  late TextEditingController _nomeController;
  late TextEditingController _categoriaController;
  late TextEditingController _descricaoController;
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final BoxDecoration _inputBoxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 5,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ],
    border: Border.all(color: const Color.fromARGB(255, 216, 211, 211)),
  );

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.tecnologia?.nome ?? '');
    _categoriaController = TextEditingController(text: widget.tecnologia?.categoria ?? '');
    _descricaoController = TextEditingController(text: widget.tecnologia?.descricao ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Processando...')],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const Divider(height: 30, thickness: 0.5, color: Colors.grey),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildBody(context),
                ),
              ),
              const SizedBox(height: 24),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    String title;
    IconData icon;
    Color iconColor;
    Color bgColorIcon;

    switch (widget.mode) {
      case TecnologiaModalMode.view:
        title = 'Detalhes da Tecnologia';
        icon = FontAwesomeIcons.solidEye;
        iconColor = const Color(0xFF2962FF);
        bgColorIcon = const Color(0xFFE3F2FD);
        break;
      case TecnologiaModalMode.edit:
        title = 'Editar Tecnologia';
        icon = FontAwesomeIcons.solidPenToSquare;
        iconColor = Colors.orange;
        bgColorIcon = Colors.orange.shade50;
        break;
      case TecnologiaModalMode.delete:
        title = 'Excluir Tecnologia';
        icon = FontAwesomeIcons.trash;
        iconColor = Colors.red;
        bgColorIcon = Colors.red.shade50;
        break;
      case TecnologiaModalMode.create:
        title = 'Criar Tecnologia';
        icon = FontAwesomeIcons.plus;
        iconColor = Colors.green;
        bgColorIcon = Colors.green.shade50;
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bgColorIcon, shape: BoxShape.circle),
          child: FaIcon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.mode == TecnologiaModalMode.delete) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            children: [
              const TextSpan(text: 'Você tem certeza que deseja excluir a tecnologia \n'),
              TextSpan(
                text: widget.tecnologia!.nome,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const TextSpan(text: '\n\nEsta ação não pode ser desfeita.'),
            ],
          ),
        ),
      );
    }

    final isView = widget.mode == TecnologiaModalMode.view;

    Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabelAndField("Nome *", controller: _nomeController, textValue: isView ? widget.tecnologia?.nome : null),
        _buildLabelAndField("Categoria", controller: _categoriaController, textValue: isView ? widget.tecnologia?.categoria : null, isRequired: false),
        _buildLabelAndField("Descrição", controller: _descricaoController, textValue: isView ? widget.tecnologia?.descricao : null, isRequired: false, maxLines: 3),
      ],
    );

    if (isView) return formContent;
    return Form(key: _formKey, child: formContent);
  }

  Widget _buildLabelAndField(String label, {String? textValue, TextEditingController? controller, bool isRequired = true, int maxLines = 1}) {
    bool isReadOnly = widget.mode == TecnologiaModalMode.view;
    final textController = controller ?? TextEditingController(text: textValue ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: _inputBoxDecoration,
            child: TextFormField(
              controller: textController,
              readOnly: isReadOnly,
              enabled: !isReadOnly,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
              validator: (value) {
                if (!isReadOnly && isRequired && (value == null || value.isEmpty)) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (widget.mode == TecnologiaModalMode.view) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Fechar'),
          ),
        ],
      );
    }

    String actionText;
    Color actionColor;
    Future<void> Function()? actionCallback;

    switch (widget.mode) {
      case TecnologiaModalMode.edit:
        actionText = 'Salvar Alterações';
        actionColor = Theme.of(context).primaryColor;
        actionCallback = () async {
          if (_formKey.currentState?.validate() ?? false) {
            setState(() => _isLoading = true);
            final data = {
              'nome': _nomeController.text,
              'categoria': _categoriaController.text.isEmpty ? null : _categoriaController.text,
              'descricao': _descricaoController.text.isEmpty ? null : _descricaoController.text,
            };
            await context.read<TecnologiasProvider>().atualizarTecnologia(widget.tecnologia!.id!, data);
            Navigator.pop(context);
          }
        };
        break;
      case TecnologiaModalMode.delete:
        actionText = 'Excluir';
        actionColor = Colors.red;
        actionCallback = () async {
          setState(() => _isLoading = true);
          await context.read<TecnologiasProvider>().excluirTecnologia(widget.tecnologia!.id!);
          Navigator.pop(context);
        };
        break;
      case TecnologiaModalMode.create:
        actionText = 'Criar Tecnologia';
        actionColor = Colors.green;
        actionCallback = () async {
          if (_formKey.currentState?.validate() ?? false) {
            setState(() => _isLoading = true);
            final data = {
              'nome': _nomeController.text,
              'categoria': _categoriaController.text.isEmpty ? null : _categoriaController.text,
              'descricao': _descricaoController.text.isEmpty ? null : _descricaoController.text,
            };
            await context.read<TecnologiasProvider>().criarTecnologia(data);
            Navigator.pop(context);
          }
        };
        break;
      default:
        actionText = '';
        actionColor = Colors.transparent;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: actionCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(actionText),
        ),
      ],
    );
  }
}