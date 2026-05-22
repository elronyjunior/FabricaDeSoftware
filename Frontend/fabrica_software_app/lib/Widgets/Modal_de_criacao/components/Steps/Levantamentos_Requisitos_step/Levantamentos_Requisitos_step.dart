import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Modal_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Configuracao_Inicial_Projeto_step/components.dart';
import 'package:fabrica_software_app/providers/modal_criacao_projeto_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/config/projeto_dto.dart';
import 'package:fabrica_software_app/services/api_service.dart';

// --- MODELO LOCAL DE DADOS ---
class RequisitoItem {
  String id;
  String titulo;
  String descricao;
  String tipo;        // 'Funcional' ou 'Não Funcional'
  String prioridade;  // 'Alta', 'Média', 'Baixa'
  bool isAiGenerated;
  bool isEdited;
  bool isApproved;

  RequisitoItem({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.prioridade,
    this.isAiGenerated = false,
    this.isEdited = false,
    this.isApproved = true, // Manuais nascem aprovados, IA requer aprovação
  });
}

class LevantamentosRequisitosStep extends ModalStep {
  @override
  String get title => 'Requisitos & Stack Tecnológico';

  @override
  String get tabName => 'Requisitos';

  @override
  IconData get icon => FontAwesomeIcons.listCheck;

  @override
  List<Color> get cores => <Color>[Colors.blueAccent, Colors.purpleAccent];

  final GlobalKey<_LevantamentoRequisitosContentState> _contentKey = GlobalKey();

  @override
  Widget buildBody(BuildContext context) {
    return _LevantamentoRequisitosContent(key: _contentKey);
  }

