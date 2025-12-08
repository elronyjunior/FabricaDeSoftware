import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TecnologiaRow extends StatelessWidget {
  final String nome;
  final String categoria;
  final String descricao;

  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TecnologiaRow({
    super.key,
    required this.nome,
    required this.categoria,
    required this.descricao,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // FLEX 3: Nome + Avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    pegarIniciais(nome),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nome,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // FLEX 2: Categoria (Badge)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  categoria,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // FLEX 4: Descrição
          Expanded(
            flex: 4,
            child: Text(
              descricao,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // FLEX 2: Ações
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(icon: FontAwesomeIcons.solidEye, onTap: onView, color: Colors.black54),
                const SizedBox(width: 8),
                _ActionButton(icon: FontAwesomeIcons.solidPenToSquare, onTap: onEdit, color: Colors.black54),
                const SizedBox(width: 8),
                _ActionButton(icon: FontAwesomeIcons.trash, onTap: onDelete, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String pegarIniciais(String nome) {
    nome = nome.trim();
    if (nome.isEmpty) return '?';
    var partes = nome.split(RegExp(r'\s+'));
    if (partes.length == 1) {
      return partes[0][0].toUpperCase();
    }
    String primeira = partes.first[0].toUpperCase();
    String ultima = partes.last[0].toUpperCase();
    return '$primeira$ultima';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({required this.icon, this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FaIcon(icon, size: 18, color: color),
      ),
    );
  }
}