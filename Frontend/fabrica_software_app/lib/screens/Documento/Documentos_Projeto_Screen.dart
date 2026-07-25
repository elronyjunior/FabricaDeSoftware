import 'package:fabrica_software_app/screens/Documento/Criar_Doc_Modal.dart';
import 'package:fabrica_software_app/screens/Documento/Visualizar_Documento_Screen.dart';
import 'package:flutter/material.dart';
import 'package:fabrica_software_app/models/projeto.dart';
import 'package:fabrica_software_app/services/documento_service.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:fabrica_software_app/config/api_config.dart'; // Para acessar delete direto se precisar ou via service
import 'package:http/http.dart' as http;
import 'package:fabrica_software_app/services/auth_service.dart';

class DocumentosProjetoScreen extends StatefulWidget {
  final Projeto projeto;

  const DocumentosProjetoScreen({super.key, required this.projeto});

  @override
  State<DocumentosProjetoScreen> createState() => _DocumentosProjetoScreenState();
}

class _DocumentosProjetoScreenState extends State<DocumentosProjetoScreen> {
  final _service = DocumentoService();
  List<dynamic> _documentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDocumentos();
  }

  Future<void> _carregarDocumentos() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _service.getDocumentosDoProjeto(widget.projeto.id!);
      setState(() {
        _documentos = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Lógica Corrigida para Abrir Link
  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Não foi possível abrir';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao abrir link")));
    }
  }

  // Documentos gerados depois da persistência do JSON abrem o editor in-app;
  // documentos legados (sem conteudo_json) continuam abrindo o Google Docs
  // externamente, como já era feito.
  void _abrirDocumento(dynamic doc) {
    final editavel = doc['tem_conteudo_editavel'] == true;
    if (!editavel) {
      _abrirLink(doc['arquivo_url']);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisualizarDocumentoScreen(
          documentoId: int.parse(doc['id'].toString()),
          nomeArquivo: doc['nome_do_arquivo'] ?? 'Documento',
          arquivoUrl: doc['arquivo_url'],
        ),
      ),
    );
  }

  // Lógica para Deletar (Banco + Drive)
  Future<void> _deletarDocumento(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Excluir Documento"),
        content: const Text("Isso apagará o registro e o arquivo no Google Drive. Tem certeza?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);
    
    try {
      // Fazendo a chamada DELETE manual aqui para garantir (ou adicione no service)
      final token = await AuthService.instance.token;
      final url = Uri.parse('${ApiConfig.baseUrl}/documentos/$id');
      final response = await http.delete(url, headers: ApiConfig.getAuthHeaders(token));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Documento apagado!"), backgroundColor: Colors.green));
        _carregarDocumentos(); // Recarrega a lista
      } else {
        throw Exception("Erro ao deletar");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao excluir documento"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo branco igual ao print
      appBar: AppBar(
        title: Text("Documentação e Artefatos", style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header com contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: Row(
              children: [
                Text("${_documentos.length} documentos no projeto", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            child: Align( // Align ou Row resolve o problema do width: double.infinity
              alignment: Alignment.centerLeft, 
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ModalCriarDocIA(
                      projetoId: widget.projeto.id!,
                      onSuccess: _carregarDocumentos,
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                label: const Text("Criar Documento com IA +"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),


          const SizedBox(height: 10),

          // Lista de Cards
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _documentos.isEmpty 
                ? Center(child: Text("Nenhum documento encontrado.", style: TextStyle(color: Colors.grey[400])))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    itemCount: _documentos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildDocCard(_documentos[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(dynamic doc) {
    // Configuração de cores baseada no tipo (Para ficar bonito igual o print)
    Color tagColorBg = Colors.grey.shade100;
    Color tagColorText = Colors.grey.shade700;
    String tipo = doc['tipo'] ?? 'Geral';

    if (tipo.contains('Arquitetura')) { tagColorBg = Colors.blue.shade50; tagColorText = Colors.blue; }
    else if (tipo.contains('Requisitos')) { tagColorBg = Colors.purple.shade50; tagColorText = Colors.purple; }
    else if (tipo.contains('API')) { tagColorBg = Colors.orange.shade50; tagColorText = Colors.orange; }
    else if (tipo.contains('Casos')) { tagColorBg = Colors.green.shade50; tagColorText = Colors.green; }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        // Sombra suave apenas embaixo
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone do Documento
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.description_outlined, color: Colors.black87, size: 24),
            ),
            const SizedBox(width: 16),
            
            // Conteúdo de Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          doc['nome_do_arquivo'] ?? 'Sem título', 
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1F2937)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tag Colorida
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: tagColorBg, borderRadius: BorderRadius.circular(4)),
                        child: Text(tipo, style: TextStyle(color: tagColorText, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      // Indica se o documento pode ser editado no app ou é
                      // um documento legado (só visível no Google Docs).
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: doc['tem_conteudo_editavel'] == true
                              ? const Color(0xFFEDE9FE)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          doc['tem_conteudo_editavel'] == true ? 'Editável' : 'Legado',
                          style: TextStyle(
                            color: doc['tem_conteudo_editavel'] == true
                                ? const Color(0xFF6D28D9)
                                : Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doc['descricao'] ?? "Documento técnico gerado pelo sistema.",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("IA Assistant", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_formatData(doc['data_criacao']), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  )
                ],
              ),
            ),

            // Botões de Ação
            Column(
              children: [
                // Botão Ver (Olho Azul)
                InkWell(
                  onTap: () => _abrirDocumento(doc),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.remove_red_eye_outlined, color: Colors.blue.shade600, size: 20),
                  ),
                ),
                // Botão Excluir (Lixeira Verde -> Vermelha no hover, mas aqui deixamos vermelha ou verde conforme seu gosto)
                InkWell(
                  onTap: () => _deletarDocumento(int.parse(doc['id'].toString())),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    // Usei vermelho para indicar exclusão, mas no seu print era verde o download. Se preferir verde, mude Colors.red
                    child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20), 
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatData(String? isoDate) {
    if (isoDate == null) return "-";
    try {
      return isoDate.split('T')[0].split('-').reversed.join('/');
    } catch (e) {
      return isoDate;
    }
  }
}