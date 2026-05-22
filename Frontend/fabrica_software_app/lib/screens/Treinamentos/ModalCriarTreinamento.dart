import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fabrica_software_app/config/api_config.dart';
import 'package:fabrica_software_app/services/auth_service.dart';

class ModalCriarTreinamento extends StatefulWidget {
  final int projetoId;
  final VoidCallback onSuccess;
  final Map<String, dynamic>? treinamentoEdicao; // Novo parâmetro opcional

  const ModalCriarTreinamento({
    super.key, 
    required this.projetoId, 
    required this.onSuccess,
    this.treinamentoEdicao, // Pode ser nulo (modo criação)
  });

  @override
  State<ModalCriarTreinamento> createState() => _ModalCriarTreinamentoState();
}

class _ModalCriarTreinamentoState extends State<ModalCriarTreinamento> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _instrutorCtrl = TextEditingController();
  final _cargaHorariaCtrl = TextEditingController();
  final _dataInicioCtrl = TextEditingController();
  final _dataTerminoCtrl = TextEditingController();
  
  // Variáveis de Estado
  String _tipoSelecionado = 'Técnico';
  bool _isLoading = false;
  DateTime? _dataInicio;
  DateTime? _dataTermino;

  final List<String> _tipos = ['Técnico', 'Comportamental', 'Gestão', 'Processos', 'Outros'];

  @override
  void initState() {
    super.initState();
    // Se veio dados para edição, preenche os campos
    if (widget.treinamentoEdicao != null) {
      final t = widget.treinamentoEdicao!;
      _nomeCtrl.text = t['nome'] ?? '';
      _descricaoCtrl.text = t['descricao'] ?? '';
      _instrutorCtrl.text = t['instrutor'] ?? '';
      _cargaHorariaCtrl.text = t['duracao_horas']?.toString() ?? '';
      
      // Ajusta Tipo (Garante que está na lista, senão default)
      if (_tipos.contains(t['tipo_treinamento'])) {
        _tipoSelecionado = t['tipo_treinamento'];
      }

      // Ajusta Datas
      if (t['data_inicio'] != null) {
        _dataInicio = DateTime.parse(t['data_inicio']);
        _dataInicioCtrl.text = DateFormat('dd/MM/yyyy').format(_dataInicio!);
      }
      if (t['data_termino'] != null) {
        _dataTermino = DateTime.parse(t['data_termino']);
        _dataTerminoCtrl.text = DateFormat('dd/MM/yyyy').format(_dataTermino!);
      }
    }
  }

  // Função de Salvar (Cria ou Edita)
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await AuthService.instance.token;
      final bool isEdicao = widget.treinamentoEdicao != null;
      
      final body = jsonEncode({
        "projeto_id": widget.projetoId,
        "nome": _nomeCtrl.text,
        "descricao": _descricaoCtrl.text,
        "instrutor": _instrutorCtrl.text,
        "tipo_treinamento": _tipoSelecionado,
        "duracao_horas": int.tryParse(_cargaHorariaCtrl.text) ?? 0,
        "data_inicio": _dataInicio?.toIso8601String(),
        "data_termino": _dataTermino?.toIso8601String(),
        // Em edição, mantemos o documento como está, ou null se for novo (backend trata)
        "documento_id": isEdicao ? widget.treinamentoEdicao!['documento_id'] : null 
      });

      http.Response response;

      if (isEdicao) {
        // MODO EDIÇÃO (PUT)
        final id = widget.treinamentoEdicao!['id'];
        response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/treinamentos/$id'),
          headers: ApiConfig.getAuthHeaders(token),
          body: body,
        );
      } else {
        // MODO CRIAÇÃO (POST)
        response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/treinamentos'),
          headers: ApiConfig.getAuthHeaders(token),
          body: body,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEdicao ? "Treinamento atualizado!" : "Treinamento criado!"), backgroundColor: Colors.green)
          );
        }
      } else {
        throw Exception("Erro no backend: ${response.body}");
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

  Future<void> _selecionarData(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? (_dataInicio ?? DateTime.now()) : (_dataTermino ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(primaryColor: const Color(0xFF2563EB)), child: child!),
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
          _dataInicioCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
        } else {
          _dataTermino = picked;
          _dataTerminoCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.treinamentoEdicao != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEdicao ? "Editar Treinamento" : "Novo Treinamento", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey))
                  ],
                ),
                const Divider(height: 30),

                Row(
                  children: [
                    Expanded(child: _buildTextField("Nome do Treinamento", _nomeCtrl, icon: Icons.title)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdown()),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(child: _buildTextField("Instrutor", _instrutorCtrl, icon: Icons.person)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField("Carga Horária (h)", _cargaHorariaCtrl, icon: Icons.timer, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildDatePicker("Data Início", _dataInicioCtrl, () => _selecionarData(true))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDatePicker("Data Término", _dataTerminoCtrl, () => _selecionarData(false))),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField("Descrição", _descricaoCtrl, maxLines: 3),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _salvar,
                      icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : Icon(isEdicao ? Icons.save : Icons.check, size: 18),
                      label: Text(_isLoading ? "Salvando..." : (isEdicao ? "Salvar Alterações" : "Criar Treinamento")),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {IconData? icon, bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildDatePicker(String label, TextEditingController ctrl, VoidCallback onTap) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: onTap,
      validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _tipoSelecionado,
      items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _tipoSelecionado = v!),
      decoration: InputDecoration(
        labelText: "Tipo",
        prefixIcon: const Icon(Icons.category, size: 20, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}