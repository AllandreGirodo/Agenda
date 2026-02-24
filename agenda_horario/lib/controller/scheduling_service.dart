/// SchedulingService: Lógica de negócio e cálculos automáticos.
class SchedulingService {
  
  // Lógica de Encaixe de Horários
  static List<String> getSlotsDisponiveis() {
    return [
      "08:00", "09:30", "11:00", "13:00", "14:15", "15:30", "17:00", "18:15"
    ];
  }

  // Baixa de estoque automática
  double subtrairInsumo(double estoqueAtual, double doseSessao) {
    if (estoqueAtual >= doseSessao) {
      return estoqueAtual - doseSessao;
    }
    return estoqueAtual;
  }

  // Notificação via WhatsApp
  String formatarMensagemWhats(String nomeCliente, String data, String hora) {
    return "Olá $nomeCliente, seu agendamento para $data às $hora está em análise!";
  }
}