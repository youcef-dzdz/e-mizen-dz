-- =============================================================================
-- 001_wilaya.sql — Table de référence : les 69 wilayas d'Algérie
-- -----------------------------------------------------------------------------
-- POURQUOI cette table en premier (001) : aucune dépendance FK sortante, et
--   users.wilaya_id (003) la référence. L'ordre de migration suit les
--   dépendances FK (Option A, verrouillée dans STATUS.md).
-- POURQUOI donnée publique en lecture seule : la découverte marketplace doit
--   fonctionner sans login (Visiteur), et la recherche Haversine (Phase 2)
--   s'appuie sur latitude/longitude.
-- NOTE : 69 wilayas depuis la loi n° 26-06 du 04/04/2026 (n°59-69 = ex-wilayas
--   déléguées). Les 69 lignes de données arrivent dans une tâche de seed SÉPARÉE.
-- =============================================================================

create table public.wilaya (
  id          smallint primary key,            -- numéro officiel de wilaya (1..69)
  code        text         not null,           -- matricule à 2 chiffres (ex: "31") — identifiant administratif
  nom_fr      text         not null,
  nom_ar      text         not null,
  latitude    numeric(9,6) not null,           -- POURQUOI : requis par la recherche Haversine (Phase 2)
  longitude   numeric(9,6) not null,
  actif       boolean      not null default true, -- POURQUOI : période transitoire loi 26-06 — masquer sans supprimer
  created_at  timestamptz  not null default now()
);

-- POURQUOI : recherche/jointure par matricule administratif (filtres marketplace)
create index idx_wilaya_code on public.wilaya (code);

-- -----------------------------------------------------------------------------
-- RLS : lecture publique, écriture interdite côté client
-- -----------------------------------------------------------------------------
alter table public.wilaya enable row level security;

-- POURQUOI : un Visiteur (non authentifié) doit pouvoir lister les wilayas sans
--   compte — sinon la découverte marketplace serait bloquée par un login forcé.
create policy "wilaya_select_public"
  on public.wilaya
  for select
  to anon, authenticated
  using (true);

-- POURQUOI : AUCUNE policy INSERT/UPDATE/DELETE. RLS refuse par défaut → anon et
--   authenticated ne peuvent jamais écrire la donnée de référence. Les
--   modifications (seed, ajustements loi) passent par service_role (serveur),
--   qui bypasse RLS. C'est volontaire, pas un oubli.
