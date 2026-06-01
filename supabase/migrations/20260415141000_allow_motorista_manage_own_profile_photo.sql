create policy "motorista_insert_own_profile_photo"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'fotos_motoristas'
  and name = 'fotos_motoristas/' || auth.uid()::text || '.jpg'
);

create policy "motorista_update_own_profile_photo"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'fotos_motoristas'
  and name = 'fotos_motoristas/' || auth.uid()::text || '.jpg'
)
with check (
  bucket_id = 'fotos_motoristas'
  and name = 'fotos_motoristas/' || auth.uid()::text || '.jpg'
);
