import 'package:fabrica_software_app/Widgets/App_bar/App_bar.dart';
import 'package:fabrica_software_app/Widgets/Barra_lateral/Barra_Lateral.dart';
import 'package:fabrica_software_app/screens/Equipe/modais/Modal_Adicionar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/providers/equipes_provider.dart';
import 'package:fabrica_software_app/models/projeto.dart';
import 'package:fabrica_software_app/models/contribuidor.dart';

class GerenciarEquipesScreen extends StatefulWidget {
  const GerenciarEquipesScreen({super.key});

  @override
  State<GerenciarEquipesScreen> createState() => _GerenciarEquipesScreenState();
}

class _GerenciarEquipesScreenState extends State<GerenciarEquipesScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EquipesProvider>(
      create: (_) => EquipesProvider()..carregarDados(),
      child: Scaffold(
        appBar: CustomAppBar(title: "Gestão de Equipes"),
        drawer: BarraLateral(),
        backgroundColor: Colors.grey[50],
        body: Consumer<EquipesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null) {
              return Center(child: Text("Erro: ${provider.error}"));
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ESQUERDA: PROJETOS (Sanfona) ---
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Projetos e Equipes",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Clique para expandir. Arraste pessoas da direita para cima do projeto.",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        
                        Expanded(
                          child: ListView.separated(
                            itemCount: provider.projetos.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final projeto = provider.projetos[index];
                              final membros = provider.getMembrosDoProjeto(projeto.id ?? 0);
                              
                              return TeamProjectExpansionCard(
                                projeto: projeto, 
                                membros: membros,
                                onMemberAdded: (contribuidor) {
                                  provider.adicionarMembro(projeto.id!, contribuidor.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${contribuidor.nome} adicionado ao time!'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(milliseconds: 1000),
                                      behavior: SnackBarBehavior.floating,
                                      width: 400,
                                    )
                                  );
                                },
                                onMemberRemoved: (contribuidor) {
                                  provider.removerMembro(projeto.id!, contribuidor.id!);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- DIREITA: PESSOAS ---
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade300),
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.people, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Pessoas Disponíveis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("${provider.contribuidores.length} pessoas", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => ModalAdicionarPessoa(provider: provider),
                              );
                            },
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text("Nova Pessoa"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Expanded(
                          child: ListView.builder(
                            itemCount: provider.contribuidores.length,
                            itemBuilder: (context, index) {
                              return DraggablePersonItem(
                                person: provider.contribuidores[index],
                                provider: provider,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- WIDGET 1: PROJETO ALVO (Sanfona) ---
class TeamProjectExpansionCard extends StatelessWidget {
  final Projeto projeto;
  final List<Contribuidor> membros;
  final Function(Contribuidor) onMemberAdded;
  final Function(Contribuidor) onMemberRemoved;

  const TeamProjectExpansionCard({super.key, required this.projeto, required this.membros, required this.onMemberAdded, required this.onMemberRemoved});

  @override
  Widget build(BuildContext context) {
    // Ícones básicos baseados no nome do tipo ou modelo
    IconData icon = Icons.folder;
    Color color = Colors.grey;
    final tipo = (projeto.tipo ?? projeto.modeloProjeto ?? '').toUpperCase();
    if (tipo.contains('WEB')) { icon = Icons.language; color = Colors.blue; }
    else if (tipo.contains('MOBILE')) { icon = Icons.smartphone; color = Colors.purple; }
    else if (tipo.contains('API')) { icon = Icons.storage; color = Colors.orange; }

    return DragTarget<Contribuidor>(
      onWillAccept: (data) => true,
      onAccept: (data) => onMemberAdded(data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHovering ? color.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isHovering ? color : Colors.grey.shade200, width: isHovering ? 2 : 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 24),
              ),
              title: Text(projeto.nomeProjeto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(projeto.descricao ?? "Sem descrição", maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${membros.length} membros", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
              children: [
                const Divider(),
                const SizedBox(height: 16),
                if (membros.isEmpty)
                  Center(child: Text("Arraste alguém aqui", style: TextStyle(color: Colors.grey.shade400)))
                else
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    children: membros.map((m) => _MemberChip(membro: m, onRemove: () => onMemberRemoved(m))).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MemberChip extends StatelessWidget {
  final Contribuidor membro;
  final VoidCallback onRemove;
  const _MemberChip({required this.membro, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200, padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.shade50, radius: 16, child: Text(membro.nome.substring(0, 1).toUpperCase())),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(membro.nome, overflow: TextOverflow.ellipsis), Text(membro.cargo ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey))])),
          InkWell(onTap: onRemove, child: const Icon(Icons.close, size: 16, color: Colors.red))
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET 2: PESSOA ARRASTÁVEL (CORRIGIDO PARA CLIQUE FUNCIONAR)
// ============================================================================
class DraggablePersonItem extends StatefulWidget {
  final Contribuidor person;
  final EquipesProvider provider;

  const DraggablePersonItem({
    super.key, 
    required this.person,
    required this.provider,
  });

  @override
  State<DraggablePersonItem> createState() => _DraggablePersonItemState();
}

class _DraggablePersonItemState extends State<DraggablePersonItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // 1. O Visual do Cartão (Base)
    Widget buildCardContent() {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.pink,
              radius: 18,
              child: Text(
                widget.person.nome.isNotEmpty 
                    ? widget.person.nome.substring(0, 1).toUpperCase() 
                    : "?",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.person.nome,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.person.cargo ?? "Sem cargo",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Espaço vazio onde os botões ou o ícone de drag vão ficar
            const SizedBox(width: 60), 
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Stack(
        children: [
          // CAMADA 1: O ITEM ARRASTÁVEL (Fica no fundo)
          Draggable<Contribuidor>(
            data: widget.person,
            feedback: SizedBox(
              width: 250,
              child: Material(
                color: Colors.transparent,
                child: Opacity(opacity: 0.85, child: buildCardContent()),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: buildCardContent(),
            ),
            child: buildCardContent(),
          ),

          // CAMADA 2: BOTÕES DE AÇÃO (Ficam por cima para pegar o clique)
          // Usamos Positioned para colocá-los exatamente onde queremos (direita)
          Positioned(
            right: 12, // Alinhado à direita (dentro da margem do container)
            top: 0,
            bottom: 12, // Compensa a margem inferior do container
            child: Center( // Centraliza verticalmente
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isHovering) ...[
                    // Botão Editar
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => ModalAdicionarPessoa(
                            provider: widget.provider,
                            contribuidorParaEditar: widget.person,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50, 
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botão Excluir
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.white,
                            title: const Text("Excluir Pessoa"),
                            content: Text("Tem certeza que deseja apagar ${widget.person.nome}?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx), 
                                child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
                              ),
                              TextButton(
                                onPressed: () {
                                  widget.provider.deletarContribuidor(widget.person.id!);
                                  Navigator.pop(ctx);
                                },
                                child: const Text("Excluir", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50, 
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: const Icon(Icons.delete, size: 18, color: Colors.red),
                      ),
                    ),
                  ] else ...[
                    // Ícone de Drag (apenas visual, pois o clique passa direto pro Draggable embaixo)
                    const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
