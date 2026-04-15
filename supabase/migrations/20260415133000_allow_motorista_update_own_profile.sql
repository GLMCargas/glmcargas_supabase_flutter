create policy "update_user_authenticated"
on "public"."Usuario_Caminhoneiro"
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);
