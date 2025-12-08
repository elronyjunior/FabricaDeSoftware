import 'package:fabrica_software_app/Widgets/App_bar/App_bar.dart';
import 'package:fabrica_software_app/Widgets/Barra_lateral/Barra_Lateral.dart';
import 'package:fabrica_software_app/models/cliente.dart';
import 'package:fabrica_software_app/providers/clientes_provider.dart';
import 'package:fabrica_software_app/providers/endereco_provider.dart';
import 'package:fabrica_software_app/screens/Clientes/components/ClienteRow.dart';
import 'package:fabrica_software_app/screens/Clientes/components/Cliente_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Clientes extends StatefulWidget {
  const Clientes({super.key});

  @override
  State<Clientes> createState() => _ClientesState();
}

class _ClientesState extends State<Clientes> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientesProvider>(context, listen: false).carregarClientes();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<ClientesProvider>();

    return ChangeNotifierProvider(
      create: (_) => EnderecosProvider(),
      child: Builder(
        builder: (scaffoldContext) {
          final enderecosProvider = scaffoldContext.read<EnderecosProvider>();

          return Scaffold(
            drawer: BarraLateral(),
            backgroundColor: const Color(0xFFF1F5F9),
            appBar: CustomAppBar(
              title: 'Gestão de Clientes',
              listaActions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                 child: ElevatedButton.icon(
                        onPressed: () => _abrirModalCriarCliente(scaffoldContext, enderecosProvider), 
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Novo Cliente'),
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
                        // Filtros viriam aqui
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
                              // Título da Tabela
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Lista de Clientes',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${clientesProvider.clientes?.length ?? 0} clientes encontrados',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),

                              // --- CABEÇALHO DA TABELA (HEADER) ---
                              Container(
                                width: double.infinity,
                                color: Colors.grey[50],
                                // Padding horizontal igual ao da Linha (20)
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                child: Row(
                                  children: const [
                                    // Flex 3: Razão Social
                                    Expanded(
                                      flex: 3,
                                      child: Text('Razão Social', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    // Flex 2: CNPJ
                                    Expanded(
                                      flex: 2,
                                      child: Text('CNPJ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    // Flex 1: Setor (Centralizado)
                                    Expanded(
                                      flex: 1,
                                      child: Center(child: Text('Setor', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ),
                                    // Flex 2: Contato (Padding leve na esquerda para alinhar com texto)
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Text('Contato', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    // Flex 1: Projetos (Centralizado)
                                    Expanded(
                                      flex: 1,
                                      child: Center(child: Text('Projeto(s)', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ),
                                    // Flex 1: Ações (Alinhado à Direita)
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // --- LISTA DE DADOS ---
                              if (clientesProvider.isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (clientesProvider.error != null)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Text('Erro ao buscar clientes: ${clientesProvider.error}'),
                                  ),
                                )
                              else if (clientesProvider.clientes == null || clientesProvider.clientes!.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text('Nenhum cliente encontrado.'),
                                  ),
                                )
                              else
                                Column(
                                  children: clientesProvider.clientes!.map((cliente) {
                                    return ClienteRow(
                                      razaoSocial: cliente.razaoSocial, 
                                      CNPJ: cliente.cnpj,
                                      setor:'${cliente.setor}' ,
                                      contato: cliente.email,
                                      onView: () => _abrirModalCliente(scaffoldContext, cliente, ClienteModalMode.view, enderecosProvider),
                                      onEdit: () => _abrirModalCliente(scaffoldContext, cliente, ClienteModalMode.edit, enderecosProvider),
                                      onDelete: () => _abrirModalCliente(scaffoldContext, cliente, ClienteModalMode.delete, enderecosProvider),
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
      ),
    );
  }
}

void _abrirModalCliente(BuildContext context, Cliente cliente, ClienteModalMode modo, EnderecosProvider provider) {
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: false,
    builder: (ctx) => ClienteModal(
      mode: modo,
      cliente: cliente,
      enderecosProvider: provider,
    ),
  );
}

void _abrirModalCriarCliente(BuildContext context, EnderecosProvider provider) {
  showDialog(
    context: context,
    barrierDismissible: false, 
    useRootNavigator: false,
    builder: (ctx) => ClienteModal(
      mode: ClienteModalMode.create,
      enderecosProvider: provider,
    ),
  );
}