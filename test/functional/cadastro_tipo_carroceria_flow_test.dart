import 'package:app/cadastro/cadastro_placa_rntrc.dart';
import 'package:app/cadastro/cadastro_tipo_carroceria.dart';
import 'package:app/cadastro/vehicle_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fluxo funcional de tipo de carroceria', () {
    final vehicleData = VehicleData(
      tipoVeiculo: 'Truck',
      tamanhoVeiculo: 'M\u00E9dio',
    );

    testWidgets('bloqueia avanco sem selecionar carroceria', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CadastroTipoCarroceriaScreen(vehicleData: vehicleData),
        ),
      );

      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pump();

      expect(
        find.text('Selecione um tipo de carroceria.'),
        findsOneWidget,
      );
    });

    testWidgets('seleciona bau e navega para placa e rntrc', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CadastroTipoCarroceriaScreen(vehicleData: vehicleData),
        ),
      );

      await tester.ensureVisible(find.text('Ba\u00FA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ba\u00FA'));
      await tester.pump();
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.byType(CadastroPlacaRntrcScreen), findsOneWidget);
      expect(find.text('Dados do veiculo'), findsOneWidget);
    });
  });
}
