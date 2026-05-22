import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fabrica_software_app/services/documento_service.dart';

class ModalCriarDocIA extends StatefulWidget {
  final int projetoId;
  final VoidCallback onSuccess; // Para atualizar a lista depois

  const ModalCriarDocIA({super.key, required this.projetoId, required this.onSuccess});

  @override
  State<ModalCriarDocIA> createState() => _ModalCriarDocIAState();
}

class _ModalCriarDocIAState extends State<ModalCriarDocIA> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _service = DocumentoService();
  
  String? _tipoSelecionado;
  bool _isLoading = false;

  // Lista de Opções igual ao seu print
  final List<Map<String, dynamic>> _tipos = [
    {'label': 'Arquitetura', 'icon': Icons.layers, 'color': Colors.blue},
    {'label': 'Requisitos', 'icon': Icons.description, 'color': Colors.purple},
    {'label': 'Casos de Uso', 'icon': Icons.book, 'color': Colors.green},
    {'label': 'API', 'icon': Icons.code, 'color': Colors.orange},
    {'label': 'Modelagem', 'icon': Icons.storage, 'color': Colors.pink},
    {'label': 'Testes', 'icon': Icons.bug_report, 'color': Colors.red},
    {'label': 'Código', 'icon': Icons.javascript, 'color': Colors.indigo},
  ];

  Future<void> _gerar() async {
    if (_tipoSelecionado == null || _tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione um tipo e preencha o título"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.gerarDocumentoIA(
        projetoId: widget.projetoId,
        tipo: _tipoSelecionado!,
        titulo: _tituloController.text,
        descricao: _descricaoController.text,
      );

      if (mounted) {
        Navigator.pop(context); // Fecha o modal
        widget.onSuccess(); // Atualiza a tela de trás
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Documento criado com sucesso!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600, // Largura fixa para ficar bonito no Desktop
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho
              Row(
                children: [
                  const Icon(FontAwesomeIcons.wandMagicSparkles, color: Color(0xFF8B5CF6)), // Roxo IA
                  const SizedBox(width: 10),
                  const Text("Criar Documento com IA", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                ],
              ),
              const Divider(height: 30),

              // Seção 1: Tipo
              const Text("Tipo de Documento", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _tipos.map((tipo) => _buildTypeCard(tipo)).toList(),
              ),
              
              const SizedBox(height: 24),

              // Seção 2: Título
              const Text("Título do Documento", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  hintText: "Ex: Documento de Arquitetura do Sistema ERP",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),

              const SizedBox(height: 24),

              // Seção 3: Descrição
              const Text("Descrição (Opcional) - Dê dicas para a IA", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Descreva o que você espera neste documento...",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              // Botões
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _gerar,
                    icon: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(FontAwesomeIcons.wandMagicSparkles, size: 16),
                    label: Text(_isLoading ? "Gerando..." : "Gerar Documento"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6), // Roxo do print
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(Map<String, dynamic> item) {
    final isSelected = _tipoSelecionado == item['label'];
    return InkWell(
      onTap: () => setState(() => _tipoSelecionado = item['label']),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 130, // Tamanho do card
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? item['color'].withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? item['color'] : Colors.grey.shade300,
            width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(item['icon'], color: isSelected ? item['color'] : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              item['label'], 
              style: TextStyle(
                color: isSelected ? item['color'] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}