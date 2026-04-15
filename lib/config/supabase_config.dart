class SupabaseConfig {
  static const appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _nextPublicSupabaseUrl = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_URL',
  );
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _nextPublicPublishableKey = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY',
  );
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _nextPublicAnonKey = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_ANON_KEY',
  );

  static String get url =>
      _supabaseUrl.isNotEmpty ? _supabaseUrl : _nextPublicSupabaseUrl;

  static String get apiKey {
    if (_publishableKey.isNotEmpty) return _publishableKey;
    if (_nextPublicPublishableKey.isNotEmpty) return _nextPublicPublishableKey;
    if (_anonKey.isNotEmpty) return _anonKey;
    return _nextPublicAnonKey;
  }

  static void validate() {
    if (url.isEmpty || apiKey.isEmpty) {
      throw StateError(
        'Supabase nao configurado. Informe SUPABASE_URL '
        '(ou NEXT_PUBLIC_SUPABASE_URL) e uma chave publica '
        '(SUPABASE_PUBLISHABLE_KEY, NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY, '
        'SUPABASE_ANON_KEY ou NEXT_PUBLIC_SUPABASE_ANON_KEY) via '
        '--dart-define.',
      );
    }
  }
}
