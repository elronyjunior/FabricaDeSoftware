import 'package:flutter/material.dart';
import 'package:fabrica_software_app/models/revisao_documento.dart';
import 'package:fabrica_software_app/screens/Documento/components/Secao_Widget.dart' show estiloTituloSecao;

const corFundoAlteracao = Color(0xFFFFF3E0); // laranja bem leve — novo/modificado
const corFundoRemovido = Color(0xFFFDECEA); // vermelho bem leve — removido
const corTextoRemovido = Color(0xFFB3261E);

// Renderização somente-leitura da árvore de revisão ("Ver Alterações"):
// seções novas/modificadas ganham fundo laranja leve, seções removidas
// reaparecem com fundo vermelho leve e texto riscado (mostrando o conteúdo
// original, inclusive toda a subárvore removida junto).
class SecaoRevisaoWidget extends StatelessWidget {
  final NoRevisao no;

  const SecaoRevisaoWidget({super.key, required this.no});

  bool get _removido => no.status == StatusRevisao.removido;
  bool get _alterado => no.status == StatusRevisao.novo || no.status == StatusRevisao.modificado;

  @override
  Widget build(BuildContext context) {
    final corFundo = _removido
        ? corFundoRemovido
        : (_alterado ? corFundoAlteracao : Colors.transparent);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: corFundo, borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: EdgeInsets.only(left: (no.depth * 16).toDouble()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitulo(),
            if (no.conteudo.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildTexto(no.conteudo),
            ],
            if (no.itens.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildItens(),
            ],
            for (final sub in no.subsecoes) SecaoRevisaoWidget(no: sub),
          ],
        ),
      ),
    );
  }

  Widget _buildTitulo() {
    final estilo = estiloTituloSecao(no.nivel);
    return Text(
      no.titulo.isEmpty ? 'Sem título' : no.titulo,
      style: estilo.copyWith(
        color: _removido ? corTextoRemovido : estilo.color,
        decoration: _removido ? TextDecoration.lineThrough : null,
      ),
    );
  }

  Widget _buildTexto(String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: _removido ? corTextoRemovido : null,
        decoration: _removido ? TextDecoration.lineThrough : null,
      ),
    );
  }

  Widget _buildItens() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: no.itens.map((item) {
        final removido = item.status == StatusRevisao.removido;
        final novo = item.status == StatusRevisao.novo;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 2),
          padding: novo ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1) : EdgeInsets.zero,
          decoration: novo
              ? BoxDecoration(color: corFundoAlteracao, borderRadius: BorderRadius.circular(4))
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Text(
                  item.texto,
                  style: TextStyle(
                    fontSize: 13,
                    color: removido ? corTextoRemovido : null,
                    decoration: removido ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
