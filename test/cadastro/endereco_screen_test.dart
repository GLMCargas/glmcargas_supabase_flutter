import 'package:app/cadastro/cadastro_endereco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(initializeSupabaseForTests);

  testWidgets('exibe validacoes obrigatorias no endereco', (tester) async {
    await pumpTestPage(tester, const CadastroEnderecoScreen());

    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Campo obrigatorio'), findsWidgets);
  });

  testWidgets('aceita endereco sem numero quando S/N esta marcado', (
    tester,
  ) async {
    await pumpTestPage(tester, const CadastroEnderecoScreen());

    await enterTextFormField(tester, 0, '99999999');
    await enterTextFormField(tester, 1, 'Rua Teste');
    await enterTextFormField(tester, 2, 'Centro');
    await enterTextFormField(tester, 3, 'Porto Alegre');
    await enterTextFormField(tester, 4, 'RS');

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Campo obrigatorio'), findsNothing);
  });
}
