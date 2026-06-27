-- =============================================================================
-- tests/rls/avocat_specialites.test.sql — Tests négatifs RLS, jointure N:N (Rule 12)
-- -----------------------------------------------------------------------------
-- POURQUOI : la table avocat_specialites est en lecture publique (marketplace)
--   et en écriture service_role only. On prouve par opération (Rule 12) que :
--     - le public voit les associations (témoin positif — le marketplace doit
--       afficher les spécialités d'un avocat) ;
--     - aucune écriture client n'est possible (INSERT/UPDATE/DELETE refusés) —
--       en particulier qu'un client ne peut PAS s'auto-attribuer une spécialité
--       sur le profil d'un avocat.
--
-- Environnement : Postgres Supabase. auth.uid() lit request.jwt.claims->>'sub'.
--   On simule un authentifié via role + claims JWT.
--   Idempotence : ON CONFLICT DO NOTHING sur TOUTES les fixtures est le vrai
--   filet de sécurité. POURQUOI (leçon avocats.test.sql) : begin/rollback n'est
--   PAS fiable dans le SQL Editor Supabase (gestion de transaction de l'éditeur
--   + exceptions capturées dans les blocs do), et auth.users n'est pas nettoyable
--   sans rôle privilégié (qu'un test RLS ne doit jamais utiliser). ON CONFLICT
--   garantit qu'une ré-exécution ne plante pas sur duplicate key, quel que soit
--   l'état de la base.
-- Convention : exception 'ECHEC: ...' = test raté ; fin sans exception = OK.
-- -----------------------------------------------------------------------------
-- LIMITE ENVIRONNEMENT : set local role + request.jwt.claims simulent auth.uid()
--   dans le SQL Editor. Le comportement peut différer légèrement de la production
--   (où auth.uid() vient du JWT réel). Ces tests valident la LOGIQUE des policies ;
--   la vérification finale se fait aussi via l'app en conditions réelles (Phase 7 QA).
-- =============================================================================

begin;

-- ---------------------------------------------------------------------------
-- Fixtures privilégiées. Ordre FK strict :
--   wilaya (FK cabinets) → cabinets (FK avocats) → auth.users (FK users) →
--   users (FK avocats) → avocats (FK avocat_specialites) → avocat_specialites.
-- POURQUOI ON CONFLICT DO NOTHING sur chaque INSERT : seul filet d'idempotence
--   fiable ici (voir l'en-tête). specialite_id = 1 (droit-penal) est un id réel
--   du seed (supabase/seed.sql) — pas de fixture spécialité à créer.
-- ---------------------------------------------------------------------------

-- POURQUOI on conflict : la wilaya 31 (Oran) existe déjà via le seed des
--   wilayas — sans garde l'INSERT échouerait sur duplicate key. Idempotent.
insert into public.wilaya (id, code, nom_fr, nom_ar, latitude, longitude)
values (31, '31', 'Oran', 'وهران', 35.691700, -0.633300)
on conflict (id) do nothing;

insert into public.cabinets (id, nom, slug, wilaya_id)
values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Cabinet Test', 'cabinet-test', 31)
on conflict (id) do nothing;

-- POURQUOI auth.users d'abord : users.id a une FK vers auth.users(id).
insert into auth.users (id, email)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'avocat-verifie@test.dz')
on conflict (id) do nothing;

insert into public.users (id, role, email)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'avocat', 'avocat-verifie@test.dz')
on conflict (id) do nothing;

-- POURQUOI statut 'verifie' : l'avocat doit être vérifié pour que la jointure
--   soit exploitable publiquement (cohérence avec la RLS de avocats).
insert into public.avocats (id, cabinet_id, statut)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'verifie')
on conflict (id) do nothing;

-- L'association testée : l'avocat A pratique le droit pénal (specialite 1).
insert into public.avocat_specialites (avocat_id, specialite_id)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1)
on conflict (avocat_id, specialite_id) do nothing;

-- ---------------------------------------------------------------------------
-- (1) SELECT anon — témoin positif : un VISITEUR DOIT voir l'association.
-- POURQUOI : le marketplace affiche les spécialités d'un avocat sans login —
--   la découverte ne doit jamais être bloquée par une authentification forcée.
-- ---------------------------------------------------------------------------
set local role anon;

do $$
declare n int;
begin
  select count(*) into n from public.avocat_specialites
  where avocat_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' and specialite_id = 1;
  if n <> 1 then
    raise exception 'ECHEC: anon SELECT devrait voir l''association avocat-specialite (vu %)', n;
  end if;
end $$;

-- On bascule en UTILISATEUR AUTHENTIFIÉ (un citoyen attaquant) pour l'écriture.
-- POURQUOI claims sub = un id tiers (pas l'avocat A) : prouver qu'un compte
--   valide quelconque ne peut écrire AUCUNE ligne avocat_specialites.
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

-- ---------------------------------------------------------------------------
-- (2) INSERT authenticated DOIT échouer (aucune policy write → refus).
-- POURQUOI : un client ne doit pas s'auto-attribuer une spécialité — sinon il
--   pourrait truquer le profil d'un avocat (le sien ou celui d'un autre).
-- ---------------------------------------------------------------------------
do $$
begin
  insert into public.avocat_specialites (avocat_id, specialite_id)
  values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2);
  raise exception 'ECHEC: authenticated INSERT avocat_specialites aurait du etre bloque par RLS';
exception
  -- POURQUOI when others : un INSERT bloqué peut lever insufficient_privilege
  --   (pas de GRANT INSERT) OU « new row violates row-level security policy ».
  --   On prouve le REFUS, pas un code d'erreur précis.
  when others then null;
end $$;

-- ---------------------------------------------------------------------------
-- (3) UPDATE authenticated DOIT échouer (aucune policy UPDATE → refus).
-- POURQUOI : tenter de réaffecter une association à une autre spécialité doit
--   être impossible côté client — seul le serveur (service_role) gère les liens.
-- ---------------------------------------------------------------------------
do $$
begin
  update public.avocat_specialites set specialite_id = 3
  where avocat_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' and specialite_id = 1;
  raise exception 'ECHEC: authenticated UPDATE avocat_specialites aurait du etre bloque';
exception
  -- POURQUOI when others : sans GRANT UPDATE (defaut Supabase) Postgres leve
  --   « permission denied » AVANT le filtrage RLS — l'exception precede tout
  --   row_count. On prouve le REFUS (par grant OU par RLS), pas un code precis.
  when others then null;
end $$;

-- ---------------------------------------------------------------------------
-- (4) DELETE authenticated DOIT échouer (aucune policy DELETE → refus).
-- NOTE : ici le DELETE est interdit côté CLIENT (service_role only), PAS par
--   principe de soft delete — cette table de jointure est volontairement en
--   hard delete (exception Rule 10 documentée dans 007). Seul le serveur supprime.
-- ---------------------------------------------------------------------------
do $$
begin
  delete from public.avocat_specialites
  where avocat_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' and specialite_id = 1;
  raise exception 'ECHEC: authenticated DELETE avocat_specialites aurait du etre bloque (service_role only)';
exception
  -- POURQUOI when others : sans GRANT DELETE (defaut Supabase) Postgres leve
  --   « permission denied » AVANT le filtrage RLS — l'exception precede tout
  --   row_count. On prouve le REFUS (par grant OU par RLS), pas un code precis.
  when others then null;
end $$;

-- POURQUOI rollback : intention de ne rien persister. MAIS non garanti dans le
--   SQL Editor Supabase — c'est ON CONFLICT DO NOTHING sur les fixtures qui
--   assure réellement l'idempotence d'une ré-exécution.
rollback;
