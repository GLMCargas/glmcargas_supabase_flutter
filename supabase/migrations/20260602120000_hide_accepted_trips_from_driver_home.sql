drop function if exists public.listar_cargas_publicadas_motorista(text);
drop function if exists public.listar_cargas_publicadas_motorista(character varying);

create function public.listar_cargas_publicadas_motorista(
  p_uf_coleta text default null
)
returns table (
  viagem_id bigint,
  id bigint,
  empresa text,
  produto text,
  origem_cidade text,
  origem_uf text,
  destino_cidade text,
  destino_uf text,
  peso numeric,
  valor numeric,
  dimensoes text,
  data_limite_entrega timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    viagens.id as viagem_id,
    viagens.id,
    viagens.empresa,
    viagens.produto,
    viagens.origem_cidade,
    viagens.origem_uf,
    viagens.destino_cidade,
    viagens.destino_uf,
    viagens.peso,
    viagens.valor,
    viagens.dimensoes,
    viagens.data_limite_entrega
  from public."Viagens" as viagens
  where (p_uf_coleta is null or viagens.origem_uf = p_uf_coleta)
    and not exists (
      select 1
      from public.solicitacoes_viagem as solicitacoes
      where solicitacoes.viagem_id = viagens.id
        and solicitacoes.status = 'Aceita'
    )
  order by viagens.created_at desc;
$$;

grant execute on function public.listar_cargas_publicadas_motorista(text)
  to authenticated;
grant execute on function public.listar_cargas_publicadas_motorista(text)
  to service_role;
