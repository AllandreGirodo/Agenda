class Validators {
  /// Valida se a idade baseada na data de nascimento é maior ou igual a [idadeMinima].
  static String? validarIdade(DateTime? dataNascimento, {int idadeMinima = 18}) {
    if (dataNascimento == null) return 'Data de nascimento obrigatória.';
    
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;
    
    // Ajuste se ainda não fez aniversário este ano
    if (hoje.month < dataNascimento.month || 
       (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }
    
    if (idade < idadeMinima) {
      return 'É necessário ter pelo menos $idadeMinima anos para se cadastrar.';
    }
    
    return null;
  }
}