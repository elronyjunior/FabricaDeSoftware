import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/models/projeto.dart';
import 'package:fabrica_software_app/config/projeto_dto.dart';
import 'package:fabrica_software_app/providers/projetos_provider.dart';
import 'package:fabrica_software_app/providers/modal_criacao_projeto_provider.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/Modal_de_criacao.dart';
import 'package:fabrica_software_app/screens/Gerenciar_Projetos/components/visualizador_Projetos_Screen.dart';

class ProjectCard extends StatefulWidget {
  final Projeto projeto;
  const ProjectCard({super.key, required this.projeto});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _isHovered = false;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Concluído': return Colors.blue.shade700;
      case 'Atrasado': return Colors.red.shade700;
      default: return Colors.green.shade700;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Concluído': return Colors.blue.shade50;
      case 'Atrasado': return Colors.red.shade50;
      default: return Colors.green.shade50;
    }
  }

  IconData _getIcon() {
    final tipoVerificado = (widget.projeto.tipo ?? '').toUpperCase();
    final fallback = tipoVerificado.isNotEmpty ? tipoVerificado : (widget.projeto.modeloProjeto ?? '').toUpperCase();
    if (fallback.contains('WEB')) return Icons.language;
    if (fallback.contains('MOBILE') || fallback.contains('APP')) return Icons.smartphone;
    if (fallback.contains('API')) return Icons.storage;
    if (fallback.contains('DESKTOP')) return Icons.monitor;
    if (fallback.contains('DATA')) return Icons.analytics;
    return Icons.folder_open;
  }

  Color _getIconColor() {
    final tipoVerificado = (widget.projeto.tipo ?? '').toUpperCase();
    final fallback = tipoVerificado.isNotEmpty ? tipoVerificado : (widget.projeto.modeloProjeto ?? '').toUpperCase();
    if (fallback.contains('WEB')) return Colors.blue;
    if (fallback.contains('MOBILE')) return Colors.purple;
    if (fallback.contains('API')) return Colors.orange;
    if (fallback.contains('DESKTOP')) return Colors.indigo;
    if (fallback.contains('DATA')) return Colors.teal;
    return Colors.grey;
  }

  void _editarProjeto(BuildContext context) {
    projetoDraft.loadFromModel(widget.projeto);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return ChangeNotifierProvider(
          create: (_) {
            final p = ModalCriacaoProjetoProvider();
            p.iniciarEdicao();
            return p;
          },
          child: const ModalDeCriacao(),
        );
      },
    );
  }

  void _excluirProjeto(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Projeto'),
        content: Text('Deseja realmente apagar "${widget.projeto.nomeProjeto}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ProjetosProvider>().excluirProjeto(widget.projeto.id ?? 0);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.projeto.statusCalculado;
    final statusColor = _getStatusColor(status);
    final statusBgColor = _getStatusBgColor(status);
    final icon = _getIcon();
    final iconColor = _getIconColor();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        children: [
          // 1. CARD PRINCIPAL (CLICÁVEL)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisualizarProjetoScreen(projeto: widget.projeto),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color.fromARGB(255, 230, 228, 228)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: iconColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.projeto.nomeProjeto,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.projeto.clienteNome ?? 'Cliente não inf.',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Descrição
                      Text(
                        widget.projeto.descricao ?? 'Sem descrição',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                      ),
                      
                      const Spacer(),
                      
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFEEEEEE),
                            radius: 14,
                            child: Icon(Icons.person, size: 16, color: Colors.grey),
                          ),
                          Text(
                            widget.projeto.tipo ?? 'Geral',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. BOTÕES DE AÇÃO (HOVER - RODAPÉ)
          if (_isHovered)
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconAction(
                    icon: Icons.edit,
                    color: Colors.blueGrey,
                    onTap: () => _editarProjeto(context),
                  ),
                  const SizedBox(width: 4),
                  _IconAction(
                    icon: Icons.delete,
                    color: Colors.red.shade400,
                    onTap: () => _excluirProjeto(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9), // Fundo sutil para leitura
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}