-- =============================================================================
-- 006_avocats.sql — Table avocats : extension 1:1 de users (cœur vérification T03)
-- -----------------------------------------------------------------------------
-- POURQUOI 006 (après users 003 + cabinets 005) : avocats.id référence users(id)
--   et avocats.cabinet_id référence cabinets(id) — les deux tables référencées
--   doivent exister d'abord (ordre FK, verrouillé STATUS.md).
-- POURQUOI table d'extension séparée (et pas des colonnes sur users) : seul un
--   user role='avocat' porte un statut de vérification, un n° Barreau, une bio.
--   Isoler ces champs garde la table users propre (citoyen/admin n'en ont pas
--   l'usage) et la PK partagée garantit le 1:1 au niveau base.
-- POURQUOI cœur T03 (Faux Avocat) : la base est la DERNIÈRE ligne de défense.
--   Le statut n'est jamais modifiable côté client ; seul le marketplace public
--   voit les avocats 'verifie' — la RLS l'impose, pas seulement la requête app.
-- =============================================================================

-- POURQUOI ENUM avant la table : la colonne statut l'utilise. Un ENUM verrouille
--   l'ensemble des valeurs au niveau base (pas seulement côté app), comme
--   user_role en 003.
-- POURQUOI 4 valeurs — cycle de vie de la vérification :
--   en_attente : inscrit, attend la revue admin (aucun accès ERP, invisible marketplace) ;
--   verifie    : validé par admin (accès ERP + badge marketplace) ;
--   suspendu   : était validé puis bloqué (sanction, le profil a déjà existé) ;
--   rejete     : admin a refusé, n'a JAMAIS été validé.
-- POURQUOI rejete ≠ suspendu : distinction métier réelle — un rejeté n'a jamais
--   eu accès, un suspendu l'avait et l'a perdu. Audit et réinscription diffèrent.
create type avocat_statut as enum ('en_attente', 'verifie', 'suspendu', 'rejete');

create table public.avocats (
  id                uuid          primary key references public.users(id) on delete cascade,
                    -- POURQUOI PK = users.id (extension 1:1) : un avocat EST un user (role='avocat').
                    --   La PK partagée garantit le 1:1 au niveau base — impossible d'avoir 2 lignes
                    --   avocats pour un même user. on delete cascade : suppression du user → profil avocat supprimé.
  cabinet_id        uuid          not null references public.cabinets(id),
                    -- POURQUOI not null : tout avocat appartient à un cabinet (défaut = son propre
                    --   cabinet solo, R16). Le lien est créé au signup côté serveur.
  statut            avocat_statut not null default 'en_attente',
                    -- POURQUOI default 'en_attente' (T03) : un avocat fraîchement inscrit n'a aucun
                    --   accès ERP ni visibilité marketplace tant qu'un admin ne l'a pas vérifié.
  numero_barreau    text,         -- nullable : n° inscription pro, format validé app-side (SECURITY.md : numérique 4-8). Rempli à l'inscription.
  barreau           text,         -- nullable : Ordre régional ("Barreau d'Oran"). DETTE loggée : à normaliser en table de référence quand la liste officielle UNOA sera disponible.
  verifie_jusqu_a   date,         -- nullable : date d'expiration de la vérification (re-vérification périodique). Colonne schema-ready ; la logique automatique = Future Building.
  bio               text,         -- nullable : présentation publique affichée dans le marketplace.
  annees_experience smallint,     -- nullable : filtre de recherche Phase 2.
  pratique_generale boolean       not null default false,
                    -- POURQUOI booléen (pas 21 lignes de jointure) : un généraliste se déclare via
                    --   ce flag, sémantiquement juste. Recherche Phase 2 : specialite = X OR
                    --   pratique_generale = true. Évite de polluer avocat_specialites et de fausser
                    --   les statistiques par spécialité.
  avatar_url        text,         -- nullable : photo de profil (bucket public, comme les logos cabinets).
  created_at        timestamptz   not null default now(),
  updated_at        timestamptz   not null default now(),
  -- Soft delete (Rule 10) : on ne supprime jamais physiquement une ligne.
  deleted_at        timestamptz,
  deleted_by        uuid,
  deleted_reason    text
);

-- POURQUOI idx cabinet_id : jointures cabinet ↔ avocat (un cabinet liste ses avocats).
-- POURQUOI idx statut : le marketplace Phase 2 filtre WHERE statut = 'verifie' —
--   l'index accélère ce filtre sur la table appelée à grossir.
-- POURQUOI pas d'index sur id : la PK fournit déjà un index B-tree — pas de doublon.
create index idx_avocats_cabinet_id on public.avocats (cabinet_id);
create index idx_avocats_statut     on public.avocats (statut);

-- -----------------------------------------------------------------------------
-- Trigger updated_at : tenir la colonne à jour à chaque UPDATE
-- POURQUOI réutiliser public.set_updated_at() (définie en 003) : une seule
--   source de vérité pour l'horodatage, garanti côté base même via service_role.
-- -----------------------------------------------------------------------------
create trigger trg_avocats_updated_at
  before update on public.avocats
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Couche GRANT/REVOKE explicite (least privilege).
-- POURQUOI revoke d'abord : retire les privilèges hérités de PUBLIC
--   (REFERENCES/TRIGGER/TRUNCATE) — surface minimale, explicite et auditable.
-- POURQUOI grant ensuite : Supabase ne grant plus par défaut (30 mai 2026) ;
--   sans grant explicite la table est injoignable via la Data API.
-- POURQUOI select à anon+authenticated : le marketplace public lit les avocats.
--   La couche GRANT ouvre la porte, la RLS ci-dessous filtre les lignes (seuls
--   les vérifiés sont visibles publiquement).
-- POURQUOI service_role absent : il bypass RLS et les grants (rôle privilégié) — ne pas y toucher.
-- -----------------------------------------------------------------------------
revoke all on public.avocats from anon, authenticated, public;
grant select on public.avocats to anon, authenticated;

-- -----------------------------------------------------------------------------
-- RLS : lecture publique restreinte aux vérifiés, écriture interdite côté client
-- -----------------------------------------------------------------------------
alter table public.avocats enable row level security;

-- POURQUOI statut='verifie' dans la policy (pas seulement dans la requête app) :
--   T03 CRITIQUE — la base est la dernière ligne de défense. Même si une requête
--   Phase 2 oublie le filtre, un avocat en_attente/rejete/suspendu ne fuite
--   JAMAIS publiquement. deleted_at is null : un avocat soft-deleted disparaît.
create policy "avocats_select_public_verifies"
  on public.avocats
  for select
  to anon, authenticated
  using (statut = 'verifie' and deleted_at is null);

-- POURQUOI : un avocat voit SA propre ligne quel que soit son statut — un
--   en_attente doit pouvoir consulter/gérer son profil avant vérification. Les
--   deux policies SELECT se combinent en OR : un avocat vérifié passe par les
--   deux sans conflit.
create policy "avocats_select_own"
  on public.avocats
  for select
  to authenticated
  using (auth.uid() = id);

-- POURQUOI : AUCUNE policy INSERT/UPDATE/DELETE → RLS refuse par défaut toute
--   écriture anon/authenticated. La création au signup, la vérification admin et
--   la modif de profil passent TOUTES par une route serveur service_role (bypass
--   RLS). Le statut (verifie/suspendu/rejete) ne doit JAMAIS être modifiable par
--   le client — sinon un faux avocat s'auto-vérifierait (faille T03 critique). Le
--   hard delete est interdit (Rule 10) : suppression via deleted_at/deleted_by/deleted_reason.
