import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Modal_step.dart';
import 'package:fabrica_software_app/providers/modal_criacao_projeto_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'components.dart'; 
import 'package:fabrica_software_app/config/projeto_dto.dart';
import 'package:fabrica_software_app/services/api_service.dart';

class ConfiguracaoInicialProjetoStep extends ModalStep {
  @override
  String get title => 'Configuração inicial do projeto';

  @override
  String get tabName => 'Informações Gerais';

  @override
  IconData get icon => FontAwesomeIcons.gears;

  @override
  List<Color> get cores => <Color>[const Color.fromARGB(255, 4, 187, 233)];

  final GlobalKey<_ConfiguracaoContentState> _contentKey = GlobalKey();

  @override
  Widget buildBody(BuildContext context) {
    return _ConfiguracaoContent(key: _contentKey);
  }

  @override
  Widget buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              if (_contentKey.currentState != null) {
                if (_contentKey.currentState!.validar()) {
                  context.read<ModalCriacaoProjetoProvider>().nextIndex();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
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

class _ConfiguracaoContent extends StatefulWidget {
  const _ConfiguracaoContent({super.key});

  @override
  State<_ConfiguracaoContent> createState() => _ConfiguracaoContentState();
}

class _ConfiguracaoContentState extends State<_ConfiguracaoContent> {
  final _formKey = GlobalKey<FormState>();
  
  // Inicializamos os controllers já com os dados do DTO para garantir que apareçam
  late TextEditingController _nomeCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _metodologiaCtrl;
  
  List<dynamic> _listaClientesDB = [];
  List<dynamic> _listaTecnologiasDB = [];

  Map<String, dynamic>? _clienteSelecionado;
  List<Map<String, dynamic>> _tecnologiasSelecionadas = [];
  
  String? _tipoSelecionado;
  final List<String> _opcoesTipo = ['Web', 'Mobile', 'Desktop', 'API', 'Híbrido', 'Outro'];

  String? _modeloSelecionado;
  final List<String> _opcoesModelo = ['SaaS', 'Marketplace', 'E-commerce', 'Institucional', 'Interno', 'Outros'];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // 1. Vínculo Imediato dos Dados Básicos (Evita delay visual)
    _nomeCtrl = TextEditingController(text: projetoDraft.nome ?? '');
    _descCtrl = TextEditingController(text: projetoDraft.descricao ?? '');
    _metodologiaCtrl = TextEditingController(text: projetoDraft.metodologia ?? ''); // <--- Aqui garante a Metodologia

    _carregarDadosAsync();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _metodologiaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosAsync() async {
    try {
      // Busca listas gerais
      final results = await Future.wait([
        ApiService.getClientes(),
        ApiService.getTecnologias()
      ]);

      List<int> idsTecnologiasDoProjeto = [];
      
      // Se for EDIÇÃO (tem ID), busca as tecnologias específicas desse projeto no banco
      if (projetoDraft.id != null) {
        idsTecnologiasDoProjeto = await ApiService.getTecnologiasDoProjeto(projetoDraft.id!);
      }

      if (mounted) {
        setState(() {
          _listaClientesDB = results[0];
          _listaTecnologiasDB = results[1];

          // 2. Configura Dropdowns (Tipo e Modelo)
          if (projetoDraft.tipo != null) {
             _tipoSelecionado = _encontrarOpcao(projetoDraft.tipo!, _opcoesTipo);
          }
          if (projetoDraft.modelo != null) {
             _modeloSelecionado = _encontrarOpcao(projetoDraft.modelo!, _opcoesModelo);
          }

          // 3. Configura Cliente
          if (projetoDraft.cliente != null && projetoDraft.cliente!['id'] != null) {
            try {
              final idDraft = projetoDraft.cliente!['id'].toString();
              _clienteSelecionado = _listaClientesDB.firstWhere(
                (c) => c['id'].toString() == idDraft,
                orElse: () => null
              );
              // Atualiza o DTO para garantir consistência
              if (_clienteSelecionado != null) projetoDraft.cliente = _clienteSelecionado;
            } catch (_) {}
          }

          // 4. Configura Tecnologias (A Mágica da Edição)
          if (projetoDraft.id != null && idsTecnologiasDoProjeto.isNotEmpty) {
            // Filtra da lista geral apenas as que o projeto tem
            _tecnologiasSelecionadas = _listaTecnologiasDB
                .where((tech) => idsTecnologiasDoProjeto.contains(tech['id']))
                .map((e) => Map<String, dynamic>.from(e)) // Cria cópia segura
                .toList();
            
            // Salva no DTO para persistir
            projetoDraft.tecnologias = _tecnologiasSelecionadas;
          } 
          // Se for CRIAÇÃO ou já tiver tecnologias no draft (navegação entre abas)
          else if (projetoDraft.tecnologias.isNotEmpty) {
            _tecnologiasSelecionadas = List.from(projetoDraft.tecnologias);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro no carregamento: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _encontrarOpcao(String valor, List<String> lista) {
    try {
      return lista.firstWhere(
        (e) => e.toUpperCase() == valor.toUpperCase(),
        orElse: () => lista.first
      );
    } catch (_) { return null; }
  }

  bool validar() {
    if (_nomeCtrl.text.trim().isEmpty) {
      _showError('O Nome do projeto é obrigatório.');
      return false;
    }
    if (_tipoSelecionado == null) {
      _showError('Selecione o Tipo do projeto.');
      return false;
    }
    if (_clienteSelecionado == null) {
      _showError('Selecione um Cliente.');
      return false;
    }
    // Salvamento final
    projetoDraft.nome = _nomeCtrl.text;
    projetoDraft.metodologia = _metodologiaCtrl.text; // Garante salvar metodologia
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red)
    );
  }

  void _abrirSelecaoTecnologias() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Selecionar Tecnologias"),
          content: SizedBox(
            width: double.maxFinite,
            child: _listaTecnologiasDB.isEmpty 
              ? const Text("Nenhuma tecnologia cadastrada.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _listaTecnologiasDB.length,
                  itemBuilder: (ctx, i) {
                    final tech = _listaTecnologiasDB[i];
                    final isSelected = _tecnologiasSelecionadas.any((t) => t['id'] == tech['id']);
                    
                    return CheckboxListTile(
                      title: Text(tech['nome']),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            if (!_tecnologiasSelecionadas.any((t) => t['id'] == tech['id'])) {
                              _tecnologiasSelecionadas.add(tech);
                            }
                          } else {
                            _tecnologiasSelecionadas.removeWhere((t) => t['id'] == tech['id']);
                          }
                          projetoDraft.tecnologias = _tecnologiasSelecionadas;
                        });
                        (ctx as Element).markNeedsBuild();
                      },
                    );
                  },
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Concluir"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ... (Header visual igual)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Color(0xFF2962FF), size: 20),
                SizedBox(width: 10),
                Text("Informações Gerais", style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. NOME
          ComponentsConfiguracaoInicalProjeto.buildLabel("Nome do projeto", isRequired: true),
          Container(
            decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
            child: TextFormField(
              controller: _nomeCtrl,
              decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Ex: Sistema de Gestão ERP"),
              onChanged: (val) => projetoDraft.nome = val,
            ),
          ),
          const SizedBox(height: 16),

          // 2. TIPO E MODELO
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ComponentsConfiguracaoInicalProjeto.buildLabel("Tipo", isRequired: true),
                    Container(
                      decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          hint: const Text("Selecione", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          value: _tipoSelecionado,
                          isExpanded: true,
                          items: _opcoesTipo.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) {
                            setState(() {
                              _tipoSelecionado = val;
                              projetoDraft.tipo = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ComponentsConfiguracaoInicalProjeto.buildLabel("Modelo", isRequired: true),
                    Container(
                      decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          hint: const Text("Selecione", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          value: _modeloSelecionado,
                          isExpanded: true,
                          items: _opcoesModelo.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (val) {
                            setState(() {
                              _modeloSelecionado = val;
                              projetoDraft.modelo = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // 3. DESCRIÇÃO
          ComponentsConfiguracaoInicalProjeto.buildLabel("Descrição"),
          Container(
            decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
            child: TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Descreva o objetivo..."),
              onChanged: (val) => projetoDraft.descricao = val,
            ),
          ),
          const SizedBox(height: 16),

          // 4. CLIENTE E METODOLOGIA
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ComponentsConfiguracaoInicalProjeto.buildLabel("Cliente", isRequired: true),
                    Container(
                      decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          hint: const Text("Selecione...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          value: _clienteSelecionado,
                          isExpanded: true,
                          items: _listaClientesDB.map((c) {
                            return DropdownMenuItem<dynamic>(
                              value: c, 
                              child: Text(c['razao_social'] ?? 'Sem Nome', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _clienteSelecionado = val;
                              projetoDraft.cliente = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ComponentsConfiguracaoInicalProjeto.buildLabel("Metodologia"),
                    Container(
                      decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                      child: TextFormField(
                        controller: _metodologiaCtrl,
                        decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Ex: Scrum"),
                        onChanged: (val) => projetoDraft.metodologia = val,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. TECNOLOGIAS (Multi-Select)
          ComponentsConfiguracaoInicalProjeto.buildLabel("Tecnologias Utilizadas", isRequired: true),
          GestureDetector(
            onTap: _abrirSelecaoTecnologias,
            child: Container(
              constraints: const BoxConstraints(minHeight: 50),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
              child: _tecnologiasSelecionadas.isEmpty
                  ? const Text("Toque para selecionar...", style: TextStyle(color: Colors.grey, fontSize: 13))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _tecnologiasSelecionadas.map((t) => Chip(
                        label: Text(t['nome'], style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.blue[50],
                        deleteIcon: const Icon(Icons.close, size: 12, color: Colors.blue),
                        onDeleted: () {
                           setState(() {
                             _tecnologiasSelecionadas.removeWhere((item) => item['id'] == t['id']);
                             projetoDraft.tecnologias = _tecnologiasSelecionadas;
                           });
                        },
                      )).toList(),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}