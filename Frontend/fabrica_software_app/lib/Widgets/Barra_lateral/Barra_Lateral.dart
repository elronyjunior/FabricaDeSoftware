import 'package:fabrica_software_app/Widgets/Nivel_icon/Nivel_icon.dart';
import 'package:fabrica_software_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'styles/Barra_Lateral_Styles.dart';

class BarraLateral extends StatelessWidget {
  const BarraLateral({super.key});

  @override
  Widget build(BuildContext context) {
    final _authProvider = context.watch<AuthProvider>();

    final String? rotaAtual = ModalRoute.of(context)?.settings.name;

    final bool isAccountSelected = rotaAtual == '/Account';

    final Color userTextColor = isAccountSelected 
        ? const Color.fromARGB(255, 44, 100, 253) 
        : Barra_Lateral_Styles.Usercolor; 

    final Color userBgColor = isAccountSelected 
        ? const Color.fromARGB(255, 235, 241, 255) 
        : const Color.fromARGB(0, 43, 43, 43);

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 80.0,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 44, 100, 253),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(children: <Widget>[
                    Image.asset('assets/image/icone_logo.png', height: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Fabrica Software',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 24),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const FaIcon(FontAwesomeIcons.x),
                      color: Colors.white,
                      iconSize: 15,
                    )
                  ]),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildMenuItem(
                  context,
                  icon: FontAwesomeIcons.folderOpen,
                  text: 'Projetos',
                  rotaDestino: '/Gerenciar_Projetos',
                  rotaAtual: rotaAtual,
                ),
                _buildMenuItem(
                  context,
                  icon: FontAwesomeIcons.peopleGroup,
                  text: 'Equipe',
                  rotaDestino: '/Equipe', 
                  rotaAtual: rotaAtual,
                ),
                _buildMenuItem(
                  context,
                  icon: FontAwesomeIcons.chartBar,
                  text: 'Relatórios',
                  rotaDestino: '/Relatorios', 
                  rotaAtual: rotaAtual,
                ),
                _buildMenuItem(
                  context,
                  icon: FontAwesomeIcons.usersGear,
                  text: 'Gestão de Usuários',
                  rotaDestino: '/Usuarios',
                  rotaAtual: rotaAtual,
                ),
                _buildMenuItem(
                  context,
                  icon: FontAwesomeIcons.users,
                  text: 'Gestão de Clientes',
                  rotaDestino: '/Clientes',
                  rotaAtual: rotaAtual,
                ),
                _buildMenuItem(
                  context,
                  icon: FontAwesomeIcons.cubes,
                  text: 'Gestão de Recursos',
                  rotaDestino: '/Recursos',
                  rotaAtual: rotaAtual,
                ),
                _buildMenuItem(
                  context,
                  icon: FontAwesomeIcons.microchip,
                  text: 'Gestão de Tecnologias',
                  rotaDestino: '/Tecnologias',
                  rotaAtual: rotaAtual,
                ),
              ],
            ),
          ),
          const Divider(),
          
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    if (!isAccountSelected) {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/Account');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: userBgColor, 
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          NivelIcon(
                            nivel: '${_authProvider.userNivel}',
                            color: userTextColor, 
                          ),
                          const SizedBox(width: 13),
                          Text(
                            '${_authProvider.userNivel?.toUpperCase()}',
                            style: TextStyle(
                                color: userTextColor, 
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                    tooltip: 'Sair da conta',
                    onPressed: () {
                      _authProvider.logout();
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.rightFromBracket,
                      color: Color.fromARGB(255, 179, 45, 36),
                    ))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String rotaDestino,
    required String? rotaAtual,
  }) {
    final bool isSelected = rotaAtual == rotaDestino;
    final Color itemColor = isSelected ? const Color.fromARGB(255, 44, 100, 253) : const Color.fromARGB(255,75, 85, 99,);
    final Color bgColor = isSelected ? const Color.fromARGB(255, 235, 241, 255) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: FaIcon(icon, color: itemColor, size: 20),
        title: Text(
          text,
          style: Barra_Lateral_Styles.TextStyleButtons.copyWith(
            color: itemColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: () {
          if (!isSelected) {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, rotaDestino);
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}