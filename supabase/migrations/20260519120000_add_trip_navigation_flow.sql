do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'status_execucao_viagem'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.status_execucao_viagem as enum (
      'Aguardando retirada',
      'Retirada informada',
      'Em entrega',
      'Entrega informada',
      'Concluida',
      'Cancelada'
    );
  end if;
end;
$$;

alter table public."Viagens"
add column if not exists coleta_endereco text,
add column if not exists coleta_latitude double precision,
add column if not exists coleta_longitude double precision,
add column if not exists coleta_place_id text,
add column if not exists entrega_endereco text,
add column if not exists entrega_latitude double precision,
add column if not exists entrega_longitude double precision,
add column if not exists entrega_place_id text;

alter table public."Viagens"
drop constraint if exists viagens_coleta_coords_valid;

alter table public."Viagens"
add constraint viagens_coleta_coords_valid
check (
  (
    coleta_latitude is null
    and coleta_longitude is null
  )
  or (
    coleta_latitude is not null
    and coleta_longitude is not null
    and
    coleta_latitude between -90 and 90
    and coleta_longitude between -180 and 180
  )
);

alter table public."Viagens"
drop constraint if exists viagens_entrega_coords_valid;

alter table public."Viagens"
add constraint viagens_entrega_coords_valid
check (
  (
    entrega_latitude is null
    and entrega_longitude is null
  )
  or (
    entrega_latitude is not null
    and entrega_longitude is not null
    and
    entrega_latitude between -90 and 90
    and entrega_longitude between -180 and 180
  )
);

alter table public.solicitacoes_viagem
add column if not exists status_execucao public.status_execucao_viagem,
add column if not exists coleta_informada_em timestamptz,
add column if not exists coleta_confirmada_em timestamptz,
add column if not exists entrega_informada_em timestamptz,
add column if not exists entrega_confirmada_em timestamptz;

update public.solicitacoes_viagem
set status_execucao = 'Aguardando retirada'
where status = 'Aceita'
  and status_execucao is null;

create or replace function public.sync_solicitacao_execucao_status()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'Aceita' and new.status_execucao is null then
    new.status_execucao = 'Aguardando retirada';
  end if;

  if new.status <> 'Aceita' then
    new.status_execucao = null;
    new.coleta_informada_em = null;
    new.coleta_confirmada_em = null;
    new.entrega_informada_em = null;
    new.entrega_confirmada_em = null;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_solicitacao_execucao_status
on public.solicitacoes_viagem;

create trigger trg_sync_solicitacao_execucao_status
before insert or update of status, status_execucao
on public.solicitacoes_viagem
for each row
execute function public.sync_solicitacao_execucao_status();

alter table public.solicitacoes_viagem
drop constraint if exists solicitacoes_viagem_execucao_matches_status;

alter table public.solicitacoes_viagem
add constraint solicitacoes_viagem_execucao_matches_status
check (
  (
    status = 'Aceita'
    and status_execucao is not null
  )
  or (
    status <> 'Aceita'
    and status_execucao is null
  )
);

