# GLM Cargas Web

Aplicacao Flutter Web da GLM Cargas para motoristas, com autenticacao,
cadastro de perfil, envio de documentos, gerenciamento de veiculo, busca de
cargas e chat.

## Funcionalidades

- Login e logout de motoristas
- Cadastro de dados pessoais, veiculo, placa e RNTRC
- Envio de documentos e foto de perfil
- Pagina de perfil do motorista
- Listagem de cargas disponiveis e entregas do motorista
- Chat entre motorista e empresa

## Stack

- Flutter Web
- Dart
- Supabase
- Firebase Hosting

## Requisitos

- Flutter SDK 3.9.2 ou superior
- Navegador Chrome ou Edge para execucao local
- Firebase CLI para publicacao web

## Configuracao de ambiente

O app valida as configuracoes do Supabase na inicializacao e espera receber os
valores por `--dart-define`.

Arquivos ja versionados:

- `env/supabase.dev.json`
- `env/supabase.prod.json`

As chaves aceitas pelo app sao:

- `APP_ENV`
- `SUPABASE_URL` ou `NEXT_PUBLIC_SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`,
  `SUPABASE_ANON_KEY` ou `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `MAPBOX_ACCESS_TOKEN` para recursos de mapa/navegacao

## Como rodar

Instale as dependencias:

```bash
flutter pub get
```

Ambiente de desenvolvimento:

```bash
flutter run -d chrome --dart-define-from-file=env/supabase.dev.json
```

Ambiente de producao:

```bash
flutter run -d chrome --dart-define-from-file=env/supabase.prod.json
```

## Testes

Executar toda a suite:

```bash
flutter test
```

Executar um teste especifico:

```bash
flutter test test/functional/cadastro_placa_rntrc_flow_test.dart
```

## Publicacao em producao

Hoje o deploy nao esta automatizado por GitHub Actions neste repositorio. A
publicacao e manual via Firebase Hosting.

Fluxo recomendado para colocar os ajustes da `main` em producao:

```bash
git checkout main
git pull --ff-only origin main
flutter pub get
flutter test
flutter build web --release --dart-define-from-file=env/supabase.prod.json
firebase login
firebase deploy --only hosting
```

Observacoes importantes:

- O projeto Firebase padrao deste repositorio e `glm-cargas-acd3d`
- O artefato publicado fica em `build/web`
- O deploy usa as regras de hosting definidas em `firebase.json`

## Banco e backend

- As migracoes do banco ficam em `supabase/migrations/`
- As funcoes de borda ficam em `supabase/functions/`
- A configuracao local do Supabase CLI fica em `supabase/config.toml`

## Estrutura principal

- `lib/`: codigo da aplicacao Flutter
- `test/`: testes unitarios, funcionais, de widget e de tela
- `env/`: arquivos de `dart-define` para dev e prod
- `supabase/`: migracoes, funcoes e configuracao do backend
- `docs/`: documentacao complementar
