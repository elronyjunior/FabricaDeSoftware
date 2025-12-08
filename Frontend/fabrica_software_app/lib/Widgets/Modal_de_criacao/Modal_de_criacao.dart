import 'package:fabrica_software_app/providers/modal_criacao_projeto_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class ModalDeCriacao extends StatelessWidget {

  const ModalDeCriacao({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModalCriacaoProjetoProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: [
            // -------------------------------------------------------
            // INÍCIO DO CABEÇALHO (Integrado diretamente)
            // -------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Ícone com gradiente
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: provider.returnColors(),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FaIcon(provider.returnIcon(), color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      
                      // Título
                      Expanded(
                        child: Text(
                          provider.returnTitle(),
                          style: const TextStyle(
                            fontSize: 15, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      
                      // Navegação
                      IconButton(
                        onPressed: () {provider.previousIndex();}, 
                        icon: const FaIcon(FontAwesomeIcons.caretLeft)
                      ),
                      Text(provider.returnTabName()),
                      IconButton(
                        onPressed: () {provider.nextIndex();}, 
                        icon: const FaIcon(FontAwesomeIcons.caretRight)
                      ),
                      const SizedBox(width: 20),
                      
                      // Botão Fechar
                      IconButton(
                        iconSize: 20, // Ajustei levemente para padronizar
                        color: const Color.fromARGB(171, 179, 177, 177),
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Texto de Progresso
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progresso do formulário',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${provider.returnPercentNumber()*100}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Barra de Progresso
                  LinearProgressIndicator(
                    value: provider.returnPercentNumber(),
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
            // -------------------------------------------------------
            // FIM DO CABEÇALHO
            // -------------------------------------------------------

            const Divider(height: 1, color: Color.fromARGB(50, 158, 158, 158)),

            // -------------------------------------------------------
            // CORPO (Conteúdo Scrollável)
            // -------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: provider.returnBody(context),
              ),
            ),

            // -------------------------------------------------------
            // RODAPÉ (Integrado diretamente)
            // -------------------------------------------------------
            Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(66, 150, 146, 146),
                    blurRadius: 3,
                    offset: Offset(0, -10),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(child: provider.returnFooter(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}