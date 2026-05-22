import 'package:flutter/material.dart';

// Steps de Criação (Wizard Completo)
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Modal_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Configuracao_Inicial_Projeto_step/Configuracao_Inicial_Projeto_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Levantamentos_Requisitos_step/Levantamentos_Requisitos_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Alocacao_Recursos_step/Alocacao_Recursos_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Planejamento_Orcamento_step/Planejamento_Orcamento_step.dart';

// Step de Edição (Somente Info Básica)
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Edicao_Projeto_step/EdicaoProjetoStep.dart';

class ModalCriacaoProjetoProvider with ChangeNotifier {
  int _indice = 0;
  
  // Lista 1: Criação Completa (Passo a Passo)
  final List<ModalStep> _stepsCriacao = [
    ConfiguracaoInicialProjetoStep(),
    LevantamentosRequisitosStep(),
    AlocacaoRecursosStep(),
    PlanejamentoOrcamentoStep(),
  ];

  // Lista 2: Edição (Apenas um passo simples)
  final List<ModalStep> _stepsEdicao = [
    EdicaoProjetoStep(),
  ];

  // Lista que será renderizada no momento
  List<ModalStep> _listaAtiva = [];

  ModalCriacaoProjetoProvider() {
    // Padrão: Modo Criação
    _listaAtiva = _stepsCriacao;
  }

  // --- MÉTODOS DE CONTROLE ---

  // Chamado pelo botão "Novo Projeto"
  void iniciarCriacao() {
    _listaAtiva = _stepsCriacao;
    _indice = 0;
    // notifyListeners(); // (Opcional se instanciar novo provider)
  }

  // Chamado pelo botão "Editar"
  void iniciarEdicao() {
    _listaAtiva = _stepsEdicao;
    _indice = 0;
    // notifyListeners();
  }

  // --- GETTERS PARA A UI ---

  Widget returnBody(BuildContext context) {
    return _listaAtiva[_indice].buildBody(context);
  }

  Widget returnFooter(BuildContext context) {
    return _listaAtiva[_indice].buildFooter(context);
  }

  String returnTitle() => _listaAtiva[_indice].title;
  String returnTabName() => _listaAtiva[_indice].tabName;
  IconData returnIcon() => _listaAtiva[_indice].icon;
  List<Color> returnColors() => _listaAtiva[_indice].cores;

  double returnPercentNumber() {
    // Se for edição, barra cheia (100%) ou escondida
    if (_listaAtiva == _stepsEdicao) return 1.0; 
    return (_indice + 1) / _listaAtiva.length;
  }

  void nextIndex() {
    if (_indice < _listaAtiva.length - 1) {
      _indice += 1;
      notifyListeners();
    }
  }

  void previousIndex() {
    if (_indice > 0) {
      _indice -= 1;
      notifyListeners();
    }
  }
}