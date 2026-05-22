import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Modal_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Configuracao_Inicial_Projeto_step/components.dart';
import 'package:fabrica_software_app/providers/modal_criacao_projeto_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/config/projeto_dto.dart';
import 'package:fabrica_software_app/services/api_service.dart';
import 'package:fabrica_software_app/providers/auth_provider.dart'; // Import necessário

class PlanejamentoOrcamentoStep extends ModalStep {
  @override
  String get title => 'Planejamento & Orçamento';

  @override
  String get tabName => 'Finalização';

  @override
  IconData get icon => FontAwesomeIcons.calendarCheck;

  @override
  List<Color> get cores => <Color>[Colors.orangeAccent, Colors.deepOrange];

  final GlobalKey<_PlanejamentoContentState> _contentKey = GlobalKey();

  @override
  Widget buildBody(BuildContext context) {
    return _PlanejamentoContent(key: _contentKey);
  }

  @override
  Widget buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              projetoDraft.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  if (_contentKey.currentState != null) {
                    _contentKey.currentState!.limparEtapa();
                  }
                  context.read<ModalCriacaoProjetoProvider>().previousIndex();
                },
                child: const Text('Voltar', style: TextStyle(color: Colors.black87)),
              ),
              
              const SizedBox(width: 12),
              
              ElevatedButton(
                onPressed: () async {
                   if (_contentKey.currentState != null) {
                     await _contentKey.currentState!.finalizarProjeto();
                   }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Row(
                  children: const [
                    Text('CRIAR PROJETO', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.check, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanejamentoContent extends StatefulWidget {
  const _PlanejamentoContent({super.key});

  @override
  State<_PlanejamentoContent> createState() => _PlanejamentoContentState();
}

class _PlanejamentoContentState extends State<_PlanejamentoContent> {
  final _dataInicioCtrl = TextEditingController();
  final _dataFimCtrl = TextEditingController();
  final _orcamentoCtrl = TextEditingController();
  
  DateTime? _dataInicio;
  DateTime? _dataFim;
  
  bool _isCalculatingIA = false;
  bool _isSending = false;

  void limparEtapa() {
    _dataInicioCtrl.clear();
    _dataFimCtrl.clear();
    _orcamentoCtrl.clear();
    projetoDraft.dataInicio = null;
    projetoDraft.dataFinalPrevista = null;
    projetoDraft.orcamentoEstimado = null;
    projetoDraft.complexidade = null;
  }

  Future<void> _selectDate(TextEditingController ctrl, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2962FF)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!isStart && _dataInicio != null && picked.isBefore(_dataInicio!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data final inválida."), backgroundColor: Colors.red));
        return;
      }
      if (isStart && _dataFim != null && picked.isAfter(_dataFim!)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data inicial inválida."), backgroundColor: Colors.red));
        return;
      }

      setState(() {
        ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
        if (isStart) _dataInicio = picked;
        else _dataFim = picked;
      });
    }
  }

  Future<void> _estimarOrcamentoIA() async {
    if (_dataInicio == null || _dataFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Defina as datas.")));
      return;
    }

    setState(() => _isCalculatingIA = true);

    try {
      final dias = _dataFim!.difference(_dataInicio!).inDays;
      final dadosParaIA = {
        "nome": projetoDraft.nome,
        "descricao": projetoDraft.descricao,
        "escopo": projetoDraft.escopo ?? "",
        "duracao_dias": dias,
        "equipe": projetoDraft.equipe,
        "recursos": projetoDraft.recursos
      };

      final resultado = await ApiService.estimarOrcamentoBackend(dadosParaIA);
      
      setState(() {
        double valor = (resultado['orcamento_estimado'] as num).toDouble();
        String complexidade = resultado['complexidade'] ?? 'media';
        _orcamentoCtrl.text = valor.toStringAsFixed(2);
        projetoDraft.orcamentoEstimado = valor;
        projetoDraft.complexidade = complexidade;
      });

    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro IA: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isCalculatingIA = false);
    }
  }

  Future<void> finalizarProjeto() async {
    if (_dataInicioCtrl.text.isEmpty || _dataFimCtrl.text.isEmpty || _orcamentoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha todos os campos.")));
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. PEGA O ID DO USUÁRIO LOGADO (Correção Principal)
      final usuarioLogadoId = context.read<AuthProvider>().userId;

      if (usuarioLogadoId == null) {
        throw Exception("Sessão inválida. Faça login novamente.");
      }

      projetoDraft.dataInicio = _dataInicio;
      projetoDraft.dataFinalPrevista = _dataFim;
      String valorLimpo = _orcamentoCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
      projetoDraft.orcamentoEstimado = double.tryParse(valorLimpo) ?? 0.0;
      if (projetoDraft.complexidade == null) projetoDraft.complexidade = 'media';

      final Map<String, dynamic> payload = {
        "nome_projeto": projetoDraft.nome,
        "descricao": projetoDraft.descricao,
        "modelo_projeto": projetoDraft.modelo,
        
        // --- CORREÇÃO DA CHAVE DO TIPO ---
        "tipo": projetoDraft.tipo, 
        
        "escopo": projetoDraft.escopo,
        "complexidade": projetoDraft.complexidade,
        "cliente_id": projetoDraft.cliente?['id'],
        "metodologia": projetoDraft.metodologia,
        "data_inicio": projetoDraft.dataInicio?.toIso8601String(),
        "data_final_previsto": projetoDraft.dataFinalPrevista?.toIso8601String(),
        "orcamento_estimado": projetoDraft.orcamentoEstimado,
        
        // --- USANDO O ID CORRETO ---
        "criado_por_id": usuarioLogadoId,
        "responsavel_id": projetoDraft.responsavel != null ? projetoDraft.responsavel!['id'] : usuarioLogadoId,
        
        "tecnologias": projetoDraft.tecnologias.map((t) => t['id']).toList(),
        "equipe": projetoDraft.equipe, 
        "recursos": projetoDraft.recursos.map((r) => r['id']).toList(),
        "requisitos": projetoDraft.requisitos.toList()
      };

      await ApiService.criarProjetoCompleto(payload);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Projeto criado!"), backgroundColor: Colors.green));
        projetoDraft.clear();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSending) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: const [Icon(Icons.calendar_month_outlined, color: Colors.orange, size: 20), SizedBox(width: 10), Text("Planejamento & Orçamento", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w500))]),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ComponentsConfiguracaoInicalProjeto.buildLabel("Data de Início", isRequired: true), GestureDetector(onTap: () => _selectDate(_dataInicioCtrl, true), child: AbsorbPointer(child: Container(decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration, child: TextField(controller: _dataInicioCtrl, decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Selecionar", icon: Icons.calendar_today))))),])),
             const SizedBox(width: 16),
             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ComponentsConfiguracaoInicalProjeto.buildLabel("Data Final", isRequired: true), GestureDetector(onTap: () => _selectDate(_dataFimCtrl, false), child: AbsorbPointer(child: Container(decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration, child: TextField(controller: _dataFimCtrl, decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Selecionar", icon: Icons.event))))),])),
          ],
        ),
        const SizedBox(height: 20),
        ComponentsConfiguracaoInicalProjeto.buildLabel("Orçamento Estimado", isRequired: true),
        Row(
          children: [
            Expanded(child: Container(decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration, child: TextField(controller: _orcamentoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("R\$ 0.00")))),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isCalculatingIA ? null : _estimarOrcamentoIA,
              icon: _isCalculatingIA ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(FontAwesomeIcons.wandMagicSparkles, size: 16),
              label: const Text("IA"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            )
          ],
        ),
      ],
    );
  }
}