import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:agenda/controller/firestore_service.dart';
import 'package:agenda/controller/agendamento_model.dart';
import 'package:agenda/controller/estoque_model.dart';
import 'package:agenda/controller/transacao_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

class DashboardView extends StatefulWidget {
  final FirestoreService? firestoreService;
  
  const DashboardView({super.key, this.firestoreService});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final FirestoreService firestoreService;
  int _diasFiltro = 7;

  @override
  void initState() {
    super.initState();
    firestoreService = widget.firestoreService ?? FirestoreService();
    _verificarAcessoAdmin();
  }

  void _verificarAcessoAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    final adminEmail = dotenv.env['ADMIN_EMAIL'];
    if (user == null || (adminEmail != null && user.email != adminEmail)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acesso negado.'), backgroundColor: Colors.red),
          );
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar Relatório Financeiro (PDF)',
            onPressed: () => _exportarRelatorioFinanceiroPDF(context, firestoreService),
          ),
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            tooltip: 'Exportar Agendamentos (Excel)',
            onPressed: () => _exportarExcel(context, firestoreService),
          ),
        ],
        title: const Text('Dashboard Administrativo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo do Dia', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<List<Agendamento>>(
              stream: firestoreService.getAgendamentos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Erro: ${snapshot.error}');
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final agendamentos = snapshot.data!;
                final hoje = DateTime.now();
                final agendamentosHoje = agendamentos.where((a) {
                  return a.dataHora.year == hoje.year &&
                         a.dataHora.month == hoje.month &&
                         a.dataHora.day == hoje.day;
                }).toList();

                final pendentes = agendamentos.where((a) => a.status == 'pendente').length;
                final confirmados = agendamentos.where((a) => a.status == 'aprovado').length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Se a largura for menor que 600px, usa layout vertical (Mobile)
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          _buildMetricCard('Hoje', '${agendamentosHoje.length}', Colors.blue),
                          _buildMetricCard('Pendentes', '$pendentes', Colors.orange),
                          _buildMetricCard('Confirmados', '$confirmados', Colors.green),
                        ],
                      );
                    } else {
                      // Layout horizontal (Tablet/Desktop)
                      return Row(
                        children: [
                          Expanded(child: _buildMetricCard('Hoje', '${agendamentosHoje.length}', Colors.blue)),
                          Expanded(child: _buildMetricCard('Pendentes', '$pendentes', Colors.orange)),
                          Expanded(child: _buildMetricCard('Confirmados', '$confirmados', Colors.green)),
                        ],
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            const Text('Estoque Baixo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<List<ItemEstoque>>(
              stream: firestoreService.getEstoque(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                
                final estoque = snapshot.data!;
                // Filtra itens com menos de 5 unidades (ajuste conforme necessidade)
                final baixoEstoque = estoque.where((item) => item.quantidade < 5).toList();

                if (baixoEstoque.isEmpty) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Estoque em dia!')));
                }

                return Column(
                  children: baixoEstoque.map((item) => ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    title: Text(item.nome),
                    subtitle: Text('Restam apenas ${item.quantidade} unidades'),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFaturamentoChart(firestoreService),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: firestoreService.getManutencaoStream(),
        builder: (context, snapshot) {
          final emManutencao = snapshot.data ?? false;
          return FloatingActionButton.extended(
            onPressed: () => _confirmarTrocaManutencao(context, firestoreService, !emManutencao),
            backgroundColor: emManutencao ? Colors.red : Colors.green,
            icon: Icon(emManutencao ? Icons.lock_open : Icons.lock),
            label: Text(emManutencao ? 'Desativar Manutenção' : 'Ativar Manutenção'),
          );
        },
      ),
    );
  }

  Future<void> _exportarExcel(BuildContext context, FirestoreService service) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final bytes = await service.gerarRelatorioAgendamentosExcel();
    
    if (context.mounted) Navigator.pop(context);

    if (bytes != null) {
      if (kIsWeb) {
        // Exportação Web usando universal_html
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'agendamentos_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Exportação Mobile (Android/iOS)
        final directory = await getTemporaryDirectory();
        final fileName = 'agendamentos_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        
        await Share.shareXFiles([XFile(file.path)], text: 'Relatório de Agendamentos');
      }
    } else if (bytes == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum dado para exportar.')),
      );
    }
  }

  Future<void> _exportarRelatorioFinanceiroPDF(BuildContext context, FirestoreService service) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Obter dados
      final transacoes = await service.getTransacoes().first;
      
      // Filtra pelo período selecionado no Dashboard
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDate = today.subtract(Duration(days: _diasFiltro - 1));
      
      final transacoesFiltradas = transacoes.where((t) {
        return !t.dataPagamento.isBefore(startDate);
      }).toList();

      // 2. Gerar PDF
      final pdf = pw.Document();
      final font = pw.Font.helvetica();
      
      // Carrega o logo (assumindo que existe em assets/images/logo.png)
      // Se não tiver logo, pode remover esta parte ou usar um placeholder
      pw.MemoryImage? logoImage;
      try {
        final logoBytes = await rootBundle.load('lib/images/logo.png');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) { /* Ignora se não encontrar o logo */ }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoImage != null) 
                      pw.Image(logoImage, width: 50, height: 50),
                    pw.SizedBox(width: 10),
                    pw.Expanded(child: pw.Text('Relatório Financeiro', style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold))),
                    pw.Text('Período: $_diasFiltro dias', style: pw.TextStyle(font: font, fontSize: 14)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                headers: ['Data', 'Cliente', 'Método', 'Valor Líquido'],
                data: transacoesFiltradas.map((t) => [
                  DateFormat('dd/MM/yyyy HH:mm').format(t.dataPagamento),
                  t.clienteUid, // Idealmente buscaria o nome, mas usaremos o UID/Snapshot se disponível
                  t.metodoPagamento.toUpperCase(),
                  'R\$ ${t.valorLiquido.toStringAsFixed(2)}',
                ]).toList(),
              ),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total: R\$ ${transacoesFiltradas.fold(0.0, (sum, t) => sum + t.valorLiquido).toStringAsFixed(2)}',
                  style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();

      if (context.mounted) Navigator.pop(context); // Fecha loading

      // 3. Salvar/Compartilhar (Reutilizando lógica similar ao Excel)
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'financeiro_${DateFormat('dd-MM-yyyy').format(now)}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getTemporaryDirectory();
        final fileName = 'financeiro_${DateFormat('dd-MM-yyyy').format(now)}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles([XFile(file.path)], text: 'Relatório Financeiro PDF');
      }

    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
      }
    }
  }

  Future<void> _confirmarTrocaManutencao(BuildContext context, FirestoreService service, bool novoStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(novoStatus ? 'Ativar Modo Manutenção?' : 'Desativar Modo Manutenção?'),
        content: Text(novoStatus 
          ? 'Isso bloqueará o acesso de TODOS os clientes ao aplicativo imediatamente.' 
          : 'O aplicativo ficará disponível novamente para todos os clientes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: novoStatus ? Colors.red : Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.atualizarStatusManutencao(novoStatus);
    }
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      color: color.withAlpha((0.1 * 255).round()),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaturamentoChart(FirestoreService service) {
    return SizedBox(
      height: 250,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Faturamento (Últimos $_diasFiltro dias)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  DropdownButton<int>(
                    value: _diasFiltro,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 dias')),
                      DropdownMenuItem(value: 15, child: Text('15 dias')),
                      DropdownMenuItem(value: 30, child: Text('30 dias')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _diasFiltro = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<TransacaoFinanceira>>(
                  stream: service.getTransacoes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final startDate = today.subtract(Duration(days: _diasFiltro - 1));
                    
                    final dailyTotals = <int, double>{ for (int i = 0; i < _diasFiltro; i++) i: 0.0 };

                    for (var transacao in snapshot.data!) {
                      if (!transacao.dataPagamento.isBefore(startDate)) {
                        final dayIndex = (_diasFiltro - 1) - today.difference(DateTime(transacao.dataPagamento.year, transacao.dataPagamento.month, transacao.dataPagamento.day)).inDays;
                        if (dayIndex >= 0 && dayIndex < _diasFiltro) {
                          dailyTotals[dayIndex] = (dailyTotals[dayIndex] ?? 0) + transacao.valorLiquido;
                        }
                      }
                    }
                    
                    final barGroups = dailyTotals.entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value,
                            color: Colors.teal,
                            width: 16,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList();

                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: barGroups,
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                // Mostra apenas alguns rótulos se o intervalo for grande
                                if (_diasFiltro > 10 && value.toInt() % 5 != 0) return const SizedBox();
                                final day = today.subtract(Duration(days: (_diasFiltro - 1) - value.toInt()));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(DateFormat('dd/MM').format(day), style: const TextStyle(fontSize: 10)),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}