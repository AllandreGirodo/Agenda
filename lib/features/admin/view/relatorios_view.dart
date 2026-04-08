import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/models/agendamento_model.dart';
import 'package:agenda/app_localizations.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/core/utils/massage_type_catalog.dart';

class AdminRelatoriosView extends StatelessWidget {
  const AdminRelatoriosView({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.relatoriosGerenciais),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Botão de Exportar PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: AppStrings.exportarPdfCompartilhar,
            onPressed: () => _gerarECompartilharPdf(context, firestoreService),
          ),
        ],
      ),
      body: StreamBuilder<List<Agendamento>>(
        stream: firestoreService.getAgendamentos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final agendamentos = snapshot.data!;
          final now = DateTime.now();
          
          // Filtrar agendamentos do mês atual
          final agendamentosMes = agendamentos.where((a) => 
            a.dataHora.year == now.year && a.dataHora.month == now.month
          ).toList();

          if (agendamentosMes.isEmpty) {
            return Center(child: Text(AppStrings.semDadosMes));
          }

          // Métricas
          final total = agendamentosMes.length;
          final cancelados = agendamentosMes.where((a) => a.status.contains('cancelado') || a.status == 'recusado').length;
          final realizados = agendamentosMes.where((a) => a.status == 'aprovado').length; // Considerando aprovados como realizados/futuros confirmados
          
          final taxaCancelamento = total > 0 ? (cancelados / total) * 100 : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(AppStrings.resumoDe(DateFormat('MMMM yyyy', 'pt_BR').format(now)),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Total Agendado', '$total', Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Realizados/Conf.', '$realizados', Colors.green)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Cancelados', '$cancelados', Colors.red)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Taxa Cancelamento', '${taxaCancelamento.toStringAsFixed(1)}%', Colors.orange)),
                ],
              ),

              const SizedBox(height: 30),
              Text(AppStrings.detalhamentoCancelamentos, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              ...agendamentosMes.where((a) => a.status.contains('cancelado')).map((a) {
                return ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: Text(DateFormat('dd/MM HH:mm').format(a.dataHora)),
                  subtitle: Text(a.motivoCancelamento ?? AppStrings.semMotivoCancelamento),
                  trailing: Text(a.status == 'cancelado_tardio' ? AppStrings.tardio : AppStrings.normal, 
                    style: TextStyle(color: a.status == 'cancelado_tardio' ? Colors.purple : Colors.grey)),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[800]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _gerarECompartilharPdf(BuildContext context, FirestoreService service) async {
    final messenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context)!;

    try {
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.gerandoPdf)));

      // 1. Obter dados (snapshot único para o relatório)
      final snapshot = await service.getAgendamentos().first;
      final now = DateTime.now();
      final agendamentosMes = snapshot.where((a) => 
        a.dataHora.year == now.year && a.dataHora.month == now.month
      ).toList();

      // Ordenar por data
      agendamentosMes.sort((a, b) => a.dataHora.compareTo(b.dataHora));

      // Cálculos
      final realizados = agendamentosMes.where((a) => a.status == 'aprovado').length;
      final config = await service.getConfiguracao();
      final receitaEstimada = realizados * config.precoSessao;

      // 2. Criar Documento PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(AppStrings.relatorioMensalTitulo, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text(AppStrings.mesReferencia(DateFormat('MMMM yyyy', 'pt_BR').format(now))),
                pw.Text(AppStrings.dataEmissao(DateFormat('dd/MM/yyyy HH:mm').format(now))),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                // Resumo Financeiro
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(AppStrings.resumoFinanceiro, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text(AppStrings.totalAgendamentos(agendamentosMes.length)),
                      pw.Text(AppStrings.sessoesRealizadas(realizados)),
                      pw.Text(AppStrings.receitaBruta('R\$ ${receitaEstimada.toStringAsFixed(2)}'), style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Tabela de Agendamentos
                pw.Text(AppStrings.detalhamento, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  context: pdfContext,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headers: ['Data', 'Cliente', 'Tipo', 'Status', 'Valor'],
                  data: agendamentosMes.map((a) => [
                    DateFormat('dd/MM HH:mm').format(a.dataHora),
                    a.clienteNomeSnapshot ??
                        (() {
                          final id = a.clienteId;
                          final prefixo = id.length > 5 ? id.substring(0, 5) : id;
                          return 'ID: ${prefixo.isEmpty ? 'N/A' : prefixo}...';
                        })(), // Proteção de dados se snapshot falhar
                    MassageTypeCatalog.localize(localizations, a.tipo),
                    a.status.toUpperCase(),
                    a.status == 'aprovado' ? 'R\$ ${config.precoSessao}' : '-',
                  ]).toList(),
                ),
              ],
            );
          },
        ),
      );

      // 3. Salvar e Compartilhar
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateFormat('MM_yyyy').format(now)}.pdf");
      await file.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Segue o relatório financeiro de ${DateFormat('MMMM').format(now)}.',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(AppStrings.erroGerarPdf(e.toString()))));
      }
    }
  }
}