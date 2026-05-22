import 'package:flutter/material.dart';
import 'package:fabrica_software_app/providers/equipes_provider.dart';
import 'package:fabrica_software_app/models/contribuidor.dart';

class ModalAdicionarPessoa extends StatefulWidget {
  final EquipesProvider provider;
  final Contribuidor? contribuidorParaEditar; // Se vier preenchido, é EDIÇÃO

  const ModalAdicionarPessoa({
    super.key, 
    required this.provider, 
    this.contribuidorParaEditar
  });

  @override
  State<ModalAdicionarPessoa> createState() => _ModalAdicionarPessoaState();
}

class _ModalAdicionarPessoaState extends State<ModalAdicionarPessoa> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cargoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Se for edição, preenche os campos com os dados existentes
    if (widget.contribuidorParaEditar != null) {
      _nomeController.text = widget.contribuidorParaEditar!.nome;
      _emailController.text = widget.contribuidorParaEditar!.email;
      _cargoController.text = widget.contribuidorParaEditar!.cargo ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contribuidorParaEditar != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? "Editar Pessoa" : "Nova Pessoa",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 24),
              
              // Campo Nome
              TextFormField(
                controller: _nomeController,
                decoration: _inputDecoration("Nome Completo", Icons.person),
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 16),

              // Campo Email
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration("E-mail", Icons.email),
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 16),

              // Campo Cargo
              TextFormField(
                controller: _cargoController,
                decoration: _inputDecoration("Cargo / Função", Icons.work),
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 32),

              // Botões de Ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          if (isEditing) {
                            // --- LÓGICA DE ATUALIZAR (CORRIGIDA) ---
                            await widget.provider.atualizarContribuidor(
                              widget.contribuidorParaEditar!.id!, // ID original
                              _nomeController.text,
                              _emailController.text,
                              _cargoController.text,
                            );
                          } else {
                            // --- LÓGICA DE CRIAR ---
                            await widget.provider.criarContribuidor(
                              _nomeController.text,
                              _emailController.text,
                              _cargoController.text,
                            );
                          }
                          
                          // Fecha o modal se tudo der certo
                          if (context.mounted) Navigator.pop(context);
                          
                        } catch (e) {
                          // Se der erro, mostra um aviso (opcional)
                          print("Erro ao salvar: $e");
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isEditing ? "Salvar" : "Adicionar"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}