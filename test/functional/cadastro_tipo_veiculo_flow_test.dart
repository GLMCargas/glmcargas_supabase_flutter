import 'package:app/cadastro/cadastro_tipo_carroceria.dart';
import 'package:app/cadastro/cadastro_tipo_veiculo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fluxo funcional de cadastro de veiculo', () {
    testWidgets('bloqueia avanço sem selecionar tipo de veiculo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CadastroTipoVeiculoScreen()),
      );

      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pump();

      expect(
        find.text('Selecione um tipo de ve\u00EDculo.'),
        findsOneWidget,
      );
    });

    testWidgets('seleciona tipo e navega para tipo de carroceria',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CadastroTipoVeiculoScreen()),
      );

      await tester.ensureVisible(find.text('Truck'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Truck'));
      await tester.pump();
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.byType(CadastroTipoCarroceriaScreen), findsOneWidget);
      expect(find.text('Tipo de carroceria'), findsOneWidget);
    });
  });
}
