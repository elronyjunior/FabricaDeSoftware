import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UsuarioRow extends StatelessWidget {
  final String nome;
  final String email;
  final String nivel;
  final String telefone;

  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const UsuarioRow({
    super.key,
    required this.nome,
    required this.email,
    required this.nivel,
    required this.telefone,
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
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  child: Text(
                    pegarIniciais(nome),
                    style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12),
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
          
          // FLEX 3: Email
          Expanded(
            flex: 3, 
            child: Text(email, overflow: TextOverflow.ellipsis),
          ),

          // FLEX 2: Telefone
          Expanded(
            flex: 2, 
            child: Text(telefone, overflow: TextOverflow.ellipsis),
          ),
          
          // FLEX 2: Nível (Badge Centralizado)
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  // Lógica simples de cor baseada no nível
                  color: (nivel.toLowerCase() == 'admin' ? Colors.red : Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  nivel.toUpperCase(), 
                  style: TextStyle(
                    fontSize: 11, 
                    color: (nivel.toLowerCase() == 'admin' ? Colors.red : Colors.blue).shade900, 
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ),
          ),
          
          // FLEX 2: Ações (Centralizado)
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // CENTRALIZADO
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