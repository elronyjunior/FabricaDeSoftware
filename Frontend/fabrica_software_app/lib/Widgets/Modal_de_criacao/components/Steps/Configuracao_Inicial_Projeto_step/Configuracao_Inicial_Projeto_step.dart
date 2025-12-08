import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Modal_step.dart';
import 'package:fabrica_software_app/providers/modal_criacao_projeto_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'components.dart';

class ConfiguracaoInicialProjetoStep extends ModalStep {

  @override
  String get title => 'Configuração inicial do projeto';

  @override
  String get tabName => 'Informações Gerais'; // Ajustado conforme imagem

  @override
  IconData get icon => FontAwesomeIcons.gears;

  @override
  List<Color> get cores => <Color>[const Color.fromARGB(255, 4, 187, 233)];

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // 1. HEADER "Informações Gerais"
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD), // Azul bem claro
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF2962FF), size: 20),
              SizedBox(width: 10),
              Text(
                "Informações Gerais",
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // 2. NOME DO PROJETO
        ComponentsConfiguracaoInicalProjeto.buildLabel("Nome do projeto", isRequired: false),
        Container(
          decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
          child: TextField(
            decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Ex: Sistema de Gestão Empresarial"),
          ),
        ),

        const SizedBox(height: 16),

        // 3. DESCRIÇÃO
        ComponentsConfiguracaoInicalProjeto.buildLabel("Descrição", isRequired: false),
        Container(
          decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
          child: TextField(
            maxLines: 4, // Caixa maior para descrição
            decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Descreva brevemente o objetivo do projeto..."),
          ),
        ),

        const SizedBox(height: 16),

        // 4. LINHA DUPLA (CLIENTE E METODOLOGIA)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coluna da Esquerda (Cliente)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ComponentsConfiguracaoInicalProjeto.buildLabel("Cliente", isRequired: true),
                  Container(
                    decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                    child: TextField(
                      decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Buscar cliente...", icon: Icons.search),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16), // Espaço entre as colunas
            
            // Coluna da Direita (Metodologia)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ComponentsConfiguracaoInicalProjeto.buildLabel("Metodologia", isRequired: true),
                  Container(
                    decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                            maxLines: 1, // Caixa maior para descrição
                            decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Metodologia usada"),
                  ),
                  )
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Separa os botões
        children: [
          
          // Botão Próxima Etapa
          ElevatedButton(
            onPressed: () {
              context.read<ModalCriacaoProjetoProvider>().nextIndex();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF), // Azul vibrante
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Próxima etapa'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}