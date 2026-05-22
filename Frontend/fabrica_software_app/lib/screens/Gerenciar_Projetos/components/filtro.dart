import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fabrica_software_app/providers/projetos_provider.dart';

class FilterSection extends StatefulWidget {
  const FilterSection({super.key});

  @override
  State<FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
  // Controladores para os campos de texto
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _clienteController = TextEditingController();

  // Estado local para controlar os Dropdowns (necessário para o botão Limpar funcionar visualmente)
  String _selectedTipo = 'Todos';
  String _selectedStatus = 'Todos';

  @override
  void dispose() {
    _nomeController.dispose();
    _clienteController.dispose();
    super.dispose();
  }

  // Função para resetar tudo
  void _limparTudo() {
    // 1. Limpa no Provider (Lógica)
    context.read<ProjetosProvider>().limparFiltros();
    
    // 2. Limpa visualmente (UI)
    setState(() {
      _nomeController.clear();
      _clienteController.clear();
      _selectedTipo = 'Todos';
      _selectedStatus = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Bordas mais arredondadas
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CABEÇALHO DO FILTRO ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.filter_list, color: Colors.pink, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Filtros de Pesquisa",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF1E293B)
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _limparTudo,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Limpar"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
          
          const SizedBox(height: 20),
          
          // --- CAMPOS DE FILTRO ---
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // 1. Input Nome
              _buildInput(
                "Nome do Projeto", 
                "Buscar projeto...", 
                width: 250,
                controller: _nomeController,
                icon: Icons.search,
                onChanged: (value) => context.read<ProjetosProvider>().setFiltroNome(value),
              ),

              // 2. Dropdown Tipo (Bonito e Colorido)
              _buildModernDropdown(
                "Tipo",
                // Opções
                ["Todos", "WEB", "MOBILE", "API", "DESKTOP", "DATA"],
                // Ícones correspondentes
                [Icons.apps, Icons.language, Icons.smartphone, Icons.storage, Icons.monitor, Icons.analytics],
                // Cores correspondentes
                [Colors.grey, Colors.blue, Colors.purple, Colors.orange, Colors.indigo, Colors.teal],
                width: 200,
                selectedValue: _selectedTipo,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedTipo = val);
                    context.read<ProjetosProvider>().setFiltroTipo(val);
                  }
                },
              ),

              // 3. Input Cliente
              _buildInput(
                "Cliente", 
                "Nome do cliente...", 
                width: 250,
                controller: _clienteController,
                icon: Icons.business,
                onChanged: (value) => context.read<ProjetosProvider>().setFiltroCliente(value),
              ),

              // 4. Dropdown Status
              _buildModernDropdown(
                "Status",
                ["Todos", "Em processo", "Concluído", "Atrasado", "Pausado"],
                [Icons.filter_alt, Icons.access_time, Icons.check_circle, Icons.warning, Icons.pause_circle],
                [Colors.grey, Colors.green, Colors.blue, Colors.red, Colors.orange],
                width: 200,
                selectedValue: _selectedStatus,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedStatus = val);
                    context.read<ProjetosProvider>().setFiltroStatus(val);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET AUXILIAR: INPUT DE TEXTO ---
  Widget _buildInput(String label, String hint, {
    required double width, 
    required Function(String) onChanged,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), 
                  borderSide: BorderSide(color: Colors.grey.shade300)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), 
                  borderSide: BorderSide(color: Colors.grey.shade200)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), 
                  borderSide: const BorderSide(color: Colors.pink, width: 1.5)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET AUXILIAR: DROPDOWN MODERNO ---
  Widget _buildModernDropdown(
    String label, 
    List<String> items, 
    List<IconData> icons,
    List<Color> colors, {
    required double width, 
    required String selectedValue,
    required Function(String?) onChanged,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                dropdownColor: Colors.white,
                items: items.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String value = entry.value;
                  
                  // Pega o ícone e cor correspondente, ou usa padrão se não houver
                  IconData icon = (idx < icons.length) ? icons[idx] : Icons.circle;
                  Color color = (idx < colors.length) ? colors[idx] : Colors.grey;

                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: color),
                        const SizedBox(width: 10),
                        Text(
                          value, 
                          style: const TextStyle(fontSize: 13, color: Color(0xFF334155))
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}