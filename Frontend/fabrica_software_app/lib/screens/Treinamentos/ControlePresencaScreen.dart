import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fabrica_software_app/providers/controle_presenca_provider.dart';

class ControlePresencaScreen extends StatefulWidget {
  final int treinamentoId;
  final String tituloTreinamento;

  const ControlePresencaScreen({super.key, required this.treinamentoId, required this.tituloTreinamento});

  @override
  State<ControlePresencaScreen> createState() => _ControlePresencaScreenState();
}

class _ControlePresencaScreenState extends State<ControlePresencaScreen> {
  // Controladores
  final ScrollController _horizontalController = ScrollController();

  // --- OTIMIZAÇÃO: Cache das Estatísticas ---
  int? _cachedTotalP;
  int? _cachedTotalF;
  double? _cachedTaxa;
  
  void _calcularEstatisticas(List<dynamic> alunos) {
    int totalP = 0, totalF = 0, total = 0;
    for (var a in alunos) {
      (a['presencas'] as Map).forEach((k, v) { 
        if(v=='P') totalP++; 
        if(v=='F') totalF++; 
        if(v=='P'||v=='F') total++; 
      });
    }
    _cachedTotalP = totalP;
    _cachedTotalF = totalF;
    _cachedTaxa = total > 0 ? (totalP / total) * 100 : 0.0;
  }

  String _getIniciais(String nome) {
    if (nome.isEmpty) return "?";
    List<String> partes = nome.trim().split(' ');
    if (partes.isEmpty) return "?";
    String primeira = partes[0].isNotEmpty ? partes[0][0] : "";
    if (partes.length > 1) {
      String segunda = partes[1].isNotEmpty ? partes[1][0] : "";
      return (primeira + segunda).toUpperCase();
    }
    return primeira.toUpperCase();
  }

