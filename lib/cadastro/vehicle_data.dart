// vehicle_data.dart
class VehicleData {
  String? tamanhoVeiculo;   // Pesado, Médio, Leve
  String? tipoVeiculo;      // Bitrem, Truck, 3/4...
  String? bauVeiculo;       // Fechado, Aberto, Especial
  String? tipoBau;          // Baú, Caçamba, Graneleiro...
  String? placaVeiculo;
  String? rntrcAntt;

  VehicleData({
    this.tamanhoVeiculo,
    this.tipoVeiculo,
    this.bauVeiculo,
    this.tipoBau,
    this.placaVeiculo,
    this.rntrcAntt,
  });

  VehicleData copyWith({
    String? tamanhoVeiculo,
    String? tipoVeiculo,
    String? bauVeiculo,
    String? tipoBau,
    String? placaVeiculo,
    String? rntrcAntt,
  }) {
    return VehicleData(
      tamanhoVeiculo: tamanhoVeiculo ?? this.tamanhoVeiculo,
      tipoVeiculo: tipoVeiculo ?? this.tipoVeiculo,
      bauVeiculo: bauVeiculo ?? this.bauVeiculo,
      tipoBau: tipoBau ?? this.tipoBau,
      placaVeiculo: placaVeiculo ?? this.placaVeiculo,
      rntrcAntt: rntrcAntt ?? this.rntrcAntt,
    );
  }
}
