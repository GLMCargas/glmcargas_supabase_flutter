import 'package:app/cadastro/documentos_cnh.dart';
import 'package:app/cadastro/documentos_selfie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fluxos funcionais de documentos', () {
    testWidgets('CNH bloqueia envio sem imagem selecionada', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DocumentosCnhScreen()),
      );

      expect(find.text('Nenhuma imagem selecionada'), findsOneWidget);

      await tester.ensureVisible(find.text('Enviar documento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar documento'));
      await tester.pump();

      expect(
        find.text('Envie a imagem da CNH antes de continuar.'),
        findsOneWidget,
      );
    });

    testWidgets('selfie bloqueia envio sem imagem registrada', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DocumentosSelfieScreen()),
      );

      expect(find.text('Nenhuma selfie registrada'), findsOneWidget);

      await tester.ensureVisible(find.text('Enviar selfie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar selfie'));
      await tester.pump();

      expect(find.text('Tire a selfie antes de continuar.'), findsOneWidget);
    });
  });
}
