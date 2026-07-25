import 'package:fabrica_software_app/models/projeto.dart';
import 'package:fabrica_software_app/models/enums.dart';
import 'package:fabrica_software_app/screens/Tests/Teste_screen.dart';
import 'package:fabrica_software_app/screens/Treinamentos/ListaTreinamentosScreen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; 
import 'package:fabrica_software_app/screens/Documento/Documentos_Projeto_Screen.dart';
// Import da tela de recursos
import 'package:fabrica_software_app/screens/Recursos/Recursos.dart'; 

class VisualizarProjetoScreen extends StatelessWidget {
  final Projeto projeto;

  const VisualizarProjetoScreen({super.key, required this.projeto});

  // --- Helpers de Ícone e Cor ---
  IconData _getIcon() {
    final tipo = (projeto.tipo ?? projeto.modeloProjeto ?? '').toUpperCase();
    if (tipo.contains('WEB')) return Icons.language;
    if (tipo.contains('MOBILE') || tipo.contains('APP')) return Icons.smartphone;
    if (tipo.contains('API')) return Icons.storage;
    return Icons.folder_open;
  }

  Color _getIconColor() {
    final tipo = (projeto.tipo ?? projeto.modeloProjeto ?? '').toUpperCase();
    if (tipo.contains('WEB')) return Colors.blue;
    if (tipo.contains('MOBILE')) return Colors.purple;
    if (tipo.contains('API')) return Colors.orange;
    return Colors.blue;
  }

  String _formatarOrcamento(double? valor) {
    if (valor == null) return "Não estimado";
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  }

