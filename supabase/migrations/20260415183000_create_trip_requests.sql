do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'status_solicitacao_viagem'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.status_solicitacao_viagem as enum (
      'Aguardando',
      'Aceita',
      'Recusada'
    );
  end if;
end
$$;

create table if not exists public.solicitacoes_viagem (
  id uuid primary key default gen_random_uuid(),
  viagem_id bigint not null references public."Viagens"(id) on delete cascade,
  motorista_user_id uuid not null references public."Usuario_Caminhoneiro"(id) on delete cascade,
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  mensagem_inicial text,
  status public.status_solicitacao_viagem not null default 'Aguardando',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  responded_at timestamptz
);

create unique index if not exists solicitacoes_viagem_viagem_motorista_key
  on public.solicitacoes_viagem (viagem_id, motorista_user_id);

create or replace function public.set_solicitacoes_viagem_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();

  if new.status is distinct from old.status and new.status <> 'Aguardando' then
    new.responded_at = now();
  end if;

  return new;
end;
$$;

drop trigger if exists trg_set_solicitacoes_viagem_updated_at on public.solicitacoes_viagem;

create trigger trg_set_solicitacoes_viagem_updated_at
before update on public.solicitacoes_viagem
for each row
execute function public.set_solicitacoes_viagem_updated_at();

alter table public.solicitacoes_viagem enable row level security;

drop policy if exists "solicitacoes_select_participants" on public.solicitacoes_viagem;
create policy "solicitacoes_select_participants"
on public.solicitacoes_viagem
for select
to authenticated
using (
  auth.uid() = motorista_user_id
  or exists (
    select 1
    from public."Viagens" as viagens
    where viagens.id = solicitacoes_viagem.viagem_id
      and viagens.empresa_user_id = auth.uid()
  )
);

drop policy if exists "solicitacoes_insert_motorista" on public.solicitacoes_viagem;
create policy "solicitacoes_insert_motorista"
on public.solicitacoes_viagem
for insert
to authenticated
with check (auth.uid() = motorista_user_id);

drop policy if exists "solicitacoes_update_empresa" on public.solicitacoes_viagem;
create policy "solicitacoes_update_empresa"
on public.solicitacoes_viagem
for update
to authenticated
using (
  exists (
    select 1
    from public."Viagens" as viagens
    where viagens.id = solicitacoes_viagem.viagem_id
      and viagens.empresa_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public."Viagens" as viagens
    where viagens.id = solicitacoes_viagem.viagem_id
      and viagens.empresa_user_id = auth.uid()
  )
);

create or replace function public.request_trip_interest(p_viagem_id bigint)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_motorista uuid := auth.uid();
  v_room_id uuid;
  v_request_id uuid;
  v_status public.status_solicitacao_viagem;
  v_created_now boolean := false;
  v_nome text;
  v_sobrenome text;
  v_empresa text;
  v_origem_cidade text;
  v_origem_uf text;
  v_destino_cidade text;
  v_destino_uf text;
  v_message text;
begin
  if v_motorista is null then
    raise exception 'Usuário nao autenticado';
  end if;

  select nome, sobrenome
    into v_nome, v_sobrenome
  from public."Usuario_Caminhoneiro"
  where id = v_motorista;

  if not found then
    raise exception 'Perfil do motorista não encontrado';
  end if;

  select empresa,
         coalesce(origem_cidade, ''),
         coalesce(origem_uf, ''),
         coalesce(destino_cidade, ''),
         coalesce(destino_uf, '')
    into v_empresa,
         v_origem_cidade,
         v_origem_uf,
         v_destino_cidade,
         v_destino_uf
  from public."Viagens"
  where id = p_viagem_id;

  if not found then
    raise exception 'Viagem não encontrada';
  end if;

  v_room_id := public.create_or_get_chat_room(p_viagem_id);

  select id, status
    into v_request_id, v_status
  from public.solicitacoes_viagem
  where viagem_id = p_viagem_id
    and motorista_user_id = v_motorista;

  if v_request_id is null then
    v_message := trim(
      both ' '
      from format(
        'Olá, meu nome é %s%s e tenho interesse em realizar esta viagem de %s/%s para %s/%s. Aguardo o retorno da empresa.',
        coalesce(v_nome, 'Motorista'),
        case
          when coalesce(v_sobrenome, '') = '' then ''
          else ' ' || v_sobrenome
        end,
        nullif(v_origem_cidade, ''),
        nullif(v_origem_uf, ''),
        nullif(v_destino_cidade, ''),
        nullif(v_destino_uf, '')
      )
    );

    if v_origem_cidade = '' or v_origem_uf = '' or v_destino_cidade = '' or v_destino_uf = '' then
      v_message := format(
        'Olá, meu nome é %s%s e tenho interesse em realizar a viagem %s%s. Aguardo o retorno da empresa.',
        coalesce(v_nome, 'Motorista'),
        case
          when coalesce(v_sobrenome, '') = '' then ''
          else ' ' || v_sobrenome
        end,
        p_viagem_id::text,
        case
          when coalesce(v_empresa, '') = '' then ''
          else ' da empresa ' || v_empresa
        end
      );
    end if;

    insert into public.solicitacoes_viagem (
      viagem_id,
      motorista_user_id,
      room_id,
      mensagem_inicial
    )
    values (
      p_viagem_id,
      v_motorista,
      v_room_id,
      v_message
    )
    returning id, status
      into v_request_id, v_status;

    insert into public.chat_messages (
      room_id,
      sender_user_id,
      message
    )
    values (
      v_room_id,
      v_motorista,
      v_message
    );

    v_created_now := true;
  else
    update public.solicitacoes_viagem
    set room_id = v_room_id
    where id = v_request_id
      and room_id is distinct from v_room_id;
  end if;

  return jsonb_build_object(
    'request_id', v_request_id,
    'room_id', v_room_id,
    'status', v_status::text,
    'created_now', v_created_now
  );
end;
$$;

grant all on table public.solicitacoes_viagem to authenticated;
grant all on table public.solicitacoes_viagem to service_role;
grant usage on type public.status_solicitacao_viagem to authenticated;
grant usage on type public.status_solicitacao_viagem to service_role;
grant execute on function public.request_trip_interest(bigint) to authenticated;
grant execute on function public.request_trip_interest(bigint) to service_role;
