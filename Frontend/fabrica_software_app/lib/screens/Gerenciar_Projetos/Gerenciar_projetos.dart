import 'package:fabrica_software_app/Widgets/App_bar/App_bar.dart';
import 'package:fabrica_software_app/Widgets/Barra_lateral/Barra_Lateral.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/Modal_de_criacao.dart';
import 'package:fabrica_software_app/providers/modal_criacao_projeto_provider.dart';

import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class GerenciarProjetos extends StatefulWidget {
  const GerenciarProjetos({super.key});

  @override
  State<GerenciarProjetos> createState() => _GerenciarProjetosState();
}

class _GerenciarProjetosState extends State<GerenciarProjetos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Um fundo levemente cinza destaca os cards brancos
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
      // AQUI ENTRA O BODY QUE CRIAMOS
      body: const ProjectDashboardBody(),
    );
  }
}

void abrirModalCriacao(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return ChangeNotifierProvider(
        create: (_) => ModalCriacaoProjetoProvider(),
        child: ModalDeCriacao(),
      );
    },
  );
}

// ============================================================================
// WIDGETS DO DASHBOARD (Visual)
// ============================================================================

class ProjectDashboardBody extends StatelessWidget {
  const ProjectDashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // 2. Seção de Filtros
          const FilterSection(),

          const SizedBox(height: 32),

          // 3. Título da Lista
          const Text(
            "Projetos (12)",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),

          const SizedBox(height: 16),

          // 4. Grid de Projetos Responsivo
          LayoutBuilder(
            builder: (context, constraints) {
              // Lógica de colunas baseada na largura da tela
              int crossAxisCount = constraints.maxWidth > 1100
                  ? 3
                  : constraints.maxWidth > 700
                      ? 2
                      : 1;

              // Ajuste da proporção (altura vs largura) do card
              double childAspectRatio = constraints.maxWidth > 700 ? 1.3 : 1.5;

              return GridView.builder(
                shrinkWrap: true, // Importante para funcionar dentro do SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                  mainAxisExtent: 240, // Altura fixa para garantir uniformidade
                ),
                itemCount: projectsMock.length,
                itemBuilder: (context, index) {
                  return ProjectCard(data: projectsMock[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: SEÇÃO DE FILTROS ---
class FilterSection extends StatelessWidget {
  const FilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filtros de Pesquisa",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text("Limpar Filtros"),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Wrap permite que os campos "quebrem a linha" em telas menores
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildInput("Nome do Projeto", "Buscar projeto...", width: 250),
              _buildDropdown("Tipo", "Todos os tipos", width: 180),
              _buildInput("Cliente", "Nome do cliente...", width: 250),
              _buildDropdown("Status", "Todos os status", width: 180),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, String hint, {required double width}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 45, // Altura fixa para alinhar com dropdowns
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, {required double width}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: [
                  DropdownMenuItem(value: value, child: Text(value, style: const TextStyle(fontSize: 13)))
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: CARD DO PROJETO ---
class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProjectCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBgColor;

    switch (data['status']) {
      case 'Em processo':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.shade50;
        break;
      case 'Concluído':
        statusColor = Colors.blue.shade700;
        statusBgColor = Colors.blue.shade50;
        break;
      case 'Pausado':
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.shade50;
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.shade100;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 230, 228, 228)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: data['iconColor'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data['icon'], color: data['iconColor'], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['client'],
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
                  data['status'],
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Descrição
          Text(
            data['description'],
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
          ),

          const Spacer(),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fake Avatars
              SizedBox(
                width: 80,
                height: 30,
                child: Stack(
                  children: [
                    _buildAvatar(0, Colors.red),
                    _buildAvatar(15, Colors.blue),
                    _buildAvatar(30, Colors.green),
                  ],
                ),
              ),
              Text(
                data['type'],
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAvatar(double left, Color color) {
    return Positioned(
      left: left,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          // Usando container colorido simples como placeholder para evitar erro de rede
          // image: DecorationImage(image: NetworkImage("..."))
        ),
        child: Center(
            child: Icon(Icons.person, size: 16, color: color.withOpacity(0.8))
        ),
      ),
    );
  }
}

// --- DADOS MOCKADOS ---
final List<Map<String, dynamic>> projectsMock = [
  {
    "title": "E-commerce Platform",
    "client": "Cliente 1",
    "status": "Em processo",
    "description": "Desenvolvimento de plataforma completa de e-commerce com integração de pagamentos e estoque.",
    "type": "Web",
    "icon": Icons.language,
    "iconColor": Colors.blue,
  },
  {
    "title": "Mobile Banking App",
    "client": "Cliente 2",
    "status": "Concluído",
    "description": "Aplicativo móvel para operações bancárias com biometria e notificações push.",
    "type": "Mobile",
    "icon": Icons.smartphone,
    "iconColor": Colors.purple,
  },
  {
    "title": "CRM API Integration",
    "client": "Cliente 3",
    "status": "Pausado",
    "description": "Integração de API REST para sincronização de dados entre sistemas CRM e ERP legado.",
    "type": "API",
    "icon": Icons.code,
    "iconColor": Colors.green,
  },
  {
    "title": "Dashboard Financeiro",
    "client": "Tegra",
    "status": "Em processo",
    "description": "Dashboard analítico para visualização de gastos e receitas em tempo real.",
    "type": "Web",
    "icon": Icons.pie_chart,
    "iconColor": Colors.orange,
  },
  
];