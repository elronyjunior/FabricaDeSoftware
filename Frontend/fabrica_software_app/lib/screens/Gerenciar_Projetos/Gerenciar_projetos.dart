import 'package:fabrica_software_app/Widgets/App_bar/App_bar.dart';
import 'package:fabrica_software_app/Widgets/Barra_lateral/Barra_Lateral.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/Modal_de_criacao.dart';
import 'package:fabrica_software_app/config/projeto_dto.dart';
import 'package:fabrica_software_app/providers/modal_criacao_projeto_provider.dart';
import 'package:fabrica_software_app/providers/projetos_provider.dart'; // Importe o provider
import 'components/Card_Projeto.dart';
import 'components/filtro.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GerenciarProjetos extends StatefulWidget {
  const GerenciarProjetos({super.key});

  @override
  State<GerenciarProjetos> createState() => _GerenciarProjetosState();
}

class _GerenciarProjetosState extends State<GerenciarProjetos> {
  
  @override
  void initState() {
    super.initState();
    // Inicia o carregamento dos dados assim que a tela é construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjetosProvider>().carregarProjetos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Gestão de Projetos',
        listaActions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: ElevatedButton.icon(
              onPressed: () => abrirModalCriacao(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo Projeto'),
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
      drawer: BarraLateral(),
      // Usamos o corpo com estado agora
      body: const ProjectDashboardBody(),
    );
  }
}

void abrirModalCriacao(BuildContext context) {
  projetoDraft.clear(); // 1. Limpa dados

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return ChangeNotifierProvider(
        create: (_) {
          final p = ModalCriacaoProjetoProvider();
          p.iniciarCriacao(); // <--- ATIVA O MODO CRIAÇÃO (Wizard)
          return p;
        },
        child: const ModalDeCriacao(),
      );
    },
  );
}

// ============================================================================
// BODY COM CONSUMER (DADOS REAIS)
// ============================================================================

class ProjectDashboardBody extends StatelessWidget {
  const ProjectDashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer escuta o Provider. Sempre que houver notifyListeners(), ele reconstrói.
    return Consumer<ProjetosProvider>(
      builder: (context, provider, child) {
        
        // 1. Carregando
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Erro
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Erro ao carregar: ${provider.error}'),
                TextButton(
                  onPressed: () => provider.carregarProjetos(),
                  child: const Text('Tentar novamente'),
                )
              ],
            ),
          );
        }

        final projetos = provider.projetos ?? [];

        // 3. Sucesso (Lista)
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              const FilterSection(), // Seus filtros visuais

              const SizedBox(height: 32),

              Text(
                "Projetos (${projetos.length})",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),

              const SizedBox(height: 16),
              
              if (projetos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("Nenhum projeto encontrado."),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 1100
                        ? 3
                        : constraints.maxWidth > 700
                            ? 2
                            : 1;

                    double childAspectRatio = constraints.maxWidth > 700 ? 1.3 : 1.5;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: childAspectRatio,
                        mainAxisExtent: 240,
                      ),
                      itemCount: projetos.length,
                      itemBuilder: (context, index) {
                        return ProjectCard(projeto: projetos[index]);
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}