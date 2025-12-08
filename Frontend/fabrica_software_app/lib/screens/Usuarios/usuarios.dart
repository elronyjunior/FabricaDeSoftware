import 'package:fabrica_software_app/Widgets/App_bar/App_bar.dart';
import 'package:fabrica_software_app/Widgets/Barra_lateral/Barra_Lateral.dart';
import 'package:fabrica_software_app/models/usuario.dart';
import 'package:fabrica_software_app/providers/usuarios_provider.dart';

import 'package:fabrica_software_app/screens/Usuarios/components/Usuario_modal.dart';
import 'package:fabrica_software_app/screens/Usuarios/components/usuarioRow.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Usuarios extends StatefulWidget {
  const Usuarios({super.key});

  @override
  State<Usuarios> createState() => _UsuariosState();
}

class _UsuariosState extends State<Usuarios> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsuariosProvider>(context, listen: false).carregarUsuarios();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final usuariosProvider = context.watch<UsuariosProvider>();

    return Scaffold(
      drawer: BarraLateral(),
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: CustomAppBar(
        title: 'Gestão de Usuários',
        listaActions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: ElevatedButton.icon(
              onPressed: () => _abrirModalCriarUsuario(context), 
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo Usuário'),
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
                  // Filtros
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
                        // Título e Contador
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lista de Usuários',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${usuariosProvider.usuarios?.length ?? 0} usuários encontrados',
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
                              Expanded(flex: 3, child: Text('E-mail', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Telefone', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(
                                flex: 2, 
                                child: Center(child: Text('Nível', style: TextStyle(fontWeight: FontWeight.bold)))
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- LISTAGEM ---
                        if (usuariosProvider.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (usuariosProvider.error != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text('Erro ao buscar usuários: ${usuariosProvider.error}'),
                            ),
                          )
                        else if (usuariosProvider.usuarios == null || usuariosProvider.usuarios!.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Nenhum usuário encontrado.'),
                            ),
                          )
                        else
                          Column(
                            children: usuariosProvider.usuarios!.map((usuario) {
                              return UsuarioRow(
                                nome: usuario.nome, 
                                email: usuario.email,
                                nivel: usuario.nivel ?? 'Colaborador',
                                telefone: usuario.telefone ?? '-',
                                onView: () => _abrirModalUsuario(context, usuario, UsuarioModalMode.view),
                                onEdit: () => _abrirModalUsuario(context, usuario, UsuarioModalMode.edit),
                                onDelete: () => _abrirModalUsuario(context, usuario, UsuarioModalMode.delete),
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

void _abrirModalUsuario(BuildContext context, Usuario usuario, UsuarioModalMode modo) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => UsuarioModal(
      mode: modo,
      usuario: usuario,
    ),
  );
}

void _abrirModalCriarUsuario(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, 
    builder: (ctx) => const UsuarioModal(
      mode: UsuarioModalMode.create,
    ),
  );
}