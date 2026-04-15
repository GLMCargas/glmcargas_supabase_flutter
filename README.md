# glmcargas_projeto

Equipe: Luisa Scherer e Mathuesa de Brum Kruger

Rodar web, com Chrome ou Edge

Implementado cadastro de motorista com envio de documentos e foto;
Página de perfil do motorista;
Paágina inciial com as cargas disponíveis para o motorista;
Login e logout;
Cadastro de dados pessoais e de veículo do motorista

Utilizado Flutter e Supabase.

## Ambientes Supabase

Arquivos prontos:

- `env/supabase.dev.json`
- `env/supabase.prod.json`

Rodar `dev`:

```bash
flutter run -d chrome --dart-define-from-file=env/supabase.dev.json
```

Rodar `prod`:

```bash
flutter run -d chrome --dart-define-from-file=env/supabase.prod.json
```