  // --- AJUSTE DE LARGURAS (CORREÇÃO DE OVERFLOW) ---
  final double widthAluno = 250;
  final double widthStatus = 120;
  final double widthDia = 130; // Aumentado de 100 para 130 para caber os botões sem erro
  final double widthBtnAdd = 60;

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ControlePresencaProvider()..carregarDados(widget.treinamentoId),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Color(0xFF1E293B)),
          title: const Text("Lista de Chamada", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
          actions: [
            Consumer<ControlePresencaProvider>(
              builder: (ctx, provider, _) => provider.temMudancasPendentes
                ? Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: ElevatedButton.icon(
                      onPressed: provider.isSaving ? null : () async {
                        await provider.salvarAlteracoes();
                        setState(() { _calcularEstatisticas(provider.alunos); });
                      },
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text("Salvar"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, elevation: 0),
                    ),
                  )
                : const SizedBox.shrink(),
            )
          ],
        ),
        
        body: Consumer<ControlePresencaProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());
            if (provider.error != null) return Center(child: Text(provider.error!, style: const TextStyle(color: Colors.red)));

            if (_cachedTotalP == null && provider.alunos.isNotEmpty) {
              _calcularEstatisticas(provider.alunos);
            }
            
            // Calcula largura total da tabela
            double totalTableWidth = widthAluno + widthStatus + widthBtnAdd + (provider.headersDias.length * widthDia);
            if (totalTableWidth < MediaQuery.of(context).size.width) {
               totalTableWidth = MediaQuery.of(context).size.width; 
            }

            return Column(
              children: [
                // 1. HEADER DA PÁGINA
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.tituloTreinamento, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ]),
                      Row(children: [
                        ElevatedButton.icon(
                          onPressed: () => _adicionarDia(context, provider), 
                          icon: const Icon(Icons.add, size: 18), 
                          label: const Text("Adiconar Dia"),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showNovoAlunoDialog(context, provider),
                          icon: const Icon(Icons.person_add, size: 18), 
                          label: const Text("Novo Participante"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                        ),
                      ])
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 2. TABELA OTIMIZADA
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              width: totalTableWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // A. CABEÇALHO DA TABELA
                                  Container(
                                    height: 60,
                                    color: const Color(0xFFF8FAFC),
                                    child: Row(
                                      children: [
                                        _buildHeaderCell("Participantes", widthAluno, Alignment.centerLeft),
                                        _buildHeaderCell("Status", widthStatus, Alignment.centerLeft),
                                        ...provider.headersDias.asMap().entries.map((entry) {
                                          return SizedBox(
                                            width: widthDia,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(entry.value.split('(').last.replaceAll(')', ''), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                                InkWell(onTap: () => _confirmarExclusaoDia(context, provider, entry.key), child: Text("Excluir", style: TextStyle(fontSize: 10, color: Colors.red[300]))),
                                              ],
                                            ),
                                          );
                                        }),
                                        SizedBox(
                                          width: widthBtnAdd,
                                          child: IconButton(icon: const Icon(Icons.add_circle, color: const Color(0xFFEA580C)), onPressed: () => _adicionarDia(context, provider)),
                                        )
                                      ],
                                    ),
                                  ),
                                  
                                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                                  // B. LISTA DE ALUNOS (ListView)
                                  Expanded(
                                    child: ListView.separated(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: provider.alunos.length,
                                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      itemBuilder: (ctx, index) {
                                        final aluno = provider.alunos[index];
                                        int p=0, f=0; 
                                        (aluno['presencas'] as Map).forEach((k,v){if(v=='P')p++;if(v=='F')f++;});
                                        double pct = (p+f)>0 ? (p/(p+f))*100 : 0;

                                        return SizedBox(
                                          height: 80,
                                          child: Row(
                                            children: [
                                              // Coluna Aluno
                                              SizedBox(
                                                width: widthAluno,
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 16),
                                                  child: Row(children: [
                                                    CircleAvatar(backgroundColor: const Color(0xFFF43F5E), foregroundColor: Colors.white, child: Text(_getIniciais(aluno['nome']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                                        Text(aluno['nome'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                                        Text(aluno['email'], overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                                      ]),
                                                    ),
                                                    IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey[300]), onPressed: () => provider.removerAluno(widget.treinamentoId, aluno['rowIndex'])),
                                                  ]),
                                                ),
                                              ),
                                              
                                              // Coluna Status
                                              SizedBox(
                                                width: widthStatus,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF59E0B))),
                                                    child: Text("${pct.toInt()}% presença", style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 12)),
                                                  ),
                                                ),
                                              ),

                                              // Colunas Dias
                                              ...provider.headersDias.asMap().entries.map((entry) {
                                                return SizedBox(
                                                  width: widthDia,
                                                  child: Center(
                                                    child: _StatusToggleButtons(
                                                      status: aluno['presencas'][entry.value] ?? "",
                                                      onChanged: (novo) => provider.setPresenca(aluno['rowIndex'], entry.key, novo),
                                                    ),
                                                  ),
                                                );
                                              }),

                                              // Coluna Vazia
                                              SizedBox(width: widthBtnAdd),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. FOOTER
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      _buildStatCard("Taxa de Presença", "${(_cachedTaxa ?? 0).toInt()}%", Colors.black),
                      const SizedBox(width: 20),
                      _buildStatCard("Total de Presenças", (_cachedTotalP ?? 0).toString(), Colors.green),
                      const SizedBox(width: 20),
                      _buildStatCard("Total de Faltas", (_cachedTotalF ?? 0).toString(), Colors.red),
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width, Alignment align) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Align(
          alignment: align,
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
      ]),
    ));
  }

  Future<void> _adicionarDia(BuildContext context, dynamic provider) async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2023), lastDate: DateTime(2030), builder: (context, child) => Theme(data: ThemeData.light().copyWith(primaryColor: Colors.blue), child: child!));
    if (picked != null) provider.adicionarDia(widget.treinamentoId, DateFormat('dd/MM').format(picked));
  }

  Future<void> _showNovoAlunoDialog(BuildContext context, dynamic provider) async {
    final nomeCtrl = TextEditingController(); final emailCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("Novo Aluno"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: "Nome", border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(onPressed: () { Navigator.pop(context); provider.adicionarAluno(widget.treinamentoId, nomeCtrl.text, emailCtrl.text); }, child: const Text("Adicionar"))
      ],
    ));
  }

  void _confirmarExclusaoDia(BuildContext context, dynamic provider, int index) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Remover Dia"),
      content: const Text("Tem certeza?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
        TextButton(onPressed: () { Navigator.pop(ctx); provider.removerDia(widget.treinamentoId, index); }, child: const Text("Excluir", style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}

class _StatusToggleButtons extends StatelessWidget {
  final String status;
  final Function(String) onChanged;
  const _StatusToggleButtons({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    bool isP = status == 'P'; bool isF = status == 'F';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      InkWell(onTap: () => onChanged(isP ? "" : "P"), borderRadius: BorderRadius.circular(20), child: Container(
        // Padding reduzido para evitar overflow (era horizontal: 10)
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), 
        decoration: BoxDecoration(color: isP ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20), border: Border.all(color: isP ? const Color(0xFF16A34A) : Colors.transparent)),
        child: Row(children: [Icon(Icons.check_circle_outline, size: 16, color: isP ? const Color(0xFF16A34A) : Colors.grey[500]), const SizedBox(width: 4), Text("P", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isP ? const Color(0xFF16A34A) : Colors.grey[600]))]),
      )),
      const SizedBox(width: 4),
      InkWell(onTap: () => onChanged(isF ? "" : "F"), borderRadius: BorderRadius.circular(20), child: Container(
        // Padding reduzido para evitar overflow (era horizontal: 10)
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: isF ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20), border: Border.all(color: isF ? const Color(0xFFDC2626) : Colors.transparent)),
        child: Row(children: [Icon(Icons.cancel_outlined, size: 16, color: isF ? const Color(0xFFDC2626) : Colors.grey[500]), const SizedBox(width: 4), Text("F", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isF ? const Color(0xFFDC2626) : Colors.grey[600]))]),
      )),
    ]);
  }
}