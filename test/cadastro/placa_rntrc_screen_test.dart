import 'package:app/cadastro/cadastro_placa_rntrc.dart';
import 'package:app/cadastro/vehicle_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(initializeSupabaseForTests);

  testWidgets('placa e RNTRC sao obrigatorios', (tester) async {
    await pumpTestPage(
      tester,
      CadastroPlacaRntrcScreen(
        vehicleData: VehicleData(
          tipoVeiculo: 'Truck',
          tamanhoVeiculo: 'Medio',
          bauVeiculo: 'Fechado',
          tipoBau: 'Sider',
        ),
      ),
    );

    await tester.ensureVisible(find.text('Enviar documentos'));
    await tester.tap(find.text('Enviar documentos'));
    await tester.pump();

    expect(find.textContaining('Campo obrigat'), findsNWidgets(2));
  });
}
