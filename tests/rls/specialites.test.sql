-- =============================================================================
-- tests/rls/specialites.test.sql — Tests négatifs RLS, table specialites (Rule 12)
-- -----------------------------------------------------------------------------
-- POURQUOI : même modèle que wilaya — donnée de référence publique en lecture
--   seule. On prouve que l'écriture anon est bloquée, la lecture autorisée.
-- Environnement : Postgres Supabase. Transaction + ROLLBACK → aucun seed persisté.
-- Convention : exception 'ECHEC: ...' = test raté ; fin sans exception = OK.
-- =============================================================================

begin;

-- Fixture privilégiée, annulée au ROLLBACK.
insert into public.specialites (id, slug, nom_fr, nom_ar)
values (1, 'droit-penal', 'Droit pénal', 'القانون الجنائي');

-- On bascule en VISITEUR (non authentifié).
set local role anon;

-- (1) SELECT anon DOIT réussir (filtres de recherche publics).
do $$
declare n int;
begin
  select count(*) into n from public.specialites where id = 1;
  if n <> 1 then
    raise exception 'ECHEC: anon SELECT specialites devrait voir la ligne (vu %)', n;
  end if;
end $$;

-- (2) INSERT anon DOIT échouer (aucune policy write → violation RLS, 42501).
do $$
begin
  insert into public.specialites (id, slug, nom_fr, nom_ar)
  values (2, 'droit-famille', 'Droit de la famille', 'قانون الأسرة');
  raise exception 'ECHEC: anon INSERT specialites aurait du etre bloque par RLS';
exception
  when insufficient_privilege then null; -- comportement attendu
end $$;

-- (3) UPDATE anon DOIT échouer (aucune policy UPDATE → 0 ligne affectée).
do $$
declare n int;
begin
  update public.specialites set nom_fr = 'Pirate' where id = 1;
  get diagnostics n = row_count;
  if n <> 0 then
    raise exception 'ECHEC: anon UPDATE specialites aurait du affecter 0 ligne (affecte %)', n;
  end if;
end $$;

-- (4) DELETE anon DOIT échouer (aucune policy DELETE → 0 ligne affectée).
do $$
declare n int;
begin
  delete from public.specialites where id = 1;
  get diagnostics n = row_count;
  if n <> 0 then
    raise exception 'ECHEC: anon DELETE specialites aurait du affecter 0 ligne (affecte %)', n;
  end if;
end $$;

rollback;
