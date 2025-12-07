import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Modal_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Configuracao_Inicial_Projeto_step/components.dart';
import 'package:fabrica_software_app/providers/modal_criacao_projeto_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// --- MODELO ATUALIZADO (Com Título e Descrição) ---
class RequisitoItem {
  String id;
  String titulo;      // NOVO CAMPO: Nome curto do requisito
  String descricao;   // Conteúdo detalhado
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
    this.isApproved = false,
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
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 16, color: Colors.black87),
            label: const Text('Cancelar', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.normal)),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  context.read<ModalCriacaoProjetoProvider>().previousIndex();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Voltar', style: TextStyle(color: Colors.black87)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Criar Projeto'),
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
  
  // Novos controladores para o cadastro manual
  final TextEditingController _novoTituloController = TextEditingController();
  final TextEditingController _novaDescricaoController = TextEditingController();
  
  String _tipoSelecionado = 'Funcional';
  String _prioridadeSelecionada = 'Média';

  final List<RequisitoItem> requisitos = [];

  void _adicionarRequisito() {
    // Validação simples
    if (_novoTituloController.text.trim().isEmpty || _novaDescricaoController.text.trim().isEmpty) return;

    setState(() {
      requisitos.add(RequisitoItem(
        id: DateTime.now().toString(),
        titulo: _novoTituloController.text, // Usa o título
        descricao: _novaDescricaoController.text, // Usa a descrição
        tipo: _tipoSelecionado,
        prioridade: _prioridadeSelecionada,
        isAiGenerated: false,
      ));
      // Limpa os campos
      _novoTituloController.clear();
      _novaDescricaoController.clear();
    });
  }

  void _gerarRequisitosIA() {
    setState(() {
      requisitos.addAll([
        RequisitoItem(
          id: DateTime.now().toString() + "1",
          titulo: "Autenticação Social", // Título gerado pela IA
          descricao: "O sistema deve permitir que o usuário faça login utilizando suas contas do Google e Facebook para facilitar o acesso.",
          tipo: "Funcional",
          prioridade: "Alta",
          isAiGenerated: true,
        ),
        RequisitoItem(
          id: DateTime.now().toString() + "2",
          titulo: "Performance de API", // Título gerado pela IA
          descricao: "O tempo de resposta dos endpoints da API principal não deve exceder 200ms em condições normais de carga.",
          tipo: "Não Funcional",
          prioridade: "Média",
          isAiGenerated: true,
        ),
      ]);
    });
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
        
        // --- SEÇÃO 1: ESCOPO E IA ---
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
        ComponentsConfiguracaoInicalProjeto.buildLabel("Descreva o escopo", isRequired: true),
        Container(
          decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
          child: TextField(
            controller: _escopoController,
            maxLines: 3,
            decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration(
              "Descreva detalhadamente o escopo... A IA usará isso para gerar requisitos.",
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _gerarRequisitosIA,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(FontAwesomeIcons.wandMagicSparkles, color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Text("Gerar Requisitos com IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // --- SEÇÃO 2: LISTA E CADASTRO MANUAL ---
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

        // BOX DE ADICIONAR MANUALMENTE (Agora com Título e Descrição)
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
              const Text("Adicionar Requisito Manual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              
              // Input Título
              Container(
                decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                child: TextField(
                  controller: _novoTituloController,
                  decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Título (ex: Exportação PDF)"),
                ),
              ),
              const SizedBox(height: 8),
              
              // Input Descrição
              Container(
                decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                child: TextField(
                  controller: _novaDescricaoController,
                  decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Descrição detalhada do requisito..."),
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
                    onPressed: _adicionarRequisito,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Adicionar"),
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

        // LISTA DE CARDS
        ...requisitos.asMap().entries.map((entry) {
          int idx = entry.key;
          RequisitoItem req = entry.value;
          return _buildRequisitoCard(req, idx);
        }),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDropdownButton(List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item, style: const TextStyle(fontSize: 13)));
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

  // --- CARD DO REQUISITO ATUALIZADO ---
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
            // LINHA 1: TAGS
            Row(
              children: [
                _buildSmallTag(req.tipo, typeColor),
                const SizedBox(width: 8),
                _buildSmallTag(req.prioridade, priorityColor),
                const Spacer(),
                if (req.isAiGenerated && !req.isEdited)
                  _buildSourceTag(FontAwesomeIcons.wandMagicSparkles, "IA", Colors.purple),
                if (req.isEdited)
                   _buildSourceTag(Icons.edit, "Editado", Colors.orange),
                if (!req.isAiGenerated && !req.isEdited)
                   _buildSourceTag(Icons.person, "Manual", Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            
            // LINHA 2: TÍTULO (Destaque)
            Text(
              req.titulo,
              style: TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                decoration: req.isApproved ? TextDecoration.lineThrough : null,
                decorationColor: Colors.green
              ),
            ),
            const SizedBox(height: 4),

            // LINHA 3: DESCRIÇÃO (Conteúdo)
            Text(
              req.descricao,
              style: TextStyle(
                fontSize: 13, 
                color: Colors.grey[800],
                height: 1.4
              ),
            ),
            const SizedBox(height: 16),
            
            // LINHA 4: AÇÕES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _toggleAprovacao(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
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
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                      onPressed: () {
                        setState(() {
                          // Exemplo de edição: Adiciona (Edit) ao título
                          req.titulo += " (Edit)";
                          req.isEdited = true;
                        });
                      },
                      tooltip: "Editar",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      onPressed: () => _removerRequisito(index),
                      tooltip: "Remover",
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