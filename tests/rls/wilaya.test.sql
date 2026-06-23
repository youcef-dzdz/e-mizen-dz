-- =============================================================================
-- tests/rls/wilaya.test.sql — Tests négatifs RLS, table wilaya (Rule 12)
-- -----------------------------------------------------------------------------
-- POURQUOI : prouver qu'un utilisateur NON autorisé est BLOQUÉ — pas seulement
--   qu'un lecteur public peut lire. Un test positif seul donne une fausse
--   confiance. On couvre SELECT (autorisé) + INSERT/UPDATE/DELETE (interdits).
--
-- Environnement : Postgres Supabase (rôles anon/authenticated + grants par
--   défaut sur public). Lancer via psql ou `supabase db`. Tout est encapsulé
--   dans une transaction terminée par ROLLBACK → AUCUNE donnée persistée (donc
--   ce fichier n'introduit aucun seed).
-- Convention : une exception 'ECHEC: ...' = test raté ; fin sans exception = OK.
-- =============================================================================

begin;

-- Fixture privilégiée (rôle courant = propriétaire migration). Annulée au ROLLBACK.
insert into public.wilaya (id, code, nom_fr, nom_ar, latitude, longitude)
values (31, '31', 'Oran', 'وهران', 35.691100, -0.642200);

-- On bascule en VISITEUR (non authentifié).
set local role anon;

-- (1) SELECT anon DOIT réussir (donnée publique — découverte marketplace).
do $$
declare n int;
begin
  select count(*) into n from public.wilaya where id = 31;
  if n <> 1 then
    raise exception 'ECHEC: anon SELECT wilaya devrait voir la ligne (vu %)', n;
  end if;
end $$;

-- (2) INSERT anon DOIT échouer (aucune policy write → violation RLS, SQLSTATE 42501).
do $$
begin
  insert into public.wilaya (id, code, nom_fr, nom_ar, latitude, longitude)
  values (16, '16', 'Alger', 'الجزائر', 36.753800, 3.058800);
  raise exception 'ECHEC: anon INSERT wilaya aurait du etre bloque par RLS';
exception
  when insufficient_privilege then null; -- comportement attendu : RLS refuse
end $$;

-- (3) UPDATE anon DOIT échouer (aucune policy UPDATE → 0 ligne affectée).
do $$
declare n int;
begin
  update public.wilaya set nom_fr = 'Pirate' where id = 31;
  get diagnostics n = row_count;
  if n <> 0 then
    raise exception 'ECHEC: anon UPDATE wilaya aurait du affecter 0 ligne (affecte %)', n;
  end if;
end $$;

-- (4) DELETE anon DOIT échouer (aucune policy DELETE → 0 ligne affectée).
do $$
declare n int;
begin
  delete from public.wilaya where id = 31;
  get diagnostics n = row_count;
  if n <> 0 then
    raise exception 'ECHEC: anon DELETE wilaya aurait du affecter 0 ligne (affecte %)', n;
  end if;
end $$;

rollback;
