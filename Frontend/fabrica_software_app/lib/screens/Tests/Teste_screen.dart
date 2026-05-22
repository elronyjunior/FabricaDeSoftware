import 'package:fabrica_software_app/models/teste.dart';
import 'package:fabrica_software_app/providers/testes_provider.dart';
// Note que aqui estou importando o arquivo com letra Maiúscula conforme sua imagem
import 'package:fabrica_software_app/screens/Tests/Teste_modal.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TestesScreen extends StatelessWidget {
  final int projetoId;
  final String nomeProjeto;

  const TestesScreen({
    Key? key,
    required this.projetoId,
    required this.nomeProjeto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TestesProvider()..carregarTestes(projetoId),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            nomeProjeto,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        // Passamos o ID para o widget filho para o botão "Novo" funcionar
        body: _TestesContent(projetoId: projetoId),
      ),
    );
  }
}

class _TestesContent extends StatelessWidget {
  final int projetoId;

  const _TestesContent({Key? key, required this.projetoId}) : super(key: key);

  // Função para abrir o Modal Centralizado
  void _abrirModal(BuildContext context, TestesProvider provider, {Teste? teste}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500), // Evita ficar gigante
          child: TesteModal(
            projetoId: projetoId, // Usa o ID recebido
            testeExistente: teste,
            onSave: (t) async {
              if (t.id == null) {
                await provider.adicionarTeste(t);
              } else {
                await provider.atualizarTeste(t);
              }
            },
          ),
        ),
      ),
    );
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'concluido': return Colors.green;
      case 'falha': return Colors.red;
      case 'em_progresso': return Colors.blue;
      default: return Colors.orange;
    }
  }

  String _textoStatus(String status) {
    switch (status) {
      case 'concluido': return 'Concluído';
      case 'falha': return 'Falha';
      case 'em_progresso': return 'Executando';
      case 'pendente': return 'Pendente';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TestesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.erro != null) {
          return Center(child: Text("Erro: ${provider.erro}"));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gestão de Testes",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                "${provider.testes.length} testes cadastrados",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              
              // Botão Novo Teste
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _abrirModal(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_task, color: Colors.white),
                  label: const Text(
                    "Novo Teste",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: provider.testes.isEmpty
                    ? Center(child: Text("Nenhum teste encontrado", style: TextStyle(color: Colors.grey[400])))
                    : ListView.builder(
                        itemCount: provider.testes.length,
                        itemBuilder: (context, index) {
                          final teste = provider.testes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.bug_report_outlined, color: Colors.black87),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      teste.nome,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _corStatus(teste.situacao).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _textoStatus(teste.situacao),
                                      style: TextStyle(
                                        color: _corStatus(teste.situacao),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(teste.descricao ?? 'Sem descrição'),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _abrirModal(context, provider, teste: teste),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          title: const Text('Excluir'),
                                          content: const Text('Confirmar exclusão?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                provider.excluirTeste(teste.id!);
                                              },
                                              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}