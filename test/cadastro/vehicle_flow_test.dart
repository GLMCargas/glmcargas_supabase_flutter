import 'package:app/cadastro/cadastro_tipo_carroceria.dart';
import 'package:app/cadastro/cadastro_tipo_veiculo.dart';
import 'package:app/cadastro/vehicle_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('tipo de veiculo exige selecao antes de continuar', (
    tester,
  ) async {
    await pumpTestPage(tester, const CadastroTipoVeiculoScreen());

    await tapVisibleText(tester, 'Continuar');

    expect(find.textContaining('Selecione um tipo'), findsOneWidget);
  });

  testWidgets('tipo de veiculo selecionado avanca para carroceria', (
    tester,
  ) async {
    await pumpTestPage(tester, const CadastroTipoVeiculoScreen());

    await tester.tap(find.text('Truck'));
    await tester.pump();
    await tapVisibleText(tester, 'Continuar');
    await tester.pumpAndSettle();

    expect(find.textContaining('Tipo de carroceria'), findsOneWidget);
  });

  testWidgets('tipo de carroceria exige selecao antes de continuar', (
    tester,
  ) async {
    await pumpTestPage(
      tester,
      CadastroTipoCarroceriaScreen(
        vehicleData: VehicleData(
          tipoVeiculo: 'Truck',
          tamanhoVeiculo: 'Medio',
        ),
      ),
    );

    await tapVisibleText(tester, 'Continuar');

    expect(find.textContaining('Selecione um tipo de carroceria'), findsOneWidget);
  });

  testWidgets('tipo de carroceria selecionado avanca para placa e RNTRC', (
    tester,
  ) async {
    await pumpTestPage(
      tester,
      CadastroTipoCarroceriaScreen(
        vehicleData: VehicleData(
          tipoVeiculo: 'Truck',
          tamanhoVeiculo: 'Medio',
        ),
      ),
    );

    await tester.tap(find.text('Sider'));
    await tester.pump();
    await tapVisibleText(tester, 'Continuar');
    await tester.pumpAndSettle();

    expect(find.text('RNTRC (ANTT) *'), findsOneWidget);
  });
}
