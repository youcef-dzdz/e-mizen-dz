-- =============================================================================
-- tests/rls/users.test.sql — Tests négatifs RLS, table users (Rule 12)
-- -----------------------------------------------------------------------------
-- POURQUOI : la table users porte des données personnelles. L'isolation des
--   profils est la garantie clé — on prouve qu'un utilisateur A ne peut NI lire
--   NI modifier la ligne d'un utilisateur B, et qu'aucun hard delete n'est
--   possible (soft delete uniquement, Rule 10).
--
-- Environnement : Postgres Supabase. auth.uid() lit request.jwt.claims->>'sub'.
--   On simule un utilisateur authentifié en posant role + claims JWT.
--   Transaction + ROLLBACK → fixtures (auth.users + profils) jamais persistées.
-- Convention : exception 'ECHEC: ...' = test raté ; fin sans exception = OK.
-- =============================================================================

begin;

-- Fixtures privilégiées : deux comptes auth + leurs profils. Annulés au ROLLBACK.
-- POURQUOI auth.users d'abord : users.id a une FK vers auth.users(id).
insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'usera@test.dz'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'userb@test.dz');

insert into public.users (id, role, email) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'citoyen', 'usera@test.dz'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'citoyen', 'userb@test.dz');

-- On s'authentifie en tant qu'utilisateur A.
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

-- (0) Témoin positif : A DOIT voir SON propre profil (sinon la policy est cassée).
do $$
declare n int;
begin
  select count(*) into n from public.users where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  if n <> 1 then
    raise exception 'ECHEC: A devrait voir son propre profil (vu %)', n;
  end if;
end $$;

-- (1) SELECT du profil de B par A DOIT échouer (0 ligne — isolation).
do $$
declare n int;
begin
  select count(*) into n from public.users where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  if n <> 0 then
    raise exception 'ECHEC: A ne doit jamais voir le profil de B (vu %)', n;
  end if;
end $$;

-- (2) UPDATE du profil de B par A DOIT échouer (0 ligne affectée — non visible).
do $$
declare n int;
begin
  update public.users set nom = 'Pirate' where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  get diagnostics n = row_count;
  if n <> 0 then
    raise exception 'ECHEC: A ne doit pas pouvoir modifier B (affecte %)', n;
  end if;
end $$;

-- (3) Hard DELETE DOIT échouer (aucune policy DELETE → 0 ligne, soft delete only).
do $$
declare n int;
begin
  delete from public.users where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  get diagnostics n = row_count;
  if n <> 0 then
    raise exception 'ECHEC: hard DELETE users interdit, attendu 0 ligne (affecte %)', n;
  end if;
end $$;

rollback;
