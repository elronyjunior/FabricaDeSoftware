import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Modal_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Configuracao_Inicial_Projeto_step/Configuracao_Inicial_Projeto_step.dart';
import 'package:fabrica_software_app/Widgets/Modal_de_criacao/components/Steps/Levantamentos_Requisitos_step/Levantamentos_Requisitos_step.dart';
import 'package:flutter/material.dart';

class ModalCriacaoProjetoProvider with ChangeNotifier {
int _indice=0;
final List<ModalStep> _lista= <ModalStep>[
 ConfiguracaoInicialProjetoStep(),
 LevantamentosRequisitosStep(),
];

Widget returnBody(BuildContext context){
  return _lista[_indice].buildBody(context);
}

List<Color> returnColors(){
  List<Color> coresAtuais=_lista[_indice].cores;
  if(_lista[_indice].cores.length==1){
    coresAtuais.add(_lista[_indice].cores[0]);
  }
  return coresAtuais;
}

Widget returnFooter(BuildContext context){
  return _lista[_indice].buildFooter(context);
}

String returnTitle(){
  return _lista[_indice].title;
}

String returnTabName(){
  return _lista[_indice].tabName;
}

IconData returnIcon(){
  return _lista[_indice].icon;
}

double returnPercentNumber(){
  return (_indice + 1)/_lista.length;
}

void nextIndex(){
  if(_indice==_lista.length-1){
    return;
  
  }else{
    _indice+=1;
    notifyListeners();
  }
}

void  previousIndex(){
  if(_indice==0){
    return;
  }
  else{
    _indice-=1;
    notifyListeners();
  }
}






}