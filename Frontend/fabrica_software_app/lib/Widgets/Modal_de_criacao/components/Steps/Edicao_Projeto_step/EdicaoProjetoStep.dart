import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// Imports
import 'package:fabrica_software_app/config/projeto_dto.dart';
import 'package:fabrica_software_app/services/projetos_service.dart';
import 'package:fabrica_software_app/providers/projetos_provider.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Modal_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Configuracao_Inicial_Projeto_step/Configuracao_Inicial_Projeto_step.dart';

class EdicaoProjetoStep extends ModalStep {
  final _basicInfoStep = ConfiguracaoInicialProjetoStep();

  @override
  String get title => 'Editar Informações Básicas';
  @override
  String get tabName => 'Editar';
  @override
  IconData get icon => FontAwesomeIcons.penToSquare;
  @override
  List<Color> get cores => [Colors.blue.shade700, Colors.blue.shade500];

  @override
  Widget buildBody(BuildContext context) => _basicInfoStep.buildBody(context);

  @override
  Widget buildFooter(BuildContext context) => _EdicaoFooter();
}

class _EdicaoFooter extends StatefulWidget {
  @override
  State<_EdicaoFooter> createState() => _EdicaoFooterState();
}

class _EdicaoFooterState extends State<_EdicaoFooter> {
  bool _isSaving = false;

  Future<void> _salvarAlteracoes() async {
    setState(() => _isSaving = true);

    try {
      // DTO já está atualizado pelo formulário.
      // Montamos o pacote completo para não apagar dados no banco.
      final dados = {
        'nome_projeto': projetoDraft.nome,
        'descricao': projetoDraft.descricao,
        'tipo': projetoDraft.tipo,
        'modelo_projeto': projetoDraft.modelo,
        'metodologia': projetoDraft.metodologia,
        'escopo': projetoDraft.escopo, // Mantém o que veio do loadFromModel
        'complexidade': projetoDraft.complexidade, // Mantém
        'orcamento_estimado': projetoDraft.orcamentoEstimado, // Mantém
        
        // Datas importantes (envia null se não tiver data, mas se tiver, envia formatado)
        'data_inicio': projetoDraft.dataInicio?.toIso8601String(),
        'data_final_previsto': projetoDraft.dataFinalPrevista?.toIso8601String(),
        
        // ID do cliente (obrigatório)
        'cliente_id': projetoDraft.cliente != null ? projetoDraft.cliente!['id'] : null,
      };

      if (projetoDraft.id != null) {
        await ProjetosService.instance.atualizarProjeto(projetoDraft.id!, dados);
      }

      if (mounted) {
        context.read<ProjetosProvider>().carregarProjetos(); // Atualiza a lista na tela
        Navigator.pop(context); // Fecha o modal
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projeto atualizado!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao editar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _salvarAlteracoes,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isSaving 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check, size: 18),
            label: Text(_isSaving ? 'Salvando...' : 'Salvar Alterações'),
          ),
        ],
      ),
    );
  }
}