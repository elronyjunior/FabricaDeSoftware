import 'package:fabrica_software_app/Widgets/App_bar/App_bar.dart';
import 'package:fabrica_software_app/Widgets/Barra_lateral/Barra_Lateral.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fabrica_software_app/providers/relatorios_provider.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RelatoriosProvider()..carregarDados(),
      child: Scaffold(
        drawer: BarraLateral(),
        backgroundColor: Colors.grey[50],
        appBar: CustomAppBar(title:"Realtórios Gerais" ),
        body: Consumer<RelatoriosProvider>(
          builder: (context, provider, child) {
            
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());
            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(provider.error!),
                    TextButton(onPressed: () => provider.carregarDados(), child: const Text("Tentar Novamente"))
                  ],
                ),
              );
            }
            if (provider.dados == null) return const Center(child: Text("Nenhum dado disponível."));

            final dados = provider.dados!;

            // --- LAYOUT RESPONSIVO ---
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200), // <--- LIMITA A LARGURA MÁXIMA
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        // 1. TOPO: KPIs + DINHEIRO (Adapta para Desktop)
                        LayoutBuilder(builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            // DESKTOP: Tudo na mesma linha (3 colunas)
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildKpiCard("Projetos Totais", dados['resumo']['total_projetos'].toString(), Icons.folder, Colors.blue)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildKpiCard("Em Andamento", dados['resumo']['projetos_ativos'].toString(), Icons.timelapse, Colors.orange)),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 2, child: _buildBigMoneyCard(dados['resumo']['orcamento_total'])), // Dinheiro ocupa mais espaço
                                ],
                              ),
                            );
                          } else {
                            // MOBILE: Empilhado
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildKpiCard("Projetos Totais", dados['resumo']['total_projetos'].toString(), Icons.folder, Colors.blue)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildKpiCard("Em Andamento", dados['resumo']['projetos_ativos'].toString(), Icons.timelapse, Colors.orange)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildBigMoneyCard(dados['resumo']['orcamento_total']),
                              ],
                            );
                          }
                        }),

                        const SizedBox(height: 24),

                        // 2. GRÁFICO BARRAS (Sempre largura total do container)
                        const Text("Top 5 Projetos - Orçamento Estimado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          height: 350, // Um pouco mais alto
                          padding: const EdgeInsets.all(24),
                          decoration: _boxDecoration(),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _calcularMaxY(dados['grafico_orcamento']),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => Colors.blueGrey)
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < dados['grafico_orcamento'].length) {
                                        // Pega nome curto
                                        String nome = dados['grafico_orcamento'][index]['nome_projeto'].toString();
                                        if (nome.length > 10) nome = "${nome.substring(0, 10)}...";
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 12.0),
                                          child: Text(
                                            nome,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                    reservedSize: 40, // Espaço extra para o texto
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: _gerarGruposBarras(dados['grafico_orcamento']),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 3. PIZZA E LISTA (Lado a lado no Desktop)
                        LayoutBuilder(builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildPizzaComplexidade(dados['grafico_complexidade'])),
                                const SizedBox(width: 24),
                                Expanded(child: _buildListaCustosRecursos(dados['grafico_custo_recursos'])),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildPizzaComplexidade(dados['grafico_complexidade']),
                                const SizedBox(height: 24),
                                _buildListaCustosRecursos(dados['grafico_custo_recursos']),
                              ],
                            );
                          }
                        }),
                        
                        const SizedBox(height: 40), // Espaço final
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS DE UI ---

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Flexible(child: Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBigMoneyCard(dynamic valor) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text("Orçamento Total Estimado", style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox( // Garante que o número não quebre se for gigante
            fit: BoxFit.scaleDown,
            child: Text(
              formatador.format(valor ?? 0),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPizzaComplexidade(List<dynamic> dadosComplexidade) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Distribuição de Complexidade", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _gerarSecoesPizza(dadosComplexidade),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legenda(Colors.green, "Baixa"),
              const SizedBox(width: 12),
              _legenda(Colors.orange, "Média"),
              const SizedBox(width: 12),
              _legenda(Colors.red, "Alta"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildListaCustosRecursos(List<dynamic> dadosCustos) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Custo Projetado de Recursos (RH)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dadosCustos.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = dadosCustos[index];
              final valor = double.tryParse(item['custo_recursos_atual'] ?? '0') ?? 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.people, color: Colors.blue, size: 16),
                ),
                title: Text(item['nome_projeto'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Text(
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legenda(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    );
  }

  // --- LÓGICA GRÁFICOS ---
  List<BarChartGroupData> _gerarGruposBarras(List<dynamic> lista) {
    List<BarChartGroupData> barras = [];
    for (int i = 0; i < lista.length; i++) {
      final valor = double.tryParse(lista[i]['orcamento_estimado'] ?? '0') ?? 0;
      barras.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: valor,
              color: const Color(0xFF8B5CF6),
              width: 24, // Barras mais largas
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            )
          ],
        ),
      );
    }
    return barras;
  }

  List<PieChartSectionData> _gerarSecoesPizza(List<dynamic> lista) {
    return lista.map((item) {
      final qtd = int.parse(item['quantidade']);
      final tipo = item['complexidade'].toString().toLowerCase();
      Color cor;
      if (tipo == 'alta') cor = Colors.red;
      else if (tipo == 'media') cor = Colors.orange;
      else cor = Colors.green;

      return PieChartSectionData(
        color: cor,
        value: qtd.toDouble(),
        title: qtd.toString(),
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  double _calcularMaxY(List<dynamic> lista) {
    double max = 0;
    for (var item in lista) {
      final val = double.tryParse(item['orcamento_estimado'] ?? '0') ?? 0;
      if (val > max) max = val;
    }
    return max * 1.2;
  }
}