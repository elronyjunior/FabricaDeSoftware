import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fabrica_software_app/models/usuario.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/providers/usuarios_provider.dart';

enum UsuarioModalMode {
  view,
  edit,
  delete,
  create,
}

class UsuarioModal extends StatefulWidget {
  final UsuarioModalMode mode;
  final Usuario? usuario;

  const UsuarioModal({
    super.key,
    required this.mode,
    this.usuario,
  });

  @override
  State<UsuarioModal> createState() => _UsuarioModalState();
}

class _UsuarioModalState extends State<UsuarioModal> {
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _nivelController;
  late TextEditingController _telefoneController;
  late TextEditingController _senhaController;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- ESTILOS PADRÃO (Mesmo do ClienteModal) ---
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
    _nomeController = TextEditingController(text: widget.usuario?.nome ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _nivelController = TextEditingController(text: widget.usuario?.nivel ?? 'colaborador');
    _telefoneController = TextEditingController(text: widget.usuario?.telefone ?? '');
    _senhaController = TextEditingController(); // Senha começa vazia
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _nivelController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
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
      case UsuarioModalMode.view:
        title = 'Detalhes do Usuário';
        icon = FontAwesomeIcons.solidEye;
        iconColor = const Color(0xFF2962FF);
        bgColorIcon = const Color(0xFFE3F2FD);
        break;
      case UsuarioModalMode.edit:
        title = 'Editar Usuário';
        icon = FontAwesomeIcons.solidPenToSquare;
        iconColor = Colors.orange;
        bgColorIcon = Colors.orange.shade50;
        break;
      case UsuarioModalMode.delete:
        title = 'Excluir Usuário';
        icon = FontAwesomeIcons.trash;
        iconColor = Colors.red;
        bgColorIcon = Colors.red.shade50;
        break;
      case UsuarioModalMode.create:
        title = 'Novo Usuário';
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
    if (widget.mode == UsuarioModalMode.delete) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            children: [
              const TextSpan(text: 'Você tem certeza que deseja excluir o usuário \n'),
              TextSpan(
                text: widget.usuario!.nome,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const TextSpan(text: '\n\nEsta ação não pode ser desfeita.'),
            ],
          ),
        ),
      );
    }

    final isView = widget.mode == UsuarioModalMode.view;
    final isCreate = widget.mode == UsuarioModalMode.create;

    Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabelAndField("Nome *", controller: _nomeController, textValue: isView ? widget.usuario?.nome : null),
        _buildLabelAndField("E-mail *", controller: _emailController, textValue: isView ? widget.usuario?.email : null),
        _buildLabelAndField("Telefone", controller: _telefoneController, textValue: isView ? widget.usuario?.telefone : null, isRequired: false),
        _buildLabelAndField("Nível (ex: admin, colaborador) *", controller: _nivelController, textValue: isView ? widget.usuario?.nivel : null),
        
        // Campo de Senha (Especial)
        if (!isView)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCreate ? "Senha *" : "Nova Senha (deixe em branco para manter)",
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: _inputBoxDecoration,
                  child: TextFormField(
                    controller: _senhaController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (isCreate && (value == null || value.isEmpty)) {
                        return 'Senha é obrigatória na criação';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (isView) return formContent;
    return Form(key: _formKey, child: formContent);
  }

  Widget _buildLabelAndField(String label, {String? textValue, TextEditingController? controller, bool isRequired = true}) {
    bool isReadOnly = widget.mode == UsuarioModalMode.view;
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
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
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
    if (widget.mode == UsuarioModalMode.view) {
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
    VoidCallback? actionCallback;

    switch (widget.mode) {
      case UsuarioModalMode.edit:
        actionText = 'Salvar Alterações';
        actionColor = Theme.of(context).primaryColor;
        actionCallback = () async {
          if (_formKey.currentState?.validate() ?? false) {
            setState(() => _isLoading = true);
            
            final data = {
              'nome': _nomeController.text,
              'email': _emailController.text,
              'nivel': _nivelController.text,
              'telefone': _telefoneController.text.isEmpty ? null : _telefoneController.text,
            };

            // Lógica do Backend: só manda senha se tiver valor
            if (_senhaController.text.isNotEmpty) {
              data['senha'] = _senhaController.text;
            }

            try {
              await context.read<UsuariosProvider>().atualizarUsuario(widget.usuario!.id!, data);
              if (!mounted) return;
              Navigator.pop(context);
            } catch (e) {
               // Tratar erro se necessário
            } finally {
               if (mounted) setState(() => _isLoading = false);
            }
          }
        };
        break;
      case UsuarioModalMode.delete:
        actionText = 'Excluir';
        actionColor = Colors.red;
        actionCallback = () async {
          setState(() => _isLoading = true);
          await context.read<UsuariosProvider>().excluirUsuario(widget.usuario!.id!);
          if (!mounted) return;
          Navigator.pop(context);
        };
        break;
      case UsuarioModalMode.create:
        actionText = 'Criar Usuário';
        actionColor = Colors.green;
        actionCallback = () async {
          if (_formKey.currentState?.validate() ?? false) {
            setState(() => _isLoading = true);
            final data = {
              'nome': _nomeController.text,
              'email': _emailController.text,
              'senha': _senhaController.text, // Obrigatória aqui
              'nivel': _nivelController.text,
              'telefone': _telefoneController.text.isEmpty ? null : _telefoneController.text,
            };
            try {
              await context.read<UsuariosProvider>().criarUsuario(data);
              if (!mounted) return;
              Navigator.pop(context);
            } catch (e) {
              // Tratar erro
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
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
          onPressed: _isLoading ? null : actionCallback,
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