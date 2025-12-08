import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ClienteRow extends StatelessWidget {
  final String razaoSocial;
  final String CNPJ;
  final String setor;
  final String contato;

  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ClienteRow({
    super.key,
    required this.CNPJ,
    required this.contato,
    required this.razaoSocial,
    required this.setor,
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
          
          // FLEX 3: Razão Social (Avatar + Texto)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    pegarIniciais(razaoSocial),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    razaoSocial, 
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // FLEX 2: CNPJ
          Expanded(
            flex: 2, 
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(CNPJ, overflow: TextOverflow.ellipsis),
            ),
          ),
          
          // FLEX 1: Setor (Badge Centralizado)
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 51, 243, 33).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  setor, 
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
          
          // FLEX 2: Contato (Com padding leve na esquerda)
          Expanded(
            flex: 2, 
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(contato, overflow: TextOverflow.ellipsis),
            ),
          ),
          
          // FLEX 1: Projetos (Centralizado)
          const Expanded(
            flex: 1, 
            child: Center(child: Text('1 Projeto(s)')),
          ),
          
          // FLEX 1: Ações (Alinhado à Direita)
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Empurra para a direita
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
    if (nome.isEmpty) return "?";
    nome = nome.trim();
    var partes = nome.split(RegExp(r'\s+'));
    if (partes.length == 1) {
      return partes[0][0].toUpperCase();
    }
    String primeira = partes.first[0].toUpperCase();
    String ultima = partes.last[0].toUpperCase();
    return '$primeira$ultima';
  }
}

// Componente auxiliar para padronizar os botões de ação
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
        child: FaIcon(icon, size: 18, color: color), // Ícone levemente menor (18)
      ),
    );
  }
}