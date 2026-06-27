-- =============================================================================
-- 005_cabinets.sql — Table cabinets : entité racine (tenant root) du cabinet
-- -----------------------------------------------------------------------------
-- POURQUOI 005 (après wilaya 001) : cabinets.wilaya_id référence wilaya(id) —
--   la table référencée doit exister d'abord (ordre FK, verrouillé STATUS.md).
-- POURQUOI tenant root indépendant : le cabinet n'est PAS lié à un avocat ici.
--   C'est l'avocat qui portera cabinet_id (défaut = avocat.id pour le solo,
--   R16), pas l'inverse. Le RBAC multi-collaborateurs (Phase 3) s'ajoutera de
--   façon ADDITIVE (tables membership) sans réécrire ce schéma.
-- POURQUOI donnée publique en lecture : le cabinet s'affiche dans le marketplace
--   sans login (Visiteur). La restriction « avocat vérifié uniquement » sera
--   appliquée Phase 2 via JOIN sur avocats.statut — PAS dans cette policy.
-- =============================================================================

create table public.cabinets (
  id             uuid        primary key default gen_random_uuid(),
  nom            text        not null,                              -- affiché dans le marketplace
  slug           text        not null unique,                       -- URL publique propre ; généré côté app depuis nom (pas ici)
  wilaya_id      smallint    not null references public.wilaya(id), -- POURQUOI not null : la recherche Haversine (Phase 2) exclut un cabinet sans wilaya — il serait introuvable
  adresse        text,                                              -- nullable : profil public optionnel
  telephone      text,                                              -- nullable : format algérien validé côté app (SECURITY.md)
  logo_url       text,                                              -- nullable : bucket public (logos = seule exception publique, SECURITY.md)
  description    text,                                              -- nullable : présentation du cabinet
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  -- Soft delete (Rule 10) : on ne supprime jamais physiquement une ligne.
  deleted_at     timestamptz,
  deleted_by     uuid,
  deleted_reason text
);

-- POURQUOI : recherche marketplace par wilaya (Phase 2). Le slug a DÉJÀ un index
--   B-tree via la contrainte UNIQUE — inutile d'en ajouter un second (doublon),
--   même logique que specialites (002).
create index idx_cabinets_wilaya_id on public.cabinets (wilaya_id);

-- -----------------------------------------------------------------------------
-- Trigger updated_at : tenir la colonne à jour à chaque UPDATE
-- POURQUOI réutiliser public.set_updated_at() (définie en 003) : une seule
--   source de vérité pour l'horodatage, garanti côté base même via service_role.
-- -----------------------------------------------------------------------------
create trigger trg_cabinets_updated_at
  before update on public.cabinets
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Couche GRANT/REVOKE explicite (least privilege).
-- POURQUOI revoke d'abord : retire les privilèges hérités de PUBLIC
--   (REFERENCES/TRIGGER/TRUNCATE) — surface minimale, explicite et auditable.
-- POURQUOI grant ensuite : Supabase ne grant plus par défaut (30 mai 2026) ;
--   sans grant explicite la table est injoignable via la Data API.
-- POURQUOI service_role absent : il bypass RLS et les grants (rôle privilégié) — ne pas y toucher.
-- -----------------------------------------------------------------------------
revoke all on public.cabinets from anon, authenticated, public;
grant select on public.cabinets to anon, authenticated;

-- -----------------------------------------------------------------------------
-- RLS : lecture publique, écriture interdite côté client
-- -----------------------------------------------------------------------------
alter table public.cabinets enable row level security;

-- POURQUOI : le marketplace public affiche les cabinets sans compte — sinon la
--   découverte serait bloquée par un login forcé (modèle Visiteur). Le filtre
--   « avocat vérifié » viendra Phase 2 via JOIN sur avocats.statut, pas ici.
create policy "cabinets_select_public"
  on public.cabinets
  for select
  to anon, authenticated
  using (true);

-- POURQUOI : AUCUNE policy INSERT/UPDATE/DELETE → RLS refuse par défaut toute
--   écriture anon/authenticated. Toute écriture sur un cabinet (création au
--   signup avocat, modif via paramètres cabinet) passe par une route serveur
--   service_role, qui bypasse RLS. Le hard delete est interdit (Rule 10) :
--   suppression via deleted_at/deleted_by/deleted_reason.