create or replace function public.informar_coleta_realizada(
  p_solicitacao_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_motorista uuid := auth.uid();
  v_solicitacao public.solicitacoes_viagem%rowtype;
begin
  if v_motorista is null then
    raise exception 'Usuario nao autenticado';
  end if;

  select *
    into v_solicitacao
  from public.solicitacoes_viagem
  where id = p_solicitacao_id
    and motorista_user_id = v_motorista
  for update;

  if not found then
    raise exception 'Solicitacao nao encontrada para este motorista';
  end if;

  if v_solicitacao.status <> 'Aceita' then
    raise exception 'Solicitacao ainda nao foi aceita pela empresa';
  end if;

  if v_solicitacao.status_execucao = 'Aguardando retirada' then
    update public.solicitacoes_viagem
    set status_execucao = 'Retirada informada',
        coleta_informada_em = coalesce(coleta_informada_em, now())
    where id = p_solicitacao_id
    returning *
      into v_solicitacao;
  elsif v_solicitacao.status_execucao <> 'Retirada informada' then
    raise exception 'A coleta nao pode ser informada nesta etapa';
  end if;

  return jsonb_build_object(
    'solicitacao_id', v_solicitacao.id,
    'status_execucao', v_solicitacao.status_execucao::text,
    'coleta_informada_em', v_solicitacao.coleta_informada_em
  );
end;
$$;

create or replace function public.confirmar_coleta_empresa(
  p_solicitacao_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa uuid := auth.uid();
  v_solicitacao public.solicitacoes_viagem%rowtype;
begin
  if v_empresa is null then
    raise exception 'Usuario nao autenticado';
  end if;

  select s.*
    into v_solicitacao
  from public.solicitacoes_viagem as s
  join public."Viagens" as v on v.id = s.viagem_id
  where s.id = p_solicitacao_id
    and v.empresa_user_id = v_empresa
  for update of s;

  if not found then
    raise exception 'Solicitacao nao encontrada para esta empresa';
  end if;

  if v_solicitacao.status <> 'Aceita' then
    raise exception 'Solicitacao ainda nao foi aceita';
  end if;

  if v_solicitacao.status_execucao = 'Retirada informada' then
    update public.solicitacoes_viagem
    set status_execucao = 'Em entrega',
        coleta_confirmada_em = coalesce(coleta_confirmada_em, now())
    where id = p_solicitacao_id
    returning *
      into v_solicitacao;
  elsif v_solicitacao.status_execucao <> 'Em entrega' then
    raise exception 'A coleta nao pode ser confirmada nesta etapa';
  end if;

  return jsonb_build_object(
    'solicitacao_id', v_solicitacao.id,
    'status_execucao', v_solicitacao.status_execucao::text,
    'coleta_confirmada_em', v_solicitacao.coleta_confirmada_em
  );
end;
$$;

create or replace function public.informar_entrega_realizada(
  p_solicitacao_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_motorista uuid := auth.uid();
  v_solicitacao public.solicitacoes_viagem%rowtype;
begin
  if v_motorista is null then
    raise exception 'Usuario nao autenticado';
  end if;

  select *
    into v_solicitacao
  from public.solicitacoes_viagem
  where id = p_solicitacao_id
    and motorista_user_id = v_motorista
  for update;

  if not found then
    raise exception 'Solicitacao nao encontrada para este motorista';
  end if;

  if v_solicitacao.status <> 'Aceita' then
    raise exception 'Solicitacao ainda nao foi aceita pela empresa';
  end if;

  if v_solicitacao.status_execucao = 'Em entrega' then
    update public.solicitacoes_viagem
    set status_execucao = 'Entrega informada',
        entrega_informada_em = coalesce(entrega_informada_em, now())
    where id = p_solicitacao_id
    returning *
      into v_solicitacao;
  elsif v_solicitacao.status_execucao <> 'Entrega informada' then
    raise exception 'A entrega nao pode ser informada nesta etapa';
  end if;

  return jsonb_build_object(
    'solicitacao_id', v_solicitacao.id,
    'status_execucao', v_solicitacao.status_execucao::text,
    'entrega_informada_em', v_solicitacao.entrega_informada_em
  );
end;
$$;

create or replace function public.confirmar_entrega_empresa(
  p_solicitacao_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa uuid := auth.uid();
  v_solicitacao public.solicitacoes_viagem%rowtype;
begin
  if v_empresa is null then
    raise exception 'Usuario nao autenticado';
  end if;

  select s.*
    into v_solicitacao
  from public.solicitacoes_viagem as s
  join public."Viagens" as v on v.id = s.viagem_id
  where s.id = p_solicitacao_id
    and v.empresa_user_id = v_empresa
  for update of s;

  if not found then
    raise exception 'Solicitacao nao encontrada para esta empresa';
  end if;

  if v_solicitacao.status <> 'Aceita' then
    raise exception 'Solicitacao ainda nao foi aceita';
  end if;

  if v_solicitacao.status_execucao = 'Entrega informada' then
    update public.solicitacoes_viagem
    set status_execucao = 'Concluida',
        entrega_confirmada_em = coalesce(entrega_confirmada_em, now())
    where id = p_solicitacao_id
    returning *
      into v_solicitacao;
  elsif v_solicitacao.status_execucao <> 'Concluida' then
    raise exception 'A entrega nao pode ser confirmada nesta etapa';
  end if;

  return jsonb_build_object(
    'solicitacao_id', v_solicitacao.id,
    'status_execucao', v_solicitacao.status_execucao::text,
    'entrega_confirmada_em', v_solicitacao.entrega_confirmada_em
  );
end;
$$;

grant usage on type public.status_execucao_viagem to authenticated;
grant usage on type public.status_execucao_viagem to service_role;

grant execute on function public.informar_coleta_realizada(uuid) to authenticated;
grant execute on function public.informar_coleta_realizada(uuid) to service_role;

grant execute on function public.confirmar_coleta_empresa(uuid) to authenticated;
grant execute on function public.confirmar_coleta_empresa(uuid) to service_role;

grant execute on function public.informar_entrega_realizada(uuid) to authenticated;
grant execute on function public.informar_entrega_realizada(uuid) to service_role;

grant execute on function public.confirmar_entrega_empresa(uuid) to authenticated;
grant execute on function public.confirmar_entrega_empresa(uuid) to service_role;
