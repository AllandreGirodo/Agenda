// ATENÇÃO: As linhas de teste abaixo estão comentadas para permitir que o app compile em modo Release.
// O pacote 'flutter_test' fica em dev_dependencies e não pode ser acessado pelo código de produção (PerfilView).
// Para rodar os testes, descomente as linhas abaixo e execute o arquivo.

// import 'package:flutter_test/flutter_test.dart';

// --- TAG DE AMBIENTE ---
const bool kModoTeste = true;

// --- LÓGICA DE NEGÓCIO (CLASSE) ---
// Skill: Strategy Pattern (Encapsulamento de regras de validação)
class Validadores {
  static String? validarCpf(String? value, {bool obrigatorio = false}) {
    if (value == null || value.isEmpty) return obrigatorio ? 'CPF obrigatório' : null;
    
    final cpf = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Se não for obrigatório e estiver vazio (após limpar), retorna válido
    if (cpf.isEmpty && !obrigatorio) return null;
    
    if (cpf.length != 11) return 'CPF deve ter 11 dígitos';
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return 'CPF inválido';

    List<int> numbers = cpf.split('').map(int.parse).toList();
    
    // Validação do primeiro dígito verificador (multiplicadores 10 a 2)
    int sum = 0;
    for (int i = 0; i < 9; i++) sum += numbers[i] * (10 - i);
    int digit1 = 11 - (sum % 11);
    if (digit1 >= 10) digit1 = 0;
    if (numbers[9] != digit1) return 'CPF inválido';

    // Validação do segundo dígito verificador (multiplicadores 11 a 2)
    sum = 0;
    for (int i = 0; i < 10; i++) sum += numbers[i] * (11 - i);
    int digit2 = 11 - (sum % 11);
    if (digit2 >= 10) digit2 = 0;
    if (numbers[10] != digit2) return 'CPF inválido';

    return null;
  }

  static String? validarEmail(String? value, {bool obrigatorio = false}) {
    if (value == null || value.isEmpty) {
      return obrigatorio ? 'E-mail obrigatório' : null;
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'E-mail inválido';
    }
    return null;
  }
}

// --- ÁREA DE TESTES ---
/*
void main() {
  if (kModoTeste) {
    group('Validação de CPF', () {
      test('Deve retornar erro se CPF for vazio e obrigatório', () {
        final result = Validadores.validarCpf('', obrigatorio: true);
        expect(result, 'CPF obrigatório');
      });

      test('Deve aceitar vazio se não for obrigatório', () {
        final result = Validadores.validarCpf('', obrigatorio: false);
        expect(result, null);
      });

      test('Deve retornar erro se tamanho for incorreto', () {
        final result = Validadores.validarCpf('123.456.789-0'); // 10 dígitos
        expect(result, 'CPF deve ter 11 dígitos');
      });

      test('Deve retornar erro para dígitos repetidos conhecidos', () {
        final result = Validadores.validarCpf('111.111.111-11');
        expect(result, 'CPF inválido');
      });

      test('Deve retornar erro para CPF matematicamente inválido', () {
        final result = Validadores.validarCpf('123.456.789-00'); 
        expect(result, 'CPF inválido');
      });

      test('Deve aceitar CPF válido', () {
        final result = Validadores.validarCpf('73666685030');
        expect(result, null);
      });
    });

    group('Validação de E-mail', () {
      test('Deve retornar erro para e-mail inválido', () {
        final result = Validadores.validarEmail('emailinvalido');
        expect(result, 'E-mail inválido');
      });

      test('Deve aceitar e-mail válido', () {
        final result = Validadores.validarEmail('teste@exemplo.com');
        expect(result, null);
      });
    });
  }
}
*/