-- =============================================================================
-- 002_specialites.sql — Table de référence : spécialités juridiques
-- -----------------------------------------------------------------------------
-- POURQUOI 002 (après wilaya, avant users) : aucune dépendance FK sortante ;
--   regroupée avec wilaya comme donnée de référence publique. users (003) n'en
--   dépend pas directement, mais l'ordre reste cohérent (référence avant métier).
-- POURQUOI donnée publique en lecture seule : les filtres de recherche
--   marketplace (Phase 2) listent les spécialités sans login.
-- NOTE : les lignes de spécialités arrivent dans une tâche de seed SÉPARÉE.
-- =============================================================================

create table public.specialites (
  id          smallint    primary key,
  slug        text        not null unique,     -- URL-safe (ex: "droit-penal") — utilisé dans les URLs de recherche
  nom_fr      text        not null,
  nom_ar      text        not null,
  actif       boolean     not null default true,
  created_at  timestamptz not null default now()
);

-- POURQUOI : la contrainte UNIQUE sur slug crée DÉJÀ un index B-tree
--   (idx unique). Inutile d'ajouter un second index sur slug — ce serait un
--   doublon. La recherche par slug est donc couverte par cette contrainte.

-- -----------------------------------------------------------------------------
-- RLS : lecture publique, écriture interdite côté client
-- -----------------------------------------------------------------------------
alter table public.specialites enable row level security;

-- POURQUOI : les filtres de spécialité doivent s'afficher pour un Visiteur non
--   authentifié — SELECT ouvert à tous.
create policy "specialites_select_public"
  on public.specialites
  for select
  to anon, authenticated
  using (true);

-- POURQUOI : AUCUNE policy INSERT/UPDATE/DELETE → RLS refuse par défaut toute
--   écriture anon/authenticated. La gestion du catalogue passe par service_role
--   (serveur/admin), jamais par un client.
