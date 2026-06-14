import 'package:app/cadastro/vehicle_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleData', () {
    test('copyWith preserva campos quando nao recebe novos valores', () {
      final original = VehicleData(
        tamanhoVeiculo: 'Pesado',
        tipoVeiculo: 'Truck',
        bauVeiculo: 'Fechado',
        tipoBau: 'Sider',
        placaVeiculo: 'ABC1D23',
        rntrcAntt: '12345678',
      );

      final copy = original.copyWith();

      expect(copy.tamanhoVeiculo, original.tamanhoVeiculo);
      expect(copy.tipoVeiculo, original.tipoVeiculo);
      expect(copy.bauVeiculo, original.bauVeiculo);
      expect(copy.tipoBau, original.tipoBau);
      expect(copy.placaVeiculo, original.placaVeiculo);
      expect(copy.rntrcAntt, original.rntrcAntt);
    });

    test('copyWith sobrescreve somente os campos informados', () {
      final original = VehicleData(
        tamanhoVeiculo: 'Pesado',
        tipoVeiculo: 'Carreta',
        bauVeiculo: 'Aberto',
      );

      final copy = original.copyWith(tipoBau: 'Prancha');

      expect(copy.tamanhoVeiculo, 'Pesado');
      expect(copy.tipoVeiculo, 'Carreta');
      expect(copy.bauVeiculo, 'Aberto');
      expect(copy.tipoBau, 'Prancha');
    });
  });
}
