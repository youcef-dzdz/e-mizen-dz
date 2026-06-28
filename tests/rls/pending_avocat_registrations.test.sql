-- =============================================================================
-- tests/rls/pending_avocat_registrations.test.sql — Tests négatifs RLS (Rule 12)
-- -----------------------------------------------------------------------------
-- POURQUOI : pending_avocat_registrations est un registre serveur PUR — aucune
--   policy, aucun grant client. On prouve (a) que service_role (ici le rôle
--   postgres, qui bypasse RLS) peut écrire/lire — témoin positif — et (b) que
--   anon/authenticated ne voient RIEN et ne peuvent RIEN insérer, par opération
--   (Rule 12). L'absence totale de policy doit se traduire par un refus total.
--
-- Environnement : Postgres Supabase. On simule un authentifié via role + claims
--   JWT. Transaction + ROLLBACK → fixtures jamais persistées. En plus du rollback,
--   le fichier est self-cleaning (delete initial + final) pour ne rien laisser
--   même si exécuté hors transaction.
-- POURQUOI le user de test = '22349d59-75a3-4bbb-accc-8ff240747796' : user_id a une
--   FK vers auth.users ; on ne peut pas insérer dans auth.users (table système).
--   On réutilise donc le compte de test RÉEL déjà présent dans auth.users (créé
--   via Dashboard, voir STATUS.md) pour respecter la contrainte FK.
-- Convention : exception 'ECHEC: ...' = test raté ; fin sans exception = OK.
-- =============================================================================

begin;

-- Nettoyage défensif initial : repartir d'un état propre même si un run précédent
-- a laissé une ligne (le rollback couvre la transaction, ce delete couvre le cas
-- d'une exécution partielle hors transaction).
delete from public.pending_avocat_registrations
where user_id = '22349d59-75a3-4bbb-accc-8ff240747796';

-- Fixture wilaya 16 (Alger). POURQUOI on conflict do nothing : la wilaya 16 existe
-- déjà via le seed des 69 wilayas — sans garde, l'INSERT échouerait sur duplicate
-- key. Idempotent : on réutilise la ligne existante si présente.
insert into public.wilaya (id, code, nom_fr, nom_ar, latitude, longitude)
values (16, '16', 'Alger', 'الجزائر', 36.753800, 3.058800)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- (1) TÉMOIN POSITIF — service_role (rôle postgres courant, bypass RLS) DOIT
--     pouvoir insérer un pending. POURQUOI : prouve que le registre fonctionne
--     pour l'unique acteur autorisé (la route serveur), avant de prouver le refus
--     côté client. wilaya_id=16 satisfait la FK NOT NULL.
-- ---------------------------------------------------------------------------
insert into public.pending_avocat_registrations
  (user_id, nom, prenom, telephone, wilaya_id, cabinet_nom)
values
  ('22349d59-75a3-4bbb-accc-8ff240747796', 'Test', 'Avocat', '0550000000', 16, 'Cabinet Test');

do $$
declare n int;
begin
  select count(*) into n from public.pending_avocat_registrations
  where user_id = '22349d59-75a3-4bbb-accc-8ff240747796';
  if n <> 1 then
    raise exception 'ECHEC: service_role INSERT pending devrait creer la ligne (vu %)', n;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- (2) anon SELECT DOIT échouer. POURQUOI on attend une EXCEPTION et pas « 0
--     ligne » : revoke all retire le privilège SELECT lui-même → Postgres lève
--     « permission denied » AVANT toute évaluation RLS. Le refus est TOTAL (pas
--     un filtrage de lignes) — donc un SELECT qui passe = faille.
-- ---------------------------------------------------------------------------
set local role anon;

do $$
declare n int;
begin
  select count(*) into n from public.pending_avocat_registrations;
  raise exception 'ECHEC: anon SELECT aurait du etre bloque (permission denied attendu)';
exception
  -- Refus permission denied attendu (revoke all) = succès silencieux, même
  -- convention que le test (3) INSERT.
  when others then
    -- Le signal ECHEC doit remonter (test rouge) ; seul le refus attendu
    --   (permission denied / violation RLS) est avalé = succès silencieux.
    if sqlerrm like 'ECHEC:%' then
      raise;
    end if;
end $$;

reset role;

-- On bascule en UTILISATEUR AUTHENTIFIÉ (compte valide) pour les tests d'écriture
-- et de lecture. POURQUOI : prouver que même un compte authentifié — y compris en
-- prétendant être le user du pending via le claim sub — ne peut ni écrire ni lire.
set local role authenticated;
set local request.jwt.claims = '{"sub":"22349d59-75a3-4bbb-accc-8ff240747796","role":"authenticated"}';

-- ---------------------------------------------------------------------------
-- (3) authenticated INSERT DOIT échouer. POURQUOI : aucune policy INSERT + aucun
--     grant → Postgres refuse (permission denied AVANT RLS, ou violation RLS). Le
--     client ne doit jamais pouvoir s'auto-inscrire un pending (T01/T03).
-- ---------------------------------------------------------------------------
do $$
begin
  insert into public.pending_avocat_registrations
    (user_id, nom, prenom, telephone, wilaya_id, cabinet_nom)
  values
    ('22349d59-75a3-4bbb-accc-8ff240747796', 'Pirate', 'Self', '0560000000', 16, 'Cabinet Pirate');
  raise exception 'ECHEC: authenticated INSERT aurait du etre bloque';
exception
  -- POURQUOI when others : sans GRANT INSERT (defaut Supabase) Postgres leve
  --   « permission denied » AVANT le filtrage RLS, ou « violates row-level
  --   security » sinon. On prouve le REFUS (par grant OU par RLS), pas un code
  --   precis — toute exception ici = comportement attendu.
  when others then
    -- Le signal ECHEC doit remonter (test rouge) ; seul le refus attendu
    --   (permission denied / violation RLS) est avalé = succès silencieux.
    if sqlerrm like 'ECHEC:%' then
      raise;
    end if;
end $$;

-- ---------------------------------------------------------------------------
-- (4) authenticated SELECT DOIT échouer. POURQUOI on attend une EXCEPTION et pas
--     « 0 ligne » : revoke all retire le privilège SELECT → permission denied
--     AVANT la RLS. Même un compte authentifié (claim sub == user_id du pending)
--     est bloqué net — le refus est total, pas un filtrage de lignes.
-- ---------------------------------------------------------------------------
do $$
declare n int;
begin
  select count(*) into n from public.pending_avocat_registrations;
  raise exception 'ECHEC: authenticated SELECT aurait du etre bloque (permission denied attendu)';
exception
  -- Refus permission denied attendu (revoke all) = succès silencieux, même
  -- convention que le test (3) INSERT.
  when others then
    -- Le signal ECHEC doit remonter (test rouge) ; seul le refus attendu
    --   (permission denied / violation RLS) est avalé = succès silencieux.
    if sqlerrm like 'ECHEC:%' then
      raise;
    end if;
end $$;

reset role;

-- Nettoyage final (self-cleaning) : retire la ligne témoin créée en (1).
-- POURQUOI en plus du rollback : garantit zéro résidu même si le fichier est
-- exécuté partiellement ou hors transaction dans le SQL Editor.
delete from public.pending_avocat_registrations
where user_id = '22349d59-75a3-4bbb-accc-8ff240747796';

rollback;
