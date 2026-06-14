import 'package:app/screen/cadastro.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(initializeSupabaseForTests);

  testWidgets('exibe validacoes obrigatorias no cadastro de motorista', (
    tester,
  ) async {
    await pumpTestPage(tester, const SignupPage());

    await tester.ensureVisible(find.text('Continuar cadastro'));
    await tester.tap(find.text('Continuar cadastro'));
    await tester.pump();

    expect(find.text('Campo obrigatorio'), findsWidgets);
  });

  testWidgets('pede genero antes de tentar cadastrar no Supabase', (
    tester,
  ) async {
    await pumpTestPage(tester, const SignupPage());

    await enterTextFormField(tester, 0, 'motorista@example.com');
    await enterTextFormField(tester, 1, 'Maria');
    await enterTextFormField(tester, 2, 'Silva');
    await enterTextFormField(tester, 3, '12345678901');
    await enterTextFormField(tester, 4, '11052000');
    await enterTextFormField(tester, 5, '51999999999');
    await enterTextFormField(tester, 6, 'senha123');

    await tester.ensureVisible(find.text('Continuar cadastro'));
    await tester.tap(find.text('Continuar cadastro'));
    await tester.pump();

    expect(find.textContaining('Selecione um g'), findsOneWidget);
  });

}