  @override
  Widget buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão Cancelar
          TextButton.icon(
            onPressed: () {
              // Regra: Sair perde tudo
              projetoDraft.clear();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close, size: 16, color: Colors.black87),
            label: const Text('Cancelar', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.normal)),
          ),
          
          Row(
            children: [
              // Botão Voltar
              OutlinedButton(
                onPressed: () {
                  // Regra: Regressar perde o progresso desta etapa
                  if (_contentKey.currentState != null) {
                    _contentKey.currentState!.limparDadosDestaEtapa();
                  }
                  context.read<ModalCriacaoProjetoProvider>().previousIndex();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Voltar', style: TextStyle(color: Colors.black87)),
              ),
              
              const SizedBox(width: 12),
              
              // Botão Próxima Etapa
              ElevatedButton(
                onPressed: () {
                  if (_contentKey.currentState != null) {
                    // Validação: Só avança se tiver requisitos
                    if (_contentKey.currentState!.validar()) {
                       _contentKey.currentState!.salvarNoDTO();
                       context.read<ModalCriacaoProjetoProvider>().nextIndex();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Row(
                  children: const [
                    Text('Próxima etapa'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 12),
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

class _LevantamentoRequisitosContent extends StatefulWidget {
  const _LevantamentoRequisitosContent({super.key});

  @override
  State<_LevantamentoRequisitosContent> createState() => _LevantamentoRequisitosContentState();
}

class _LevantamentoRequisitosContentState extends State<_LevantamentoRequisitosContent> {
  // Controladores
  final TextEditingController _escopoController = TextEditingController();
  final TextEditingController _novoTituloController = TextEditingController();
  final TextEditingController _novaDescricaoController = TextEditingController();
  
  String _tipoSelecionado = 'Funcional';
  String _prioridadeSelecionada = 'Média';
  bool _isLoadingAI = false;

  // Lista de requisitos local
  final List<RequisitoItem> requisitos = [];

  // --- MÉTODOS DE CONTROLE ---

  void limparDadosDestaEtapa() {
    setState(() {
      requisitos.clear();
      projetoDraft.requisitos = [];
      _escopoController.clear();
      _novoTituloController.clear();
      _novaDescricaoController.clear();
    });
  }

  void salvarNoDTO() {
    projetoDraft.escopo = _escopoController.text;
    
    projetoDraft.requisitos = requisitos.map((r) => {
      'titulo': r.titulo,
      'descricao': r.descricao,
      'tipo': r.tipo,
      'prioridade': r.prioridade,
      'is_ai_generated': r.isAiGenerated,
      'is_approved': r.isApproved,
      'is_edited': r.isEdited
    }).toList();
  }

  bool validar() {
    if (requisitos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("É necessário adicionar pelo menos um requisito para continuar."),
          backgroundColor: Colors.red,
        )
      );
      return false;
    }
    return true;
  }

  void _adicionarRequisitoManual() {
    if (_novoTituloController.text.trim().isEmpty || _novaDescricaoController.text.trim().isEmpty) return;

    setState(() {
      requisitos.add(RequisitoItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        titulo: _novoTituloController.text,
        descricao: _novaDescricaoController.text,
        tipo: _tipoSelecionado,
        prioridade: _prioridadeSelecionada,
        isAiGenerated: false,
        isApproved: true, // Manuais já nascem aprovados
      ));
      
      _novoTituloController.clear();
      _novaDescricaoController.clear();
    });
  }

  // --- INTEGRAÇÃO COM IA NO BACKEND ---
  Future<void> _gerarRequisitosIA() async {
    if (_escopoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, descreva o escopo do projeto antes de chamar a IA."))
      );
      return;
    }

    setState(() => _isLoadingAI = true);

    try {
      String nomeProjeto = projetoDraft.nome ?? "Novo Projeto";
      
      // Chama o ApiService que conecta no seu Node.js
      List<dynamic> resultados = await ApiService.gerarRequisitosBackend(
        _escopoController.text, 
        nomeProjeto
      );

      setState(() {
        for (var item in resultados) {
          requisitos.add(RequisitoItem(
            id: DateTime.now().microsecondsSinceEpoch.toString() + item['titulo'].hashCode.toString(),
            titulo: item['titulo'] ?? 'Requisito Sugerido',
            descricao: item['descricao'] ?? '',
            tipo: item['tipo'] ?? 'Funcional',
            prioridade: item['prioridade'] ?? 'Média',
            isAiGenerated: true,
            isApproved: false, // Requer aprovação
          ));
        }
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao conectar com a IA: $e"), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isLoadingAI = false);
    }
  }

  // --- LÓGICA DE EDIÇÃO ---
  void _editarRequisito(int index) {
    RequisitoItem itemAtual = requisitos[index];
    
    TextEditingController editTituloCtrl = TextEditingController(text: itemAtual.titulo);
    TextEditingController editDescCtrl = TextEditingController(text: itemAtual.descricao);
    String editTipo = itemAtual.tipo;
    String editPrioridade = itemAtual.prioridade;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text("Editar Requisito", style: TextStyle(fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ComponentsConfiguracaoInicalProjeto.buildLabel("Título"),
                    Container(
                      decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                      child: TextField(
                        controller: editTituloCtrl,
                        decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Título"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ComponentsConfiguracaoInicalProjeto.buildLabel("Descrição"),
                    Container(
                      decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                      child: TextField(
                        controller: editDescCtrl,
                        maxLines: 3,
                        decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Descrição"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ComponentsConfiguracaoInicalProjeto.buildLabel("Tipo"),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: editTipo,
                                    isExpanded: true,
                                    items: ['Funcional', 'Não Funcional'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                                    onChanged: (v) => setDialogState(() => editTipo = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ComponentsConfiguracaoInicalProjeto.buildLabel("Prioridade"),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: editPrioridade,
                                    isExpanded: true,
                                    items: ['Alta', 'Média', 'Baixa'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                                    onChanged: (v) => setDialogState(() => editPrioridade = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      requisitos[index].titulo = editTituloCtrl.text;
                      requisitos[index].descricao = editDescCtrl.text;
                      requisitos[index].tipo = editTipo;
                      requisitos[index].prioridade = editPrioridade;
                      requisitos[index].isEdited = true; 
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF)),
                  child: const Text("Salvar Alterações", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _removerRequisito(int index) {
    setState(() {
      requisitos.removeAt(index);
    });
  }

  void _toggleAprovacao(int index) {
    setState(() {
      requisitos[index].isApproved = !requisitos[index].isApproved;
    });
  }

  @override
  Widget build(BuildContext context) {
    int countFuncional = requisitos.where((r) => r.tipo == 'Funcional').length;
    int countNaoFuncional = requisitos.where((r) => r.tipo == 'Não Funcional').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // --- SEÇÃO ESCOPO ---
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              Icon(Icons.description_outlined, color: Color(0xFF2962FF), size: 20),
              SizedBox(width: 10),
              Text("Escopo do Projeto", style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        ComponentsConfiguracaoInicalProjeto.buildLabel("Descreva o escopo para a IA", isRequired: true),
        Container(
          decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
          child: TextField(
            controller: _escopoController,
            maxLines: 3,
            decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration(
              "Ex: Desenvolver um CRM para gestão de vendas com integração ao WhatsApp...",
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Botão Gerar com Loading
        Container(
          width: double.infinity,
          height: 45,
          decoration: BoxDecoration(
            gradient: _isLoadingAI 
                ? const LinearGradient(colors: [Colors.grey, Colors.blueGrey])
                : const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (!_isLoadingAI)
                BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoadingAI ? null : _gerarRequisitosIA,
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: _isLoadingAI 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text("Gerando requisitos...", style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(FontAwesomeIcons.wandMagicSparkles, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text("Gerar Requisitos com IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // --- CONTADORES ---
        Row(
          children: [
            const Icon(Icons.assignment_outlined, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            const Text("Requisitos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            _buildBadgeCounter("Funcionais", countFuncional, Colors.blue),
            const SizedBox(width: 8),
            _buildBadgeCounter("Não Funcionais", countNaoFuncional, Colors.purple),
          ],
        ),
        const SizedBox(height: 16),

        // --- BOX CADASTRO MANUAL ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Adicionar Requisito Manualmente", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 12),
              
              Container(
                decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                child: TextField(
                  controller: _novoTituloController,
                  decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Título (ex: Login Social)"),
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                child: TextField(
                  controller: _novaDescricaoController,
                  decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Descrição detalhada..."),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildDropdownButton(['Funcional', 'Não Funcional'], _tipoSelecionado, (val) {
                      setState(() => _tipoSelecionado = val!);
                    }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _buildDropdownButton(['Alta', 'Média', 'Baixa'], _prioridadeSelecionada, (val) {
                      setState(() => _prioridadeSelecionada = val!);
                    }),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _adicionarRequisitoManual,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- LISTA DE CARDS ---
        if (requisitos.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.list_alt, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    "Nenhum requisito listado.\nUse a IA ou adicione manualmente.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          ...requisitos.asMap().entries.map((entry) {
            int idx = entry.key;
            RequisitoItem req = entry.value;
            return _buildRequisitoCard(req, idx);
          }),
        
        const SizedBox(height: 40),
      ],
    );
  }

  // --- HELPERS VISUAIS (RESTAURADOS) ---

  Widget _buildDropdownButton(List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBadgeCounter(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text("$count $label", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildRequisitoCard(RequisitoItem req, int index) {
    Color typeColor = req.tipo == 'Funcional' ? Colors.blue : Colors.purple;
    Color priorityColor;
    switch (req.prioridade) {
      case 'Alta': priorityColor = Colors.red; break;
      case 'Média': priorityColor = Colors.orange; break;
      default: priorityColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration.copyWith(
        border: req.isApproved 
          ? Border.all(color: Colors.green.withOpacity(0.5), width: 1.5)
          : Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSmallTag(req.tipo, typeColor),
                const SizedBox(width: 8),
                _buildSmallTag(req.prioridade, priorityColor),
                const Spacer(),
                
                if (req.isEdited)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildSmallTag("Editado", Colors.orange),
                  ),

                if (req.isAiGenerated)
                  _buildSourceTag(FontAwesomeIcons.wandMagicSparkles, "IA", Colors.purple)
                else
                  _buildSourceTag(Icons.person, "Manual", Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              req.titulo,
              style: const TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              req.descricao,
              style: TextStyle(
                fontSize: 13, 
                color: Colors.grey[800],
                height: 1.4
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _toggleAprovacao(index),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: req.isApproved ? Colors.green : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: req.isApproved ? Colors.green : Colors.grey.shade300)
                    ),
                    child: Row(
                      children: [
                        Icon(
                          req.isApproved ? Icons.check_circle : Icons.circle_outlined, 
                          size: 16, 
                          color: req.isApproved ? Colors.white : Colors.grey
                        ),
                        const SizedBox(width: 6),
                        Text(
                          req.isApproved ? "Aprovado" : "Aprovar",
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: req.isApproved ? Colors.white : Colors.grey[600]
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                      onPressed: () => _editarRequisito(index),
                      tooltip: "Editar",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      onPressed: () => _removerRequisito(index),
                      tooltip: "Remover",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSourceTag(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}