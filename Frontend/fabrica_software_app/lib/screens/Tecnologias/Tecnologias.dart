import 'package:fabrica_software_app/models/tecnologia.dart';
import 'package:fabrica_software_app/providers/tecnologias_provider.dart';
import 'package:fabrica_software_app/screens/Tecnologias/components/TecnologiaRow.dart';
import 'package:fabrica_software_app/screens/Tecnologias/components/Tecnologia_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/Widgets/App_bar/App_bar.dart'; 
import 'package:fabrica_software_app/Widgets/Barra_lateral/Barra_Lateral.dart';

class Tecnologias extends StatefulWidget {
  const Tecnologias({super.key});

  @override
  State<Tecnologias> createState() => _TecnologiasState();
}

class _TecnologiasState extends State<Tecnologias> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TecnologiasProvider>(context, listen: false).carregarTecnologias();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final tecnologiasProvider = context.watch<TecnologiasProvider>();
    
    return Scaffold(
      drawer: BarraLateral(),
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: CustomAppBar(
        title: 'Gestão de Tecnologias',
        listaActions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: ElevatedButton.icon(
              onPressed: () => _abrirModalCriarTecnologia(context), 
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nova Tecnologia'),
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
                  // TODO: Filtros aqui se necessário
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
                                'Lista de Tecnologias',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${tecnologiasProvider.tecnologias?.length ?? 0} tecnologias encontradas',
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
                          child: Row(
                            children: const [
                              Expanded(flex: 3, child: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 4, child: Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(
                                flex: 2, 
                                child: Center(
                                  child: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))
                                )
                              ),
                            ],
                          ),
                        ),

                        // --- LISTAGEM ---
                        if (tecnologiasProvider.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (tecnologiasProvider.error != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text('Erro ao buscar tecnologias: ${tecnologiasProvider.error}'),
                            ),
                          )
                        else if (tecnologiasProvider.tecnologias == null || tecnologiasProvider.tecnologias!.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Nenhuma tecnologia encontrada.'),
                            ),
                          )
                        else
                          Column(
                            children: tecnologiasProvider.tecnologias!.map((tecnologia) {
                              return TecnologiaRow(
                                nome: tecnologia.nome, 
                                categoria: tecnologia.categoria ?? 'N/A',
                                descricao: tecnologia.descricao ?? 'N/A',
                                onView: () => _abrirModalTecnologia(context, tecnologia, TecnologiaModalMode.view),
                                onEdit: () => _abrirModalTecnologia(context, tecnologia, TecnologiaModalMode.edit),
                                onDelete: () => _abrirModalTecnologia(context, tecnologia, TecnologiaModalMode.delete),
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

void _abrirModalTecnologia(BuildContext context, Tecnologia tecnologia, TecnologiaModalMode modo) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => TecnologiaModal(
      mode: modo,
      tecnologia: tecnologia,
    ),
  );
}

void _abrirModalCriarTecnologia(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, 
    builder: (ctx) => const TecnologiaModal(
      mode: TecnologiaModalMode.create,
    ),
  );
}