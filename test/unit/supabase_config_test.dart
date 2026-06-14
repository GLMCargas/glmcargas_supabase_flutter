import 'package:app/config/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseConfig', () {
    test('usa ambiente dev como padrao', () {
      expect(SupabaseConfig.appEnv, 'dev');
    });

    test('falha quando url e chave publica nao foram configuradas', () {
      expect(SupabaseConfig.url, isEmpty);
      expect(SupabaseConfig.apiKey, isEmpty);
      expect(SupabaseConfig.validate, throwsA(isA<StateError>()));
    });
  });
}
