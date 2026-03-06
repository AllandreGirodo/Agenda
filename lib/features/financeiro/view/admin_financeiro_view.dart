import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/agendamento_model.dart';
import 'package:agenda/view/app_strings.dart';
import 'package:agenda/view/app_styles.dart';

class AdminFinanceiroView extends StatefulWidget {
  const AdminFinanceiroView({super.key});

  @override
  State<AdminFinanceiroView> createState() => _AdminFinanceiroViewState();
}

class _AdminFinanceiroViewState extends State<AdminFinanceiroView> {
  final FirestoreService _firestoreService = FirestoreService();
  int _anoSelecionado = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.configFinanceiro),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Agendamento>>(
        stream: _firestoreService.getAgendamentos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Sem dados financeiros.'));
          }

          final agendamentos = snapshot.data!;
          
          // Filtrar apenas aprovados do ano selecionado
          final agendamentosAno = agendamentos.where((a) => 
            a.status == 'aprovado' && a.dataHora.year == _anoSelecionado
          ).toList();

          // Agrupar por mês
          final Map<int, double> faturamentoMensal = {};
          // Inicializa com 0
          for (int i = 1; i <= 12; i++) {
            faturamentoMensal[i] = 0.0;
          }

          for (var a in agendamentosAno) {
            // Usa valorFinal se existir (com desconto), senão valorOriginal, senão 0
            final valor = a.valorFinal ?? a.valorOriginal ?? 0.0;
            faturamentoMensal[a.dataHora.month] = (faturamentoMensal[a.dataHora.month] ?? 0) + valor;
          }

          // Preparar dados para o gráfico
          final List<BarChartGroupData> barGroups = [];
          double maxValor = 0;

          faturamentoMensal.forEach((mes, valor) {
            if (valor > maxValor) maxValor = valor;
            barGroups.add(
              BarChartGroupData(
                x: mes,
                barRods: [
                  BarChartRodData(
                    toY: valor,
                    color: AppColors.primary,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            );
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seletor de Ano
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.financeiroAnualTitulo, style: AppStyles.title),
                    DropdownButton<int>(
                      value: _anoSelecionado,
                      items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                          .map((ano) => DropdownMenuItem(value: ano, child: Text(ano.toString())))
                          .toList(),
                      onChanged: (val) => setState(() => _anoSelecionado = val!),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Gráfico
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValor * 1.2, // Margem superior
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${_getNomeMes(group.x)}\nR\$ ${rod.toY.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: Text(_getSiglaMes(value.toInt()), style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Total Anual: R\$ ${faturamentoMensal.values.reduce((a, b) => a + b).toStringAsFixed(2)}', 
                  style: AppStyles.title.copyWith(color: Colors.green)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getNomeMes(int mes) => DateFormat('MMMM', 'pt_BR').format(DateTime(2023, mes));
  String _getSiglaMes(int mes) => DateFormat('MMM', 'pt_BR').format(DateTime(2023, mes)).toUpperCase();
}