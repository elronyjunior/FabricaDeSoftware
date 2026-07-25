import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fabrica_software_app/services/documento_service.dart';

const _corPrimaria = Color(0xFF8B5CF6);

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
  String _statusLabel = "Gerando...";
  String? _estagioAtual;
  double _progresso = 0.0;
  Timer? _progressoTimer;

  final List<Map<String, dynamic>> _tipos = [
    {'label': 'Arquitetura', 'icon': Icons.layers, 'color': Colors.blue},
    {'label': 'Requisitos', 'icon': Icons.description, 'color': Colors.purple},
    {'label': 'Casos de Uso', 'icon': Icons.book, 'color': Colors.green},
    {'label': 'API', 'icon': Icons.code, 'color': Colors.orange},
    {'label': 'Modelagem', 'icon': Icons.storage, 'color': Colors.pink},
    {'label': 'Testes', 'icon': Icons.bug_report, 'color': Colors.red},
    {'label': 'Código', 'icon': Icons.javascript, 'color': Colors.indigo},
  ];

  @override
  void dispose() {
    _progressoTimer?.cancel();
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _gerar() async {
    if (_tipoSelecionado == null || _tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione um tipo e preencha o título"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusLabel = "Iniciando...";
      _estagioAtual = null;
      _progresso = 0.05;
    });

    try {
      await _service.gerarDocumentoIA(
        projetoId: widget.projetoId,
        tipo: _tipoSelecionado!,
        titulo: _tituloController.text,
        descricao: _descricaoController.text,
        onStatusUpdate: (stage) {
          if (!mounted) return;
          setState(() {
            _statusLabel = _traduzirEstagio(stage);
            if (stage != _estagioAtual) {
              _estagioAtual = stage;
              _progresso = _progressoBase(stage);
              _iniciarProgressoSuave(stage);
            }
          });
        },
      );

      _progressoTimer?.cancel();
      if (mounted) {
        setState(() {
          _statusLabel = "Concluído!";
          _progresso = 1.0;
        });
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (mounted) {
        Navigator.pop(context); // Fecha o modal
        widget.onSuccess(); // Atualiza a tela de trás
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Documento criado com sucesso!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      _progressoTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      _progressoTimer?.cancel();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _progressoBase(String stage) {
    switch (stage) {
      case 'buscando_dados_do_projeto':
        return 0.12;
      case 'gerando_conteudo_com_ia':
        return 0.30;
      case 'criando_documento_no_google_docs':
        return 0.82;
      default:
        return _progresso;
    }
  }

  // Enquanto uma etapa demorada está em andamento (sem progresso real do
  // backend byte-a-byte), anima a barra suavemente em direção a um teto,
  // desacelerando perto dele — evita a sensação de "travado".
  void _iniciarProgressoSuave(String stage) {
    _progressoTimer?.cancel();
    final teto = switch (stage) {
      'gerando_conteudo_com_ia' => 0.75,
      'criando_documento_no_google_docs' => 0.97,
      _ => _progresso,
    };

    if (teto <= _progresso) return;

    _progressoTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progresso += (teto - _progresso) * 0.06;
      });
    });
  }

  String _traduzirEstagio(String stage) {
    switch (stage) {
      case 'buscando_dados_do_projeto':
        return 'Buscando dados do projeto...';
      case 'gerando_conteudo_com_ia':
        return 'Gerando conteúdo com IA...';
      case 'criando_documento_no_google_docs':
        return 'Criando documento no Google Docs...';
      default:
        return 'Gerando...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCabecalho(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: AnimatedOpacity(
                  opacity: _isLoading ? 0.45 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _isLoading,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLabel("Tipo de Documento"),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _tipos.map((tipo) => _buildTypeCard(tipo)).toList(),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel("Título do Documento"),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _tituloController,
                          decoration: _inputDecoration(
                            hintText: "Ex: Documento de Arquitetura do Sistema ERP",
                            icon: Icons.title_rounded,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel("Descrição (Opcional) — Dê dicas para a IA"),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descricaoController,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            hintText: "Descreva o que você espera neste documento...",
                            icon: Icons.notes_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildRodape(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13),
    );
  }

  InputDecoration _inputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
      filled: true,
      fillColor: const Color(0xFFF7F7FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _corPrimaria, width: 1.6),
      ),
    );
  }

  Widget _buildCabecalho() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
      decoration: BoxDecoration(
        color: _corPrimaria.withOpacity(0.06),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(bottom: BorderSide(color: _corPrimaria.withOpacity(0.12))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _corPrimaria.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(FontAwesomeIcons.wandMagicSparkles, color: _corPrimaria, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Criar Documento com IA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text(
                  "A IA gera o conteúdo e monta o Google Doc automaticamente",
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildRodape() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading) ...[
            _buildBarraDeProgresso(),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _gerar,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(FontAwesomeIcons.wandMagicSparkles, size: 16),
                label: Text(_isLoading ? "Gerando..." : "Gerar Documento"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _corPrimaria,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _corPrimaria.withOpacity(0.6),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarraDeProgresso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _statusLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "${(_progresso.clamp(0, 1) * 100).round()}%",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _corPrimaria),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progresso.clamp(0, 1)),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: _corPrimaria.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(_corPrimaria),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(Map<String, dynamic> item) {
    final isSelected = _tipoSelecionado == item['label'];
    return InkWell(
      onTap: () => setState(() => _tipoSelecionado = item['label']),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? item['color'].withOpacity(0.1) : const Color(0xFFF7F7FB),
          border: Border.all(
            color: isSelected ? item['color'] : Colors.grey.shade300,
            width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(10),
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
