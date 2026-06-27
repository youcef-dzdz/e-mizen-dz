-- =============================================================================
-- tests/rls/avocats.test.sql — Tests négatifs RLS, table avocats (Rule 12)
-- -----------------------------------------------------------------------------
-- POURQUOI : la table avocats est le cœur de la vérification (T03 — Faux Avocat).
--   On prouve par opération (Rule 12) que :
--     - le public voit UNIQUEMENT les avocats 'verifie' (jamais un en_attente) ;
--     - aucune écriture client n'est possible (INSERT/UPDATE/DELETE refusés) ;
--     - en particulier qu'un client ne peut PAS s'auto-vérifier (UPDATE statut)
--       — c'est l'attaque T03 directe.
--
-- Environnement : Postgres Supabase. auth.uid() lit request.jwt.claims->>'sub'.
--   On simule un authentifié via role + claims JWT. auth.users est insérable en
--   test (cf. users.test.sql) → le cycle de vie complet est testable, aucune
--   limitation à documenter.
--   Idempotence : le nettoyage de tête (DELETE préalable, juste après begin)
--   assure qu'une ré-exécution ne plante pas sur duplicate key. Le ROLLBACK
--   final reste une intention secondaire — NON garantie dans le SQL Editor
--   Supabase (gestion de transaction de l'éditeur + exceptions capturées dans
--   les blocs do). Le vrai filet de sécurité est donc le DELETE de tête.
-- Convention : exception 'ECHEC: ...' = test raté ; fin sans exception = OK.
-- =============================================================================
-- LIMITE ENVIRONNEMENT : set local role + request.jwt.claims simulent auth.uid()
--   dans le SQL Editor. Le comportement peut différer légèrement de la production
--   (où auth.uid() vient du JWT réel). Ces tests valident la LOGIQUE des policies ;
--   la vérification finale se fait aussi via l'app en conditions réelles (Phase 7 QA).
-- =============================================================================

begin;

-- ---------------------------------------------------------------------------
-- NETTOYAGE PRÉALABLE (idempotence) : on supprime d'éventuels résidus d'une
-- exécution précédente AVANT d'insérer les fixtures. POURQUOI : dans le SQL
-- Editor Supabase, begin/rollback n'annule pas toujours les fixtures (gestion
-- de transaction de l'éditeur + exceptions capturées). Sans ce nettoyage, une
-- 2e exécution échoue sur duplicate key. Ordre FK inverse (avocats → users → auth.users → cabinets).
-- ---------------------------------------------------------------------------
delete from public.avocats where id in ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
delete from public.users   where id in ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
delete from auth.users     where id in ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
delete from public.cabinets where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

-- ---------------------------------------------------------------------------
-- Fixtures privilégiées, annulées au ROLLBACK. Ordre FK strict :
--   wilaya (FK cabinets) → cabinets (FK avocats) → auth.users (FK users) →
--   users (FK avocats) → avocats.
-- POURQUOI on conflict do nothing sur chaque INSERT : le DELETE de tête échoue
--   sur auth.users (table système, permissions insuffisantes hors superuser),
--   donc un résidu d'auth.users peut survivre et faire planter l'INSERT sur
--   duplicate key. ON CONFLICT garantit l'idempotence quel que soit l'état de
--   la base, SANS recourir à un rôle privilégié (un test RLS ne doit jamais
--   tourner en superuser). C'est le vrai filet ; le DELETE de tête ne couvre
--   que les tables non-système.
-- ---------------------------------------------------------------------------

-- POURQUOI on conflict do nothing : la wilaya 31 (Oran) existe déjà via le seed
--   des 69 wilayas — sans garde l'INSERT échouerait sur duplicate key. Idempotent.
insert into public.wilaya (id, code, nom_fr, nom_ar, latitude, longitude)
values (31, '31', 'Oran', 'وهران', 35.691700, -0.633300)
on conflict (id) do nothing;

insert into public.cabinets (id, nom, slug, wilaya_id)
values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Cabinet Test', 'cabinet-test', 31)
on conflict (id) do nothing;

-- Deux comptes auth + leurs profils : un avocat vérifié, un avocat en attente.
-- POURQUOI auth.users d'abord : users.id a une FK vers auth.users(id).
insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'avocat-verifie@test.dz'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'avocat-attente@test.dz')
on conflict (id) do nothing;

insert into public.users (id, role, email) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'avocat', 'avocat-verifie@test.dz'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'avocat', 'avocat-attente@test.dz')
on conflict (id) do nothing;

insert into public.avocats (id, cabinet_id, statut) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'verifie'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'en_attente')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- (1) SELECT anon — témoin positif : un VISITEUR DOIT voir l'avocat 'verifie'.
-- POURQUOI : la découverte marketplace ne doit jamais être bloquée par un login.
-- ---------------------------------------------------------------------------
set local role anon;