  ({String label, Color bg, Color fg}) _complexidadeInfo() {
    switch (projeto.complexidade) {
      case ComplexidadeProjeto.alta:
        return (label: "Alta", bg: Colors.red.shade100, fg: Colors.red.shade700);
      case ComplexidadeProjeto.media:
        return (label: "Média", bg: Colors.orange.shade100, fg: Colors.orange.shade700);
      case ComplexidadeProjeto.baixa:
        return (label: "Baixa", bg: Colors.green.shade100, fg: Colors.green.shade700);
      default:
        return (label: "Não definida", bg: Colors.grey.shade200, fg: Colors.grey.shade700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final iconColor = _getIconColor();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.pink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Visualizar Projeto", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
                Text(projeto.nomeProjeto, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // ========================================================
                  // 1. SEÇÃO BENTO GRID
                  // ========================================================
                  LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth > 850) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // COLUNA 1: Informações
                            Expanded(
                              flex: 5,
                              child: _BentoCard(
                                title: "Informações Básicas",
                                icon: Icons.description_outlined,
                                color: Colors.blue,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _InfoLabel(label: "Descrição do Projeto", value: projeto.descricao ?? "Sem descrição definida."),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(child: _InfoLabel(label: "Tipo de Projeto", value: projeto.tipo ?? "Geral")),
                                        Builder(builder: (context) {
                                          final complexidade = _complexidadeInfo();
                                          return _StatusTag(label: "Complexidade", value: complexidade.label, color: complexidade.bg, textColor: complexidade.fg);
                                        }),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _InfoLabel(label: "Escopo", value: projeto.escopo ?? "Escopo não definido."),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // COLUNA 2: Pessoas
                            Expanded(
                              flex: 3,
                              child: _BentoCard(
                                title: "Gestão de Pessoas",
                                icon: Icons.people_outline,
                                color: Colors.purple,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _PersonRow(role: "Cliente", name: projeto.clienteNome ?? "Não informado"),
                                    const SizedBox(height: 12),
                                    const _PersonRow(role: "Responsável", name: "João Silva"),
                                    const SizedBox(height: 12),
                                    const _PersonRow(role: "Criado por", name: "Maria Santos"),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // COLUNA 3: Metodologia e Orçamento
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _BentoCard(
                                      title: "Metodologia",
                                      icon: Icons.settings_suggest_outlined,
                                      color: Colors.green,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _InfoLabel(label: "Modelo", value: projeto.modeloProjeto ?? "Ágil"),
                                          const SizedBox(height: 8),
                                          const _InfoLabel(label: "Framework", value: "Scrum"),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.attach_money, color: Colors.green.shade700, size: 20),
                                            const SizedBox(width: 8),
                                            Text("Orçamento", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(_formatarOrcamento(projeto.orcamentoEstimado), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Column(
                        children: [
                          _BentoCard(
                            title: "Informações Básicas", 
                            icon: Icons.description, color: Colors.blue,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoLabel(label: "Descrição", value: projeto.descricao ?? ""),
                                const SizedBox(height: 12),
                                _InfoLabel(label: "Tipo", value: projeto.tipo ?? ""),
                              ],
                            )
                          ),
                          const SizedBox(height: 16),
                          _BentoCard(
                            title: "Gestão de Pessoas", 
                            icon: Icons.people, color: Colors.purple,
                            child: _PersonRow(role: "Cliente", name: projeto.clienteNome ?? "-"),
                          ),
                        ],
                      );
                    }
                  }),

                  const SizedBox(height: 24),

                  // ========================================================
                  // 2. SEÇÃO PLANEJAMENTO
                  // ========================================================
                  _BentoCard(
                    title: "Planejamento",
                    icon: Icons.calendar_today_outlined,
                    color: Colors.orange,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _DateInfo(label: "Data de Início", value: _formatDate(projeto.dataInicio)),
                            _DateInfo(label: "Previsão de Término", value: _formatDate(projeto.dataFinalPrevisto)),
                            
                            if (constraints.maxWidth > 500) ...[
                               const _DateInfo(label: "Data de Término Real", value: "--/--/----"),
                               const _DateInfo(label: "Duração Total", value: "12 meses"),
                            ]
                          ],
                        );
                      }
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ========================================================
                  // 3. SEÇÃO DE CARDS DE GESTÃO
                  // ========================================================
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      return GridView.count(
                        crossAxisCount: isDesktop ? 2 : 1,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: isDesktop ? 2.5 : 1.6,
                        children: [
                          
                          // --- CARD RECURSOS (ATUALIZADO) ---
                          _DashboardInfoCard(
                            title: "Gestão de Recursos",
                            icon: Icons.people,
                            themeColor: const Color(0xFF1E40AF),
                            stats: const [
                              {"label": "Desenvolvedores", "value": "6 membros"},
                              {"label": "QA", "value": "3 membros"},
                              {"label": "Product Owner", "value": "1 membro"},
                            ],
                            buttonText: "Ver Recursos",
                            // NAVEGAÇÃO PASSANDO O PROJETO
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Recursos(projetoVinculado: projeto),
                                ),
                              );
                            },
                          ),
                          // ----------------------------------

                          _DashboardInfoCard(
                            title: "Documentação e Artefatos",
                            icon: Icons.folder,
                            themeColor: const Color(0xFF16A34A),
                            stats: const [
                              {"label": "Documentos", "value": "Acessar"}, 
                              {"label": "Repositório", "value": "Drive"},
                            ],
                            buttonText: "Ver Documentos",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DocumentosProjetoScreen(projeto: projeto),
                                ),
                              );
                            },
                          ),

                          _DashboardInfoCard(
                            title: "Relatórios de Treinamentos",
                            icon: FontAwesomeIcons.graduationCap,
                            themeColor: const Color(0xFFEA580C),
                            stats: const [
                              {"label": "Treinamentos", "value": "Verificar"},
                              {"label": "Participantes", "value": "Gerenciar"},
                              {"label": "Frequência", "value": "Sheets"},
                            ],
                            buttonText: "Ver Treinamentos",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListaTreinamentosScreen(projeto: projeto),
                                ),
                              );
                            },
                          ),

                          _DashboardInfoCard(
                            title: "Relatórios de Testes",
                            icon: Icons.bug_report,
                            themeColor: const Color(0xFF9333EA),
                            stats: const [
                              {"label": "Testes executados", "value": "156"},
                              {"label": "Taxa de sucesso", "value": "94%", "valueColor": Colors.green},
                              {"label": "Bugs encontrados", "value": "8", "valueColor": Colors.red},
                            ],
                            buttonText: "Ver Relatórios",
                             onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TestesScreen(projetoId: projeto.id ?? 0, nomeProjeto: projeto.nomeProjeto)
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "--/--/----";
    try {
      if (date is DateTime) {
        return DateFormat('dd/MM/yyyy').format(date);
      } else if (date is String) {
        final parsed = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy').format(parsed);
      }
      return "--/--/----";
    } catch (e) {
      return "--/--/----";
    }
  }
}

// ============================================================================
// WIDGETS AUXILIARES (IGUAIS AO ANTERIOR)
// ============================================================================

class _BentoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _BentoCard({required this.title, required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.4)),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _StatusTag({required this.label, required this.value, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String role;
  final String name;

  const _PersonRow({required this.role, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.person_outline, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
          ],
        )
      ],
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String value;

  const _DateInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }
}

class _DashboardInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color themeColor;
  final List<Map<String, dynamic>> stats;
  final String buttonText;
  final VoidCallback onPressed;

  const _DashboardInfoCard({
    required this.title,
    required this.icon,
    required this.themeColor,
    required this.stats,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(6)),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...stats.map((stat) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(stat['label'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        Text(stat['value'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: stat['valueColor'] ?? const Color(0xFF1E293B))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              label: Text(buttonText, style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
            ),
          ),
        ],
      ),
    );
  }
}