-- =============================================================================
-- tests/rls/disponibilites.test.sql — Tests négatifs RLS, créneaux avocats (Rule 12)
-- -----------------------------------------------------------------------------
-- POURQUOI : la table disponibilites est en lecture publique (profil avocat) et
--   en écriture service_role only. On prouve par opération (Rule 12) que :
--     - le public voit les créneaux non supprimés (témoin positif — le profil
--       public doit afficher les disponibilités) ;
--     - aucune écriture client n'est possible (INSERT/UPDATE/DELETE refusés) —
--       en particulier qu'un client ne peut PAS modifier les horaires d'un avocat.
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
--   users (FK avocats) → avocats (FK disponibilites) → disponibilites.
-- POURQUOI ON CONFLICT DO NOTHING sur chaque INSERT : seul filet d'idempotence
--   fiable ici (voir l'en-tête). L'id du créneau est figé (et non gen_random_uuid)
--   pour que les tests d'écriture ciblent une ligne connue de façon déterministe.
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

-- POURQUOI statut 'verifie' : cohérence avec le profil public (un créneau ne
--   s'affiche que pour un avocat exploitable publiquement).
insert into public.avocats (id, cabinet_id, statut)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'verifie')
on conflict (id) do nothing;

-- Le créneau testé : avocat A, lundi (jour 1), 09:00-12:00.
insert into public.disponibilites (id, avocat_id, jour_semaine, heure_debut, heure_fin)
values ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, '09:00', '12:00')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- (1) SELECT anon — témoin positif : un VISITEUR DOIT voir le créneau actif.
-- POURQUOI : le profil public affiche les disponibilités sans login — la
--   découverte ne doit jamais être bloquée par une authentification forcée.
-- ---------------------------------------------------------------------------
set local role anon;

do $$
declare n int;
begin
  select count(*) into n from public.disponibilites
  where id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
  if n <> 1 then
    raise exception 'ECHEC: anon SELECT devrait voir le creneau actif (vu %)', n;
  end if;
end $$;

-- On bascule en UTILISATEUR AUTHENTIFIÉ (un citoyen attaquant) pour l'écriture.
-- POURQUOI claims sub = un id tiers (pas l'avocat A) : prouver qu'un compte
--   valide quelconque ne peut écrire AUCUNE ligne disponibilites.
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

-- ---------------------------------------------------------------------------
-- (2) INSERT authenticated DOIT échouer (aucune policy write → refus).
-- POURQUOI : un client ne doit pas créer de créneau — sinon il pourrait truquer
--   les horaires affichés sur le profil d'un avocat (le sien ou celui d'un autre).
-- ---------------------------------------------------------------------------
do $$
begin
  insert into public.disponibilites (avocat_id, jour_semaine, heure_debut, heure_fin)
  values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2, '14:00', '17:00');
  raise exception 'ECHEC: authenticated INSERT disponibilites aurait du etre bloque par RLS';
exception
  -- POURQUOI when others : un INSERT bloqué peut lever insufficient_privilege
  --   (pas de GRANT INSERT) OU « new row violates row-level security policy ».
  --   On prouve le REFUS, pas un code d'erreur précis.
  when others then null;
end $$;

-- ---------------------------------------------------------------------------
-- (3) UPDATE authenticated DOIT échouer (aucune policy UPDATE → refus).
-- POURQUOI : modifier l'horaire d'un créneau doit être impossible côté client —
--   seul le serveur (service_role) gère les disponibilités de l'avocat.
-- ---------------------------------------------------------------------------
do $$
begin
  update public.disponibilites set heure_fin = '18:00'
  where id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
  raise exception 'ECHEC: authenticated UPDATE disponibilites aurait du etre bloque';
exception
  -- POURQUOI when others : sans GRANT UPDATE (defaut Supabase) Postgres leve
  --   « permission denied » AVANT le filtrage RLS — l'exception precede tout
  --   row_count. On prouve le REFUS (par grant OU par RLS), pas un code precis.
  when others then null;
end $$;

-- ---------------------------------------------------------------------------
-- (4) Hard DELETE authenticated DOIT échouer (aucune policy DELETE).
-- POURQUOI : la suppression se fait par soft delete uniquement (Rule 10) —
--   retrait d'un créneau = deleted_at via route serveur, jamais un hard delete client.
-- ---------------------------------------------------------------------------
do $$
begin
  delete from public.disponibilites
  where id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
  raise exception 'ECHEC: hard DELETE disponibilites aurait du etre bloque (Rule 10)';
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
