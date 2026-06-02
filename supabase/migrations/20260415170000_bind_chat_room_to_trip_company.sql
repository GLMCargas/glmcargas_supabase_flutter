alter table public."Viagens"
add column if not exists empresa_user_id uuid;

alter table public.chat_rooms
add column if not exists empresa_user_id uuid;

drop function if exists public.create_or_get_chat_room(bigint);

do $$
declare
  v_room_id_type text;
begin
  select format_type(attribute.atttypid, attribute.atttypmod)
    into v_room_id_type
  from pg_attribute as attribute
  where attribute.attrelid = 'public.chat_rooms'::regclass
    and attribute.attname = 'id'
    and not attribute.attisdropped;

  if v_room_id_type is null then
    raise exception 'Coluna public.chat_rooms.id nao encontrada';
  end if;

  execute format($function$
    create function public.create_or_get_chat_room(p_viagem_id bigint)
    returns %1$s
    language plpgsql
    security definer
    as $body$
    declare
      v_room_id %1$s;
      v_motorista uuid := auth.uid();
      v_empresa uuid;
    begin
      if v_motorista is null then
        raise exception 'Usuario nao autenticado';
      end if;

      select empresa_user_id
        into v_empresa
      from public."Viagens"
      where id = p_viagem_id;

      if not found then
        raise exception 'Viagem nao encontrada';
      end if;

      if v_empresa is null then
        raise exception 'Viagem sem empresa vinculada';
      end if;

      select id
        into v_room_id
      from public.chat_rooms
      where viagem_id = p_viagem_id
        and motorista_user_id = v_motorista;

      if v_room_id is not null then
        update public.chat_rooms
        set empresa_user_id = v_empresa
        where id = v_room_id
          and empresa_user_id is distinct from v_empresa;

        return v_room_id;
      end if;

      insert into public.chat_rooms (viagem_id, motorista_user_id, empresa_user_id)
      values (p_viagem_id, v_motorista, v_empresa)
      returning id into v_room_id;

      return v_room_id;
    end;
    $body$;
  $function$, v_room_id_type);
end;
$$;

update public.chat_rooms as rooms
set empresa_user_id = viagens.empresa_user_id
from public."Viagens" as viagens
where viagens.id = rooms.viagem_id
  and viagens.empresa_user_id is not null
  and rooms.empresa_user_id is distinct from viagens.empresa_user_id;
