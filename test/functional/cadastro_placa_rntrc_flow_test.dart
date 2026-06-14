import 'package:app/cadastro/cadastro_placa_rntrc.dart';
import 'package:app/cadastro/vehicle_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fluxo funcional de placa e RNTRC', () {
    final vehicleData = VehicleData(
      tamanhoVeiculo: 'M\u00E9dio',
      tipoVeiculo: 'Truck',
      bauVeiculo: 'Fechado',
      tipoBau: 'Ba\u00FA',
    );

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CadastroPlacaRntrcScreen(vehicleData: vehicleData),
        ),
      );
    }

    testWidgets('exibe campos obrigatorios ao enviar vazio', (tester) async {
      await pumpScreen(tester);

      await tester.ensureVisible(find.text('Enviar documentos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar documentos'));
      await tester.pump();

      expect(find.text('Campo obrigatorio'), findsNWidgets(2));
    });

    testWidgets('formata placa digitada em letras maiusculas com hifen',
        (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'abc1234');
      await tester.pump();

      expect(find.text('ABC-1234'), findsOneWidget);
    });

    testWidgets('valida placa e rntrc invalidos sem chamar Supabase',
        (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'ab12');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.ensureVisible(find.text('Enviar documentos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar documentos'));
      await tester.pump();

      expect(find.text('Informe uma placa valida'), findsOneWidget);
      expect(
        find.text('Informe 8 numeros do RNTRC ou 9 com zero a esquerda'),
        findsOneWidget,
      );
    });
  });
}
