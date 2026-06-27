-- =============================================================================
-- tests/rls/cabinets.test.sql — Tests négatifs RLS, table cabinets (Rule 12)
-- -----------------------------------------------------------------------------
-- POURQUOI : le cabinet est public en lecture (marketplace) mais en écriture
--   verrouillée — toute modification passe par service_role serveur. On prouve
--   que la lecture est autorisée et que l'écriture client est REFUSÉE, par
--   opération (Rule 12), y compris le hard delete (interdit, Rule 10).
--
-- Environnement : Postgres Supabase. On simule un authentifié via role + claims
--   JWT. Transaction + ROLLBACK → fixtures (wilaya + cabinet) jamais persistées.
-- Convention : exception 'ECHEC: ...' = test raté ; fin sans exception = OK.
-- =============================================================================

begin;

-- Fixtures privilégiées, annulées au ROLLBACK.
-- POURQUOI wilaya d'abord : cabinets.wilaya_id a une FK NOT NULL vers wilaya(id).
-- POURQUOI on conflict do nothing : la wilaya 31 (Oran) existe déjà via le seed
--   des 69 wilayas — sans garde, l'INSERT échouerait sur duplicate key avant
--   même les tests. Idempotent : on réutilise la ligne existante si présente.
insert into public.wilaya (id, code, nom_fr, nom_ar, latitude, longitude)
values (31, '31', 'Oran', 'وهران', 35.691700, -0.633300)
on conflict (id) do nothing;

insert into public.cabinets (id, nom, slug, wilaya_id)
values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Cabinet Test', 'cabinet-test', 31);

-- ---------------------------------------------------------------------------
-- (1) SELECT — témoin positif : un VISITEUR (anon) DOIT lire le cabinet.
-- POURQUOI : la découverte marketplace ne doit jamais être bloquée par un login.
-- ---------------------------------------------------------------------------
set local role anon;

do $$
declare n int;
begin
  select count(*) into n from public.cabinets
  where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  if n <> 1 then
    raise exception 'ECHEC: anon SELECT cabinets devrait voir la ligne (vu %)', n;
  end if;
end $$;

-- On bascule en UTILISATEUR AUTHENTIFIÉ pour les tests d'écriture.
-- POURQUOI authenticated (et pas anon) : prouver que même un compte valide ne
--   peut pas écrire un cabinet — l'écriture est réservée au service_role serveur.
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

-- ---------------------------------------------------------------------------
-- (2) INSERT authenticated DOIT échouer (aucune policy write → violation RLS).
-- ---------------------------------------------------------------------------
do $$
begin
  insert into public.cabinets (nom, slug, wilaya_id)
  values ('Cabinet Pirate', 'cabinet-pirate', 31);
  raise exception 'ECHEC: authenticated INSERT cabinets aurait du etre bloque par RLS';
exception
  -- POURQUOI when others : un INSERT bloqué par RLS peut lever insufficient_privilege
  --   OU « new row violates row-level security policy ». On prouve le REFUS, pas un
  --   code d'erreur précis — toute exception ici = comportement attendu.
  when others then null;
end $$;

-- ---------------------------------------------------------------------------
-- (3) UPDATE authenticated DOIT échouer (aucune policy UPDATE → 0 ligne).
-- ---------------------------------------------------------------------------
do $$
begin
  update public.cabinets set nom = 'Pirate'
  where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  raise exception 'ECHEC: authenticated UPDATE cabinets aurait du etre bloque';
exception
  -- POURQUOI when others : sans GRANT UPDATE (defaut Supabase) Postgres leve
  --   « permission denied » AVANT le filtrage RLS — l'exception precede tout
  --   row_count. On prouve le REFUS (par grant OU par RLS), pas un code precis.
  when others then null;
end $$;

-- ---------------------------------------------------------------------------
-- (4) Hard DELETE authenticated DOIT échouer (aucune policy DELETE → 0 ligne).
-- POURQUOI : la suppression se fait par soft delete uniquement (Rule 10).
-- ---------------------------------------------------------------------------
do $$
begin
  delete from public.cabinets
  where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  raise exception 'ECHEC: hard DELETE cabinets aurait du etre bloque (Rule 10)';
exception
  -- POURQUOI when others : sans GRANT DELETE (defaut Supabase) Postgres leve
  --   « permission denied » AVANT le filtrage RLS — l'exception precede tout
  --   row_count. On prouve le REFUS (par grant OU par RLS), pas un code precis.
  when others then null;
end $$;

rollback;