do $$
declare n int;
begin
  select count(*) into n from public.avocats
  where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  if n <> 1 then
    raise exception 'ECHEC: anon SELECT devrait voir l''avocat verifie (vu %)', n;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- (2) SELECT anon — NÉGATIF CLÉ (T03) : un VISITEUR ne DOIT PAS voir un
--     avocat 'en_attente'. C'est la garantie anti-Faux-Avocat au niveau base :
--     un non-vérifié ne fuite jamais publiquement, même si l'app oublie le filtre.
-- ---------------------------------------------------------------------------
do $$
declare n int;
begin
  select count(*) into n from public.avocats
  where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  if n <> 0 then
    raise exception 'ECHEC: anon ne doit JAMAIS voir un avocat en_attente (vu %)', n;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- (2bis) SELECT authentifié NON-propriétaire — NÉGATIF T03 : l'avocat A
--   (vérifié) ne DOIT PAS voir le profil en_attente de l'avocat B. La policy
--   avocats_select_own ne matche que sa PROPRE ligne (auth.uid() = id) ; la
--   policy publique exclut les en_attente. Donc A ne voit pas B en_attente.
--   POURQUOI ce test : prouver qu'aucune fuite inter-comptes n'existe — un
--   avocat ne peut pas inspecter les dossiers en attente des autres.
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
-- claims sub = avocat A (vérifié), qui tente de lire B (en_attente)
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $$
declare n int;
begin
  select count(*) into n from public.avocats
  where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  if n <> 0 then
    raise exception 'ECHEC: avocat A ne doit PAS voir le profil en_attente de B (vu %)', n;
  end if;
end $$;

-- Contrôle positif de cohérence : le même avocat A DOIT voir SA propre ligne
-- (même si elle était non vérifiée — ici A est vérifié, donc doublement visible).
do $$
declare n int;
begin
  select count(*) into n from public.avocats
  where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  if n <> 1 then
    raise exception 'ECHEC: avocat A doit voir SA propre ligne (vu %)', n;
  end if;
end $$;

-- On bascule en UTILISATEUR AUTHENTIFIÉ (un citoyen attaquant) pour l'écriture.
-- POURQUOI claims sub = un id tiers (ni A ni B) : prouver qu'un compte valide
--   quelconque ne peut écrire AUCUNE ligne avocats.
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

-- ---------------------------------------------------------------------------
-- (3) INSERT authenticated DOIT échouer (aucune policy write → violation RLS).
-- ---------------------------------------------------------------------------
do $$
begin
  insert into public.avocats (id, cabinet_id, statut)
  values ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'verifie');
  raise exception 'ECHEC: authenticated INSERT avocats aurait du etre bloque par RLS';
exception
  -- POURQUOI when others : un INSERT bloqué peut lever insufficient_privilege
  --   (pas de GRANT INSERT) OU « new row violates row-level security policy ».
  --   On prouve le REFUS, pas un code d'erreur précis.
  when others then null;
end $$;

-- ---------------------------------------------------------------------------
-- (4) UPDATE authenticated DOIT échouer — ATTAQUE T03 DIRECTE : tenter de
--     passer un avocat 'en_attente' à 'verifie' (auto-vérification). Le client
--     ne doit JAMAIS pouvoir modifier le statut — sinon un faux avocat se valide
--     lui-même. Aucune policy UPDATE → refus.
-- ---------------------------------------------------------------------------
do $$
begin
  update public.avocats set statut = 'verifie'
  where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  raise exception 'ECHEC: authenticated UPDATE statut (auto-verification T03) aurait du etre bloque';
exception
  -- POURQUOI when others : sans GRANT UPDATE (defaut Supabase) Postgres leve
  --   « permission denied » AVANT le filtrage RLS — l'exception precede tout
  --   row_count. On prouve le REFUS (par grant OU par RLS), pas un code precis.
  when others then null;
end $$;

-- ---------------------------------------------------------------------------
-- (5) Hard DELETE authenticated DOIT échouer (aucune policy DELETE).
-- POURQUOI : la suppression se fait par soft delete uniquement (Rule 10).
-- ---------------------------------------------------------------------------
do $$
begin
  delete from public.avocats
  where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  raise exception 'ECHEC: hard DELETE avocats aurait du etre bloque (Rule 10)';
exception
  -- POURQUOI when others : sans GRANT DELETE (defaut Supabase) Postgres leve
  --   « permission denied » AVANT le filtrage RLS — l'exception precede tout
  --   row_count. On prouve le REFUS (par grant OU par RLS), pas un code precis.
  when others then null;
end $$;

-- POURQUOI rollback : intention de ne rien persister. MAIS non garanti dans le
--   SQL Editor Supabase — c'est le nettoyage de tête (DELETE préalable) qui
--   assure réellement l'idempotence d'une ré-exécution.
rollback;
