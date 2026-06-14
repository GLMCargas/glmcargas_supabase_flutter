import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Componentes GLM UI', () {
    testWidgets('GlmFormPage exibe titulo, subtitulo e conteudo', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GlmFormPage(
            title: 'Cadastro',
            subtitle: 'Preencha os dados',
            child: Text('Conteudo do formulario'),
          ),
        ),
      );

      expect(find.text('Cadastro'), findsOneWidget);
      expect(find.text('Preencha os dados'), findsOneWidget);
      expect(find.text('Conteudo do formulario'), findsOneWidget);
      expect(find.text('GLM'), findsOneWidget);
      expect(find.text('CARGAS'), findsOneWidget);
    });

    testWidgets('GlmPrimaryButton executa callback quando habilitado', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlmPrimaryButton(
              label: 'Continuar',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Continuar'));
      expect(pressed, isTrue);
    });

    testWidgets('GlmPrimaryButton em loading desabilita acao', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlmPrimaryButton(
              label: 'Salvar',
              loading: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Salvar'), warnIfMissed: false);
      expect(pressed, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
