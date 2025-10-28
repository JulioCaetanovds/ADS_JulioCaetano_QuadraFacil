// Modelo de dados para representar uma reserva.
// Idealmente, viria da camada de domínio.
class BookingData {
  final String quadra;
  final String data; // Pode ser String ou DateTime dependendo da origem
  final String horario; // Pode ser String ou TimeOfDay
  final String status;
  final String cliente; // Adicionado para detalhes do dono

  BookingData({
    required this.quadra,
    required this.data,
    required this.horario,
    required this.status,
    this.cliente = 'Cliente N/A', // Valor padrão
  });
}
