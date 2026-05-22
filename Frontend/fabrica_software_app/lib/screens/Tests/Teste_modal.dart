import 'package:fabrica_software_app/models/teste.dart';
import 'package:flutter/material.dart';


class TesteModal extends StatefulWidget {
  final int projetoId;
  final Teste? testeExistente;
  final Function(Teste) onSave;

  const TesteModal({
    Key? key,
    required this.projetoId,
    this.testeExistente,
    required this.onSave,
  }) : super(key: key);

  @override
  State<TesteModal> createState() => _TesteModalState();
}

class _TesteModalState extends State<TesteModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  String _situacao = 'pendente';
  bool _isSaving = false;

  final Map<String, String> _situacaoLabels = {
    'pendente': 'Pendente',
    'em_progresso': 'Em Execução',
    'concluido': 'Concluído',
    'falha': 'Falha / Erro',
  };

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.testeExistente?.nome ?? '');
    _descricaoController = TextEditingController(text: widget.testeExistente?.descricao ?? '');
    if (widget.testeExistente != null) {
      _situacao = widget.testeExistente!.situacao;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true); // Começa o loading

      try {
        final teste = Teste(
          id: widget.testeExistente?.id,
          projetoId: widget.projetoId,
          nome: _nomeController.text,
          descricao: _descricaoController.text,
          situacao: _situacao,
        );

        // Tenta salvar
        await widget.onSave(teste);
        
        // Se deu certo, fecha o modal
        if (mounted) {
          Navigator.pop(context); 
        }
        
      } catch (e) {
        // SE DEU ERRO: Para o loading e mostra mensagem
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView permite rolar se o teclado cobrir o dialog
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0), // Padding interno do Dialog
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.testeExistente == null ? 'Novo Teste' : 'Editar Teste',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Teste',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição / Critérios',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _situacao,
                decoration: const InputDecoration(
                  labelText: 'Situação',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _situacaoLabels.entries.map((e) => 
                  DropdownMenuItem(value: e.key, child: Text(e.value))
                ).toList(),
                onChanged: (v) => setState(() => _situacao = v!),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}