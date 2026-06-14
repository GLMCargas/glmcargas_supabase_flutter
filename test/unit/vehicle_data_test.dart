import 'package:app/cadastro/vehicle_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleData', () {
    test('copyWith altera somente os campos informados', () {
      final original = VehicleData(
        tamanhoVeiculo: 'Pesado',
        tipoVeiculo: 'Truck',
        bauVeiculo: 'Aberto',
        tipoBau: 'Ca\u00E7amba',
        placaVeiculo: 'ABC1234',
        rntrcAntt: '12345678',
      );

      final updated = original.copyWith(
        tipoBau: 'Graneleiro',
        placaVeiculo: 'XYZ9876',
      );

      expect(updated.tamanhoVeiculo, 'Pesado');
      expect(updated.tipoVeiculo, 'Truck');
      expect(updated.bauVeiculo, 'Aberto');
      expect(updated.tipoBau, 'Graneleiro');
      expect(updated.placaVeiculo, 'XYZ9876');
      expect(updated.rntrcAntt, '12345678');
    });

    test('permite criar dados parciais durante cadastro multi-etapas', () {
      final data = VehicleData(tipoVeiculo: 'Fiorino');

      expect(data.tipoVeiculo, 'Fiorino');
      expect(data.tamanhoVeiculo, isNull);
      expect(data.bauVeiculo, isNull);
    });
  });
}
