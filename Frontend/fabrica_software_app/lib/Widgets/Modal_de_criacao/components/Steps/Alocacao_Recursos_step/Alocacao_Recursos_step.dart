import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Modal_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Configuracao_Inicial_Projeto_step/components.dart';
import 'package:fabrica_software_app/providers/modal_criacao_projeto_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/config/projeto_dto.dart';
import 'package:fabrica_software_app/services/api_service.dart';

class AlocacaoRecursosStep extends ModalStep {
  @override
  String get title => 'Alocação de Recursos';
  @override
  String get tabName => 'Equipe & Recursos';
  @override
  IconData get icon => FontAwesomeIcons.usersGear;
  @override
  List<Color> get cores => <Color>[Colors.teal, Colors.green];

  final GlobalKey<_AlocacaoContentState> _contentKey = GlobalKey();

  @override
  Widget buildBody(BuildContext context) => _AlocacaoContent(key: _contentKey);

  @override
  Widget buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => context.read<ModalCriacaoProjetoProvider>().previousIndex(),
                child: const Text('Voltar', style: TextStyle(color: Colors.black87)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                   // SÓ AVANÇA SE A VALIDAÇÃO PASSAR
                   if (_contentKey.currentState != null) {
                     if (_contentKey.currentState!.validar()) {
                       context.read<ModalCriacaoProjetoProvider>().nextIndex();
                     }
                   }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Row(children: const [Text('Próxima etapa'), SizedBox(width: 8), Icon(Icons.arrow_forward_ios, size: 12)]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlocacaoContent extends StatefulWidget {
  const _AlocacaoContent({super.key});
  @override
  State<_AlocacaoContent> createState() => _AlocacaoContentState();
}

class _AlocacaoContentState extends State<_AlocacaoContent> {
  List<dynamic> _listaContribuidoresDB = [];
  List<dynamic> _listaRecursosDB = [];
  dynamic _colaboradorSelecionado;
  dynamic _recursoSelecionado;
  final _cargoController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        ApiService.getContribuidores(),
        ApiService.getRecursos()
      ]);
      if (mounted) {
        setState(() {
          _listaContribuidoresDB = results[0];
          _listaRecursosDB = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- VALIDAÇÃO ---
  bool validar() {
    if (projetoDraft.equipe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione pelo menos um membro à Equipe do Projeto.')));
      return false;
    }
    return true;
  }

  void _adicionarColaborador() {
    if (_colaboradorSelecionado != null) {
      setState(() {
        bool existe = projetoDraft.equipe.any((e) => e['id'] == _colaboradorSelecionado['id']);
        if (!existe) {
          projetoDraft.equipe.add({
            'id': _colaboradorSelecionado['id'],
            'nome': _colaboradorSelecionado['nome'],
            'papel': _colaboradorSelecionado['cargo'] ?? 'N/A'
          });
        }
        _colaboradorSelecionado = null;
        _cargoController.clear();
      });
    }
  }

  void _adicionarRecurso() {
    if (_recursoSelecionado != null) {
      setState(() {
         bool existe = projetoDraft.recursos.any((r) => r['id'] == _recursoSelecionado['id']);
         if (!existe) {
            projetoDraft.recursos.add({
              'id': _recursoSelecionado['id'],
              'nome': _recursoSelecionado['nome'],
              'tipo': _recursoSelecionado['tipo']
            });
         }
        _recursoSelecionado = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: const [Icon(Icons.people_outline, color: Colors.blue), SizedBox(width: 8), Text("Equipe do Projeto (Obrigatório)", style: TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<dynamic>(
                    hint: const Text("Colaborador", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    value: _colaboradorSelecionado,
                    isExpanded: true,
                    items: _listaContribuidoresDB.map((c) => DropdownMenuItem(value: c, child: Text(c['nome']))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _colaboradorSelecionado = val;
                        _cargoController.text = val['cargo'] ?? 'Sem cargo';
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration.copyWith(color: Colors.grey[100]),
                child: TextField(controller: _cargoController, enabled: false, decoration: ComponentsConfiguracaoInicalProjeto.inputDecoration("Cargo"), style: TextStyle(color: Colors.grey[700])),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _adicionarColaborador,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64B5F6), foregroundColor: Colors.white),
              child: const Icon(Icons.add),
            )
          ],
        ),

        if (projetoDraft.equipe.isNotEmpty)
           ...projetoDraft.equipe.map((c) => ListTile(
            dense: true,
            leading: CircleAvatar(child: Text(c['nome'][0]), radius: 14),
            title: Text(c['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(c['papel']),
            trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 18), onPressed: (){
               setState(() => projetoDraft.equipe.remove(c));
            }),
           )).toList(),

        const Divider(height: 40),

        Row(children: const [Icon(Icons.inventory_2_outlined, color: Colors.teal), SizedBox(width: 8), Text("Recursos (Opcional)", style: TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 16),
        Row(
          children: [
             Expanded(
              child: Container(
                decoration: ComponentsConfiguracaoInicalProjeto.inputBoxDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<dynamic>(
                    hint: const Text("Selecione Recurso", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    value: _recursoSelecionado,
                    isExpanded: true,
                    items: _listaRecursosDB.map((r) => DropdownMenuItem(value: r, child: Text(r['nome']))).toList(),
                    onChanged: (val) => setState(() => _recursoSelecionado = val),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
               onPressed: _adicionarRecurso,
               style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64B5F6), foregroundColor: Colors.white),
               child: const Icon(Icons.add),
            )
          ],
        ),
        const SizedBox(height: 10),
        if (projetoDraft.recursos.isNotEmpty)
           Wrap(
             spacing: 8,
             children: projetoDraft.recursos.map((r) => Chip(
               label: Text(r['nome']),
               backgroundColor: Colors.teal[50],
               deleteIcon: const Icon(Icons.close, size: 14),
               onDeleted: () => setState(() => projetoDraft.recursos.remove(r)),
             )).toList(),
           ),
      ],
    );
  }
}