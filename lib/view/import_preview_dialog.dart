import 'package:flutter/material.dart';

/// Helper para validar e mostrar preview de importacao
class ImportPreviewHelper {
  /// Validar cabecalho: verifica se tem campos obrigatorios
  static Map<String, dynamic> validarCabecalho(List<String> headers) {
    final resultado = <String, dynamic>{
      'valido': true,
      'erro': null,
      'campos_mapeados': <String>[],
      'campos_erro': <String>[],
    };

    // Normalizar para comparacao
    final headersNormalizados = headers
        .map((h) => _normalizar(h).replaceFirst('\ufeff', ''))
        .toList();

    bool temTelefone = false;
    bool temNome = false;

    for (int i = 0; i < headers.length; i++) {
      final normalized = headersNormalizados[i];

      if (_ehCampoTelefonePrincipal(normalized)) {
        temTelefone = true;
      }

      if (_ehCampoNomePrincipal(normalized)) {
        temNome = true;
      }

      resultado['campos_mapeados'].add(headers[i]);
    }

    if (!temTelefone) {
      resultado['valido'] = false;
      resultado['erro'] = 'Campo obrigatorio nao encontrado: "Telefone Principal"';
    }
    if (!temNome && resultado['valido'] != false) {
      resultado['valido'] = false;
      resultado['erro'] = 'Campo obrigatorio nao encontrado: "Nome Principal"';
    }

    return resultado;
  }

  static bool _ehCampoTelefonePrincipal(String campoNormalizado) {
    final temTelefone =
        campoNormalizado.contains('telefone') ||
        campoNormalizado.contains('whatsapp') ||
        campoNormalizado.contains('celular');

    final ehSecundario =
        campoNormalizado.contains('secund') ||
        campoNormalizado.contains('indic') ||
        campoNormalizado.contains('contato');

    return temTelefone && !ehSecundario;
  }

  static bool _ehCampoNomePrincipal(String campoNormalizado) {
    final temNome =
        campoNormalizado == 'nome' ||
        campoNormalizado.contains('nome principal') ||
        campoNormalizado.contains('cliente nome') ||
        (campoNormalizado.contains('nome') &&
            campoNormalizado.contains('cliente'));

    final ehSecundario =
        campoNormalizado.contains('secund') ||
        campoNormalizado.contains('indic') ||
        campoNormalizado.contains('contato');

    return temNome && !ehSecundario;
  }

  /// Normalizar nome do campo
  static String _normalizar(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll('\ufeff', '')
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[_\s]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), '')
        .trim();
  }

  /// Mostrar dialogo de preview
  static Future<bool> mostrarPreview(
    BuildContext context, {
    required List<String> headers,
    required List<Map<String, dynamic>> linhas,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: Column(
            children: [
              // Header
              Container(
                color: Colors.blue.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          'Validacao de Arquivo',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Campos: ${headers.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Registros: ${linhas.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Campos encontrados:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: headers.map((h) {
                          return Chip(
                            label: Text(h, style: const TextStyle(fontSize: 11)),
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Preview de dados (primeiros 3 registros):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      _buildPreviewRecords(linhas.take(3).toList(), headers),
                      if (linhas.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '... +${linhas.length - 3} registros',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.upload),
                      label: const Text('Importar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return resultado ?? false;
  }

  static Widget _buildPreviewRecords(
    List<Map<String, dynamic>> linhas,
    List<String> headers,
  ) {
    return Column(
      children: linhas.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final linha = entry.value;
        return _buildPreviewRecord(idx, headers, linha);
      }).toList(),
    );
  }

  static Widget _buildPreviewRecord(
    int numero,
    List<String> headers,
    Map<String, dynamic> linha,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registro #$numero',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...headers.take(5).map((header) {
            final valor = linha[header];
            final textoValor = valor == null ? '(vazio)' : valor.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      header,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      textoValor.length > 25
                          ? '${textoValor.substring(0, 25)}...'
                          : textoValor,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (headers.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${headers.length - 5} campos',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
