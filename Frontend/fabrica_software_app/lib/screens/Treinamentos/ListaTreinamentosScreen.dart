import 'package:fabrica_software_app/screens/Treinamentos/ControlePresencaScreen.dart';
import 'package:fabrica_software_app/screens/Treinamentos/ModalCriarTreinamento.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fabrica_software_app/models/projeto.dart';
import 'package:fabrica_software_app/providers/treinamentos_provider.dart';

class ListaTreinamentosScreen extends StatelessWidget {
  final Projeto projeto;

  const ListaTreinamentosScreen({super.key, required this.projeto});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TreinamentosProvider>(
      create: (_) => TreinamentosProvider()..carregarTreinamentos(projeto.id!),
      // ADICIONADO: O Builder cria um novo contexto abaixo do Provider
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC), // Fundo cinza bem claro
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Treinamentos",
                style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 22),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ModalCriarTreinamento(
                          projetoId: projeto.id!,
                          // AGORA FUNCIONA: O context aqui já enxerga o Provider
                          onSuccess: () => context.read<TreinamentosProvider>().carregarTreinamentos(projeto.id!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Novo Treinamento"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink, // Verde
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              ],
            ),
            
            body: Consumer<TreinamentosProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          
                          // LISTA DE CARDS
                          if (provider.treinamentos.isEmpty)
                            _buildEmptyState()
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.treinamentos.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return _buildCardEstiloFigma(context, provider, provider.treinamentos[index]);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
      ),
    );
  }

  // --- CARD PRINCIPAL ---
  Widget _buildCardEstiloFigma(BuildContext context, TreinamentosProvider provider, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LINHA 1: Título e Badge e Botão
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Título
              Text(t['nome'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(width: 12),
              const Spacer(), // Empurra o botão para a direita

              // Botão "Lista de Chamada" Azul
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ControlePresencaScreen(treinamentoId: int.parse(t['id'].toString()), tituloTreinamento: t['nome'])));
                },
                icon: const Icon(Icons.assignment_outlined, size: 16),
                label: const Text("Lista de Chamada"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C), // Azul Royal
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),

          const SizedBox(height: 12),

          // LINHA 2: Descrição
          Text(
            t['descricao'] ?? "Treinamento extensivo sobre desenvolvimento",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),

          const SizedBox(height: 24),

          // LINHA 3: Ícones de Informação (Data, Alunos, Aulas)
          Row(
            children: [
              _buildInfoIcon(Icons.calendar_today_outlined, "${_formatDate(t['data_inicio'])} - ${_formatDate(t['data_termino'])}"),
              const SizedBox(width: 24),
              const Spacer(),
              
              // Menu de Mais Opções (Editar/Excluir) discreto no canto
              PopupMenuButton(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') {
                     showDialog(context: context, builder: (_) => ModalCriarTreinamento(projetoId: projeto.id!, treinamentoEdicao: t, onSuccess: () => provider.carregarTreinamentos(projeto.id!)));
                  } else if (value == 'delete') {
                    provider.deletarTreinamento(int.parse(t['id'].toString()));
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Editar")])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("Excluir", style: TextStyle(color: Colors.red))])),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(padding: const EdgeInsets.all(40), alignment: Alignment.center, child: Text("Nenhum treinamento encontrado", style: TextStyle(color: Colors.grey[400])));
  }

  String _formatDate(String? iso) {
    if (iso == null) return "--/--";
    try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso)); } catch (e) { return iso; }
  }
}