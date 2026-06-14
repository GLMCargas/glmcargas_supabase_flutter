import 'package:app/cadastro/documentos_cnh.dart';
import 'package:app/cadastro/documentos_selfie.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(initializeSupabaseForTests);

  testWidgets('CNH exige imagem antes do upload', (tester) async {
    await pumpTestPage(tester, const DocumentosCnhScreen());

    await tester.ensureVisible(find.text('Enviar documento'));
    await tester.tap(find.text('Enviar documento'));
    await tester.pump();

    expect(find.textContaining('Envie a imagem da CNH'), findsOneWidget);
  });

  testWidgets('selfie exige imagem antes do upload', (tester) async {
    await pumpTestPage(tester, const DocumentosSelfieScreen());

    await tester.ensureVisible(find.text('Enviar selfie'));
    await tester.tap(find.text('Enviar selfie'));
    await tester.pump();

    expect(find.textContaining('Tire a selfie antes'), findsOneWidget);
  });
}
