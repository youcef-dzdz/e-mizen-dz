-- =============================================================================
-- 003_users.sql — Table profil liée à auth.users (RBAC-ready)
-- -----------------------------------------------------------------------------
-- POURQUOI 003 (après wilaya/specialites) : users.wilaya_id référence wilaya(id)
--   créée en 001 — la table référencée doit exister d'abord.
-- POURQUOI role à 3 valeurs fixes : Visiteur/Citoyen/Client sont gérés ailleurs
--   (Visiteur = non authentifié ; Client = état métier, pas un rôle). Le RBAC
--   cabinet multi-collaborateurs (Phase 3) s'ajoutera de façon ADDITIVE
--   (nouvelles tables membership), sans réécrire ce schéma (voir STATUS.md).
-- =============================================================================

-- POURQUOI ENUMs avant la table : la colonne role/locale les utilise. Un ENUM
--   verrouille l'ensemble des valeurs au niveau base (pas seulement côté app).
create type user_role   as enum ('citoyen', 'avocat', 'admin');
create type user_locale as enum ('fr', 'ar', 'en');

create table public.users (
  id             uuid        primary key references auth.users(id) on delete cascade, -- POURQUOI cascade : suppression du compte auth → profil supprimé avec
  role           user_role   not null,
  email          text        not null,
  nom            text,
  prenom         text,
  telephone      text,                                  -- nullable ; format algérien validé côté app (voir SECURITY.md)
  wilaya_id      smallint    references public.wilaya(id), -- nullable : citoyen peut l'omettre, avocat requis (imposé côté app)
  locale         user_locale not null default 'fr',
  avatar_url     text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  -- Soft delete (Rule 10) : on ne supprime jamais physiquement une ligne.
  deleted_at     timestamptz,
  deleted_by     uuid,
  deleted_reason text
);

-- POURQUOI : filtres admin par rôle + jointures par wilaya (statistiques Phase 5)
create index idx_users_role      on public.users (role);
create index idx_users_wilaya_id on public.users (wilaya_id);

-- -----------------------------------------------------------------------------
-- Trigger updated_at : tenir la colonne à jour à chaque UPDATE
-- POURQUOI côté base et pas seulement app : garantit l'horodatage même si une
--   mise à jour passe par service_role ou un script, sans dépendre du client.
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_users_updated_at
  before update on public.users
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS : un utilisateur ne voit/modifie QUE sa propre ligne
-- -----------------------------------------------------------------------------
alter table public.users enable row level security;

-- POURQUOI : isolation absolue des profils — aucun utilisateur ne lit la ligne
--   d'un autre. auth.uid() = l'utilisateur authentifié courant.
create policy "users_select_own"
  on public.users
  for select
  to authenticated
  using (auth.uid() = id);

-- POURQUOI : un utilisateur ne met à jour que son propre profil. WITH CHECK
--   empêche de réécrire l'id pour usurper une autre ligne pendant l'UPDATE.
create policy "users_update_own"
  on public.users
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- POURQUOI : AUCUNE policy DELETE → le hard delete est interdit (Rule 10). La
--   suppression se fait par deleted_at/deleted_by/deleted_reason via une route
--   serveur. AUCUNE policy INSERT côté client non plus : la création du profil
--   au signup passe par service_role (serveur), qui bypasse RLS.
