# Supabase e publicacao web

## Ambientes configurados

- `dev`: `https://zabeesixaloyyhrsqqne.supabase.co`
- `prod`: `https://zzwbnyajtdvmcumdlfoj.supabase.co`

O cliente Flutter aceita tanto chave publica `publishable` quanto `anon`.

## Arquivos de ambiente

- `env/supabase.dev.json`
- `env/supabase.prod.json`

## Execucao local

Desenvolvimento:

```bash
flutter run -d chrome --dart-define-from-file=env/supabase.dev.json
```

Producao:

```bash
flutter run -d chrome --dart-define-from-file=env/supabase.prod.json
```

## Build e deploy de producao

O deploy web deste repositorio e manual via Firebase Hosting.

```bash
flutter pub get
flutter test
flutter build web --release --dart-define-from-file=env/supabase.prod.json
firebase login
firebase deploy --only hosting
```

Referencias:

- Projeto Firebase padrao: `glm-cargas-acd3d`
- Pasta publicada: `build/web`
