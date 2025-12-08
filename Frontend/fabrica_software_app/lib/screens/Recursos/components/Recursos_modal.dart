import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fabrica_software_app/models/recurso.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/providers/recursos_provider.dart';

enum RecursoModalMode {
  view,
  edit,
  delete,
  create,
}

class RecursoModal extends StatefulWidget {
  final RecursoModalMode mode;
  final Recurso? recurso;

  const RecursoModal({
    super.key,
    required this.mode,
    this.recurso,
  });

  @override
  State<RecursoModal> createState() => _RecursoModalState();
}

class _RecursoModalState extends State<RecursoModal> {
  late TextEditingController _nomeController;
  late TextEditingController _tipoController;
  late TextEditingController _descricaoController;
  late TextEditingController _criadoPorIdController;
  late bool _disponivel;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- ESTILOS ---
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
    _nomeController = TextEditingController(text: widget.recurso?.nome ?? '');
    _tipoController = TextEditingController(text: widget.recurso?.tipo ?? '');
    _descricaoController = TextEditingController(text: widget.recurso?.descricao ?? '');
    _criadoPorIdController = TextEditingController(text: widget.recurso?.criadoPorId?.toString() ?? '');
    _disponivel = widget.recurso?.disponivel ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _tipoController.dispose();
    _descricaoController.dispose();
    _criadoPorIdController.dispose();
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
      case RecursoModalMode.view:
        title = 'Detalhes do Recurso';
        icon = FontAwesomeIcons.solidEye;
        iconColor = const Color(0xFF2962FF);
        bgColorIcon = const Color(0xFFE3F2FD);
        break;
      case RecursoModalMode.edit:
        title = 'Editar Recurso';
        icon = FontAwesomeIcons.solidPenToSquare;
        iconColor = Colors.orange;
        bgColorIcon = Colors.orange.shade50;
        break;
      case RecursoModalMode.delete:
        title = 'Excluir Recurso';
        icon = FontAwesomeIcons.trash;
        iconColor = Colors.red;
        bgColorIcon = Colors.red.shade50;
        break;
      case RecursoModalMode.create:
        title = 'Criar Novo Recurso';
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
    if (widget.mode == RecursoModalMode.delete) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            children: [
              const TextSpan(text: 'Você tem certeza que deseja excluir o recurso \n'),
              TextSpan(
                text: widget.recurso!.nome,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const TextSpan(text: '\n\nEsta ação não pode ser desfeita.'),
            ],
          ),
        ),
      );
    }

    final isView = widget.mode == RecursoModalMode.view;

    // Conteúdo do formulário
    Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabelAndField("Nome *", controller: _nomeController, textValue: isView ? widget.recurso?.nome : null),
        _buildLabelAndField("Tipo *", controller: _tipoController, textValue: isView ? widget.recurso?.tipo : null),
        _buildLabelAndField("Descrição", controller: _descricaoController, textValue: isView ? widget.recurso?.descricao : null, isRequired: false),
        
        // Campo Disponível (Customizado para parecer com os outros inputs)
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Disponível",
                style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: _inputBoxDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SwitchListTile(
                  title: Text(_disponivel ? "Sim" : "Não", style: const TextStyle(fontSize: 15)),
                  value: _disponivel,
                  activeColor: Colors.green,
                  onChanged: isView ? null : (val) => setState(() => _disponivel = val),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ),

        // Campo ID do Criador (Só mostra em Create ou View, logicamente não se edita o criador)
        if (!isView)
           _buildLabelAndField("ID Criador *", controller: _criadoPorIdController, isNumeric: true),
        
        if (isView) ...[
           _buildLabelAndField("ID Criador", textValue: widget.recurso?.criadoPorId.toString()),
           _buildLabelAndField("Data Criação", textValue: widget.recurso?.dataCriacao.toString()),
        ]
      ],
    );

    if (isView) return formContent;
    return Form(key: _formKey, child: formContent);
  }

  Widget _buildLabelAndField(String label, {String? textValue, TextEditingController? controller, bool isRequired = true, bool isNumeric = false}) {
    bool isReadOnly = widget.mode == RecursoModalMode.view;
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
              keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                errorStyle: TextStyle(height: 0.8),
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
    if (widget.mode == RecursoModalMode.view) {
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
      case RecursoModalMode.edit:
        actionText = 'Salvar Alterações';
        actionColor = Theme.of(context).primaryColor;
        actionCallback = () async {
          if (_formKey.currentState?.validate() ?? false) {
            setState(() => _isLoading = true);
            final data = {
              'nome': _nomeController.text,
              'tipo': _tipoController.text,
              'disponivel': _disponivel,
              'descricao': _descricaoController.text.isEmpty ? null : _descricaoController.text,
            };
            await context.read<RecursosProvider>().atualizarRecurso(widget.recurso!.id!, data);
            Navigator.pop(context);
          }
        };
        break;
      case RecursoModalMode.delete:
        actionText = 'Excluir';
        actionColor = Colors.red;
        actionCallback = () async {
          setState(() => _isLoading = true);
          await context.read<RecursosProvider>().excluirRecurso(widget.recurso!.id!);
          Navigator.pop(context);
        };
        break;
      case RecursoModalMode.create:
        actionText = 'Criar Recurso';
        actionColor = Colors.green;
        actionCallback = () async {
          if (_formKey.currentState?.validate() ?? false) {
            setState(() => _isLoading = true);
            final data = {
              'nome': _nomeController.text,
              'tipo': _tipoController.text,
              'disponivel': _disponivel,
              'descricao': _descricaoController.text.isEmpty ? null : _descricaoController.text,
              'criado_por_id': int.parse(_criadoPorIdController.text),
            };
            await context.read<RecursosProvider>().criarRecurso(data);
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