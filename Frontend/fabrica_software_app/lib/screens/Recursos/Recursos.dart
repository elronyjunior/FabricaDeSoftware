import 'package:fabrica_software_app/Widgets/Barra_lateral/Barra_Lateral.dart';
import 'package:fabrica_software_app/models/projeto.dart';
import 'package:fabrica_software_app/models/recurso.dart';
import 'package:fabrica_software_app/providers/recursos_provider.dart';
import 'package:fabrica_software_app/screens/Recursos/components/RecursosRow.dart';
import 'package:fabrica_software_app/screens/Recursos/components/Recursos_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Recursos extends StatefulWidget {
  // Parâmetro opcional: Se vier preenchido, filtra por projeto.
  final Projeto? projetoVinculado;

  const Recursos({super.key, this.projetoVinculado});

  @override
  State<Recursos> createState() => _RecursosState();
}

class _RecursosState extends State<Recursos> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.projetoVinculado != null) {
        // Se tem projeto vinculado, carrega filtrado
        // OBS: Certifique-se que o ID do projeto não é nulo
        context.read<RecursosProvider>().carregarRecursosPorProjeto(widget.projetoVinculado!.id!);
      } else {
        // Se não tem, carrega todos (comportamento padrão)
        context.read<RecursosProvider>().carregarRecursos();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final recursosProvider = context.watch<RecursosProvider>();
    // Flag para saber se estamos no modo filtrado
    final bool isFiltrado = widget.projetoVinculado != null;
    
    return Scaffold(
      // Se estiver filtrado, NÃO mostra o menu lateral (Drawer) para não confundir a navegação
      drawer: isFiltrado ? null : BarraLateral(),
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Configura o botão da esquerda (Leading)
        leading: IconButton(
          icon: Icon(
            isFiltrado ? Icons.arrow_back : Icons.menu, // Seta se filtrado, Menu se geral
            color: const Color(0xFF1E293B)
          ),
          onPressed: () {
            if (isFiltrado) {
              Navigator.pop(context); // Volta para a tela do projeto
            } else {
              Scaffold.of(context).openDrawer(); // Abre o menu lateral
            }
          },
        ),
        title: Text(
          isFiltrado 
            ? 'Gestão de Recursos' // Título específico
            : 'Gestão de Recursos',
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: ElevatedButton.icon(
              onPressed: () => _abrirModalCriarRecurso(context), 
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo Recurso'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 34),
                  // TODO: Filtros aqui (se necessário)
                  const SizedBox(height: 24),
                  
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- TÍTULO E CONTADOR ---
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lista de Recursos',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${recursosProvider.recursos?.length ?? 0} recursos encontrados',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        // --- CABEÇALHO DA TABELA ---
                        Container(
                          width: double.infinity,
                          color: Colors.grey[50],
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Expanded(flex: 2, child: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Disponível', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(
                                flex: 1, 
                                child: Center(
                                  child: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))
                                )
                              ),
                            ],
                          ),
                        ),

                        // --- LISTAGEM ---
                        if (recursosProvider.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (recursosProvider.error != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text('Erro ao buscar recursos: ${recursosProvider.error}'),
                            ),
                          )
                        else if (recursosProvider.recursos == null || recursosProvider.recursos!.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Nenhum recurso encontrado.'),
                            ),
                          )
                        else
                          Column(
                            children: recursosProvider.recursos!.map((recurso) {
                              return RecursoRow(
                                nome: recurso.nome, 
                                tipo: recurso.tipo,
                                disponivel: recurso.disponivel,
                                descricao: recurso.descricao ?? '',
                                onView: () => _abrirModalRecurso(context, recurso, RecursoModalMode.view),
                                onEdit: () => _abrirModalRecurso(context, recurso, RecursoModalMode.edit),
                                onDelete: () => _abrirModalRecurso(context, recurso, RecursoModalMode.delete),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _abrirModalRecurso(BuildContext context, Recurso recurso, RecursoModalMode modo) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => RecursoModal(
      mode: modo,
      recurso: recurso,
    ),
  );
}

void _abrirModalCriarRecurso(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, 
    builder: (ctx) => const RecursoModal(
      mode: RecursoModalMode.create,
    ),
  );
}