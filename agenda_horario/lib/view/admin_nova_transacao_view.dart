import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/firestore_service.dart';
import '../controller/cliente_model.dart';
import '../controller/transacao_model.dart';

class AdminNovaTransacaoView extends StatefulWidget {
  const AdminNovaTransacaoView({super.key});

  @override
  State<AdminNovaTransacaoView> createState() => _AdminNovaTransacaoViewState();
}

class _AdminNovaTransacaoViewState extends State<AdminNovaTransacaoView> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  String? _clienteUidSelecionado;
  final _valorBrutoController = TextEditingController();
  final _valorDescontoController = TextEditingController();
  final _valorLiquidoController = TextEditingController();
  String _metodoPagamento = 'pix';
  String _statusPagamento = 'pago';
  DateTime _dataPagamento = DateTime.now();
  
  List<Cliente> _clientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
    _valorBrutoController.addListener(_calcularLiquido);
    _valorDescontoController.addListener(_calcularLiquido);
  }

  @override
  void dispose() {
    _valorBrutoController.dispose();
    _valorDescontoController.dispose();
    _valorLiquidoController.dispose();
    super.dispose();
  }

  void _calcularLiquido() {
    double bruto = double.tryParse(_valorBrutoController.text.replaceAll(',', '.')) ?? 0.0;
    double desconto = double.tryParse(_valorDescontoController.text.replaceAll(',', '.')) ?? 0.0;
    double liquido = bruto - desconto;
    if (liquido < 0) liquido = 0;
    _valorLiquidoController.text = liquido.toStringAsFixed(2);
  }

  Future<void> _carregarClientes() async {
    // Busca a lista de clientes para o Dropdown
    final snapshot = await _firestoreService.getClientesAprovados().first;
    if (mounted) {
      setState(() {
        _clientes = snapshot;
        _isLoading = false;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteUidSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um cliente')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transacao = TransacaoFinanceira(
        clienteUid: _clienteUidSelecionado!,
        valorBruto: double.parse(_valorBrutoController.text.replaceAll(',', '.')),
        valorDesconto: double.tryParse(_valorDescontoController.text.replaceAll(',', '.')) ?? 0.0,
        valorLiquido: double.parse(_valorLiquidoController.text.replaceAll(',', '.')),
        metodoPagamento: _metodoPagamento,
        statusPagamento: _statusPagamento,
        dataPagamento: _dataPagamento,
        criadoPorUid: FirebaseAuth.instance.currentUser?.uid ?? 'admin',
        dataCriacao: DateTime.now(),
      );

      await _firestoreService.salvarTransacao(transacao);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transação registrada com sucesso!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Transação'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    value: _clienteUidSelecionado,
                    decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
                    items: _clientes.map((c) => DropdownMenuItem(value: c.uid, child: Text(c.nome))).toList(),
                    onChanged: (v) => setState(() => _clienteUidSelecionado = v),
                    validator: (v) => v == null ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _valorBrutoController,
                          decoration: const InputDecoration(labelText: 'Valor Bruto (R\$)', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _valorDescontoController,
                          decoration: const InputDecoration(labelText: 'Desconto (R\$)', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _valorLiquidoController,
                    decoration: InputDecoration(labelText: 'Valor Líquido (R\$)', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[200]),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _metodoPagamento,
                    decoration: const InputDecoration(labelText: 'Método de Pagamento', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'pix', child: Text('Pix')),
                      DropdownMenuItem(value: 'dinheiro', child: Text('Dinheiro')),
                      DropdownMenuItem(value: 'cartao', child: Text('Cartão')),
                      DropdownMenuItem(value: 'pacote', child: Text('Pacote')),
                    ],
                    onChanged: (v) => setState(() => _metodoPagamento = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _statusPagamento,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
                      DropdownMenuItem(value: 'pago', child: Text('Pago')),
                      DropdownMenuItem(value: 'estornado', child: Text('Estornado')),
                    ],
                    onChanged: (v) => setState(() => _statusPagamento = v!),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('Data do Pagamento: ${DateFormat('dd/MM/yyyy').format(_dataPagamento)}'),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dataPagamento,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _dataPagamento = picked);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Registrar Transação'),
                  ),
                ],
              ),
            ),
    );
  }
}