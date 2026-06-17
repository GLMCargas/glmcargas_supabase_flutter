import 'package:app/screen/home_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(initializeSupabaseForTests);

  test('home formata dados exibidos nos cards de carga', () {
    final dynamic state = const HomeMotoristaScreen().createState();

    expect(state.formatarData('2026-05-11'), '11/05/2026');
    expect(state.formatarData('2026-05-11T14:30:00'), '11/05/2026 14:30');
    expect(state.formatarData('data livre'), 'data livre');
    expect(state.formatarValor('1200'), 'R\$ 1200');
    expect(state.formatarValor('A combinar'), 'A combinar');
    expect(state.formatarPeso(900), '900 kg');
    expect(state.formatarPeso('12 ton'), '12 ton');
    expect(
      state.formatarPesoViagem({'peso_texto': '12 toneladas', 'peso': 0}),
      '12 toneladas',
    );
    expect(
      state.formatarCompatibilidadeVeiculo({
        'compatibilidade_veiculo': 'Truck bau',
        'tipo_veiculo': 'Truck',
      }),
      'Truck bau',
    );
    expect(
      state.formatarCompatibilidadeVeiculo({
        'tipo_veiculo': 'Toco',
        'tipo_carroceria': 'Grade baixa',
      }),
      'Toco - Grade baixa',
    );
    expect(state.inicialEmpresa('GLM Transportes'), 'G');
  });
}
