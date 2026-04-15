# Supabase: separacao de dev e prod

## Ambientes configurados

- `dev`: `https://zabeesixaloyyhrsqqne.supabase.co`
- `prod`: `https://zzwbnyajtdvmcumdlfoj.supabase.co`

O app agora aceita tanto `anon key` quanto `publishable key`.

## Arquivos prontos

- `env/supabase.dev.json`
- `env/supabase.prod.json`

## Como rodar

### Dev

```bash
flutter run -d chrome --dart-define-from-file=env/supabase.dev.json
```

### Prod

```bash
flutter run -d chrome --dart-define-from-file=env/supabase.prod.json
```

## Observacao

No cliente Flutter, a chave usada na inicializacao pode ser `publishable` ou
`anon`, conforme a documentacao atual do Supabase.
