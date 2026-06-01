import 'package:app/auth/account_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountProfile', () {
    test('normaliza status conhecidos para exibicao', () {
      expect(AccountProfile.displayStatus('aprovado'), 'Aprovado');
      expect(AccountProfile.displayStatus('REPROVADO'), 'Reprovado');
      expect(AccountProfile.displayStatus('em analise'), 'Em an\u00E1lise');
      expect(AccountProfile.displayStatus('em processamento'), 'Em an\u00E1lise');
      expect(AccountProfile.displayStatus('em analise documental'), 'Em an\u00E1lise');
      expect(AccountProfile.displayStatus('aguardando'), 'Pendente');
      expect(AccountProfile.displayStatus(null), 'Pendente');
    });

    test('identifica acesso aprovado e restrito', () {
      expect(AccountProfile.isApprovedStatus('Aprovado'), isTrue);
      expect(AccountProfile.isRestrictedStatus('Pendente'), isTrue);
      expect(AccountProfile.isRestrictedStatus('Reprovado'), isTrue);
    });

    test('cria perfil a partir do mapa do banco com valores padrao', () {
      final profile = AccountProfile.fromMap({
        'id': 'driver-1',
        'email': 'motorista@glm.com',
        'status': 'aprovado',
      });

      expect(profile.id, 'driver-1');
      expect(profile.email, 'motorista@glm.com');
      expect(profile.nome, 'Motorista');
      expect(profile.status, 'Aprovado');
      expect(profile.isApproved, isTrue);
    });

    test('mantem dados brutos e indica restricao para perfil pendente', () {
      final raw = {
        'id': 'driver-2',
        'email': 'pendente@glm.com',
        'nome': 'Luisa',
        'status': 'pendente',
        'telefone': '(51) 99999-0000',
      };

      final profile = AccountProfile.fromMap(raw);

      expect(profile.nome, 'Luisa');
      expect(profile.status, 'Pendente');
      expect(profile.isRestricted, isTrue);
      expect(profile.raw, same(raw));
    });
  });
}
