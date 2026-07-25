import 'package:flutter/foundation.dart';

// Resolve qual seção deve ganhar o contorno amarelo de hover no editor de
// documentos, respeitando a hierarquia (Título 1 contorna toda a sua árvore,
// um Título 2 aninhado contorna só a dele).
//
// Por que não um simples "último onEnter vence": como os limites de uma
// seção-pai sempre contêm os da seção-filha, passar o mouse sobre um filho
// profundo dispara onEnter em TODOS os ancestrais também, numa ordem que o
// Flutter não garante. Em vez de lutar contra isso, guardamos o CONJUNTO de
// seções atualmente sob o cursor (adicionar/remover num Set é comutativo -
// não importa a ordem dos eventos) e resolvemos de forma determinística:
// vence a seção de maior profundidade estrutural (não o "nivel", que o
// usuário pode editar livremente e não reflete a posição real na árvore).
class SecaoHoverProvider extends ChangeNotifier {
  final Set<int> _hoveredIds = {};
  Map<int, int> _profundidadePorId = {};

  // Chamado pelo dono da árvore sempre que a estrutura muda (add/remove
  // seção), para manter a resolução de profundidade atualizada.
  void atualizarProfundidades(Map<int, int> profundidades) {
    _profundidadePorId = profundidades;
  }

  void setHover(int localId, bool hovering) {
    final mudou = hovering ? _hoveredIds.add(localId) : _hoveredIds.remove(localId);
    if (mudou) notifyListeners();
  }

  void limpar() {
    if (_hoveredIds.isNotEmpty) {
      _hoveredIds.clear();
      notifyListeners();
    }
  }

  int? get deepestHoveredId {
    if (_hoveredIds.isEmpty) return null;

    int? melhorId;
    var melhorProfundidade = -1;
    for (final id in _hoveredIds) {
      final profundidade = _profundidadePorId[id] ?? 0;
      if (profundidade > melhorProfundidade) {
        melhorProfundidade = profundidade;
        melhorId = id;
      }
    }
    return melhorId;
  }

  bool isDeepestHovered(int localId) => deepestHoveredId == localId;
}
