-- =============================================================================
-- 010_pending_avocat_registrations.sql — Registre serveur des inscriptions
--   avocat EN ATTENTE de confirmation email (28e table, approuvée fondateur)
-- -----------------------------------------------------------------------------
-- POURQUOI cette table (voir STATUS.md § Décisions Verrouillées, 2026-06-28) :
--   l'inscription avocat de niveau entreprise sépare deux instants. À signUp(),
--   on stocke ICI les données avocat/cabinet (nom, prenom, telephone, wilaya_id,
--   cabinet_nom) ; le compte reste un citoyen NON confirmé. La promotion réelle
--   (rpc register_avocat, 009 — crée cabinet + ligne avocats + role='avocat')
--   n'est déclenchée qu'APRÈS confirmation email vérifiée, au premier accès
--   authentifié (logique de promotion idempotente côté route serveur).
-- BÉNÉFICE : aucune donnée orpheline (jamais de cabinet créé pour un email jamais
--   confirmé), identité toujours server-authoritative (les données viennent de ce
--   registre serveur, jamais d'un user_metadata manipulable par le client), et un
--   seul pattern d'auth (confirmation email obligatoire pour tous, avocat inclus).
-- POURQUOI 010 (après wilaya 001) : wilaya_id référence wilaya(id) — la table
--   référencée doit exister (ordre FK, verrouillé STATUS.md).
-- =============================================================================

create table public.pending_avocat_registrations (
  -- POURQUOI PK = user_id : un seul pending par compte ; un re-signup met à jour
  --   le même enregistrement (pas de doublon possible). POURQUOI FK auth.users +
  --   ON DELETE CASCADE : c'est un enregistrement de session auth pure — si le
  --   compte auth disparaît, son pending disparaît avec lui (aucun orphelin).
  user_id     uuid        primary key references auth.users(id) on delete cascade,
  nom         text        not null,
  prenom      text        not null,
  telephone   text,                                              -- nullable : cohérent avec users.telephone (003)
  wilaya_id   smallint    not null references public.wilaya(id), -- POURQUOI not null : la promotion crée un cabinet, qui exige une wilaya (Haversine Phase 2)
  cabinet_nom text        not null,
  created_at  timestamptz not null default now()
  -- POURQUOI pas de updated_at : enregistrement transitoire — écrit une fois (ou
  --   réécrit en bloc à un re-signup), puis supprimé après promotion réussie.
  -- POURQUOI pas de soft delete (exception Rule 10, documentée comme les tables
  --   de jointure) : ce n'est pas une donnée métier à conserver mais un sas
  --   éphémère entre signUp et promotion. Une fois l'avocat créé (cabinets +
  --   avocats portent l'historique), le pending n'a plus aucune valeur d'audit →
  --   hard delete justifié.
);

-- POURQUOI aucun index au-delà de la PK : l'accès se fait UNIQUEMENT par user_id
--   (déjà couvert par l'index B-tree de la clé primaire). Pas de recherche par
--   un autre critère → tout index supplémentaire serait du poids mort.

-- -----------------------------------------------------------------------------
-- Couche GRANT/REVOKE explicite (least privilege) — PLUS STRICTE que 005.
-- POURQUOI revoke d'abord : retire les privilèges hérités de PUBLIC
--   (REFERENCES/TRIGGER/TRUNCATE) — surface minimale, explicite et auditable.
-- POURQUOI AUCUN grant ensuite (contrairement à wilaya/cabinets qui grant SELECT
--   public) : ce registre n'a aucune raison d'être lu ou écrit côté client. Le
--   marketplace ne l'affiche jamais ; seule une route serveur (service_role) y
--   écrit au signUp et le lit/supprime à la promotion. Zéro accès client.
-- POURQUOI service_role absent de ces lignes : il bypass RLS et les grants (rôle
--   privilégié) — il garde son accès total sans qu'on y touche.
-- -----------------------------------------------------------------------------
revoke all on public.pending_avocat_registrations from anon, authenticated, public;

-- -----------------------------------------------------------------------------
-- RLS : refus TOTAL côté client (aucune policy, aucune exception)
-- -----------------------------------------------------------------------------
alter table public.pending_avocat_registrations enable row level security;

-- POURQUOI AUCUNE policy (ni SELECT, ni INSERT, ni UPDATE, ni DELETE) : RLS refuse
--   par défaut tout ce qui n'est pas explicitement autorisé. L'absence TOTALE de
--   policy = refus total pour anon ET authenticated, par design. Seul service_role
--   (route serveur), qui bypasse RLS, écrit/lit/supprime ces lignes. Ce n'est pas
--   un oubli : un client ne doit JAMAIS voir ni toucher un pending — c'est un
--   registre serveur pur (T01/T03 : l'identité et le rôle ne viennent jamais du
--   client). Tests négatifs : tests/rls/pending_avocat_registrations.test.sql.
