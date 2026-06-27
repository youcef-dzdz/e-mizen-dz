-- =============================================================================
-- 007_avocat_specialites.sql — Table de jointure N:N : avocats ↔ specialites
-- -----------------------------------------------------------------------------
-- POURQUOI 007 (après avocats 006 + specialites 002) : les deux tables
--   référencées doivent exister d'abord (ordre FK, verrouillé STATUS.md).
-- POURQUOI une table de jointure pure : un avocat a plusieurs spécialités, une
--   spécialité regroupe plusieurs avocats — relation N:N classique. La table ne
--   porte AUCUNE donnée métier propre, seulement le lien entre les deux côtés.
-- POURQUOI lecture publique : le marketplace (Phase 2) affiche les spécialités
--   d'un avocat sans login, et filtre les avocats par spécialité.
--
-- EXCEPTION À LA RULE 10 (soft delete) — JUSTIFIÉE ET DOCUMENTÉE :
--   Cette table est en HARD DELETE, contrairement aux entités métier. POURQUOI :
--   une ligne de jointure pure n'a AUCUNE valeur historique — elle exprime un
--   fait présent (« cet avocat pratique cette spécialité »), pas un événement à
--   tracer. Retirer une spécialité = supprimer la ligne, point. Le soft delete
--   (corbeille deleted_at/deleted_by/deleted_reason) est réservé aux entités
--   métier auditées (dossiers, clients, demandes…), pas aux jointures techniques.
--   Le DELETE reste néanmoins service_role only (aucune policy client) : seul le
--   serveur supprime, jamais le navigateur.
-- =============================================================================

create table public.avocat_specialites (
  avocat_id     uuid     not null references public.avocats(id) on delete cascade,
                -- POURQUOI on delete cascade : si l'avocat est supprimé, ses
                --   associations de spécialités disparaissent avec lui — la
                --   jointure n'a aucun sens sans l'avocat qu'elle qualifie.
  specialite_id smallint not null references public.specialites(id),
                -- POURQUOI pas de cascade ici : une spécialité de référence ne se
                --   supprime pas (catalogue stable, fermé). Si jamais le cas se
                --   présentait, il serait traité à la main, jamais en cascade.
  created_at    timestamptz not null default now(),
                -- POURQUOI created_at sans updated_at : une ligne de jointure ne
                --   se "modifie" pas — elle existe ou non. Aucun trigger
                --   updated_at nécessaire (rien à horodater à la mise à jour).
  primary key (avocat_id, specialite_id)
                -- POURQUOI PK composite : garantit l'unicité de la paire — un
                --   avocat ne peut pas avoir 2x la même spécialité (pas de
                --   doublon). Crée aussi l'index B-tree sur (avocat_id, specialite_id).
);

-- POURQUOI un index sur specialite_id seul : la PK composite indexe
--   (avocat_id, specialite_id) — efficace pour « les spécialités de l'avocat X »
--   (recherche menant par avocat_id). Mais la recherche inverse « les avocats de
--   la spécialité Y » (marketplace Phase 2, filtre par spécialité) a besoin d'un
--   index menant par specialite_id, que la PK ne fournit pas.
-- POURQUOI pas d'index sur avocat_id seul : déjà couvert en tête de PK composite.
create index idx_avocat_specialites_specialite on public.avocat_specialites (specialite_id);

-- POURQUOI pas de trigger updated_at : aucune colonne updated_at — une jointure
--   ne se modifie pas (voir le POURQUOI created_at ci-dessus).

-- -----------------------------------------------------------------------------
-- Couche GRANT/REVOKE explicite (least privilege).
-- POURQUOI revoke d'abord : retire les privilèges hérités de PUBLIC
--   (REFERENCES/TRIGGER/TRUNCATE) — surface minimale, explicite et auditable.
-- POURQUOI grant ensuite : Supabase ne grant plus par défaut (30 mai 2026) ;
--   sans grant explicite la table est injoignable via la Data API.
-- POURQUOI select à anon+authenticated : le marketplace public lit les
--   spécialités d'un avocat. La couche GRANT ouvre la porte, la RLS ci-dessous
--   filtre (ici lecture ouverte, voir le POURQUOI using(true)).
-- POURQUOI service_role absent : il bypass RLS et les grants (rôle privilégié) — ne pas y toucher.
-- -----------------------------------------------------------------------------
revoke all on public.avocat_specialites from anon, authenticated, public;
grant select on public.avocat_specialites to anon, authenticated;

-- -----------------------------------------------------------------------------
-- RLS : lecture publique, écriture interdite côté client
-- -----------------------------------------------------------------------------
alter table public.avocat_specialites enable row level security;

-- POURQUOI using(true) (pas de filtre statut) : c'est la table avocats qui filtre
--   les avocats non vérifiés. Une association pointant vers un avocat en_attente
--   n'est de toute façon pas exploitable publiquement — la jointure avec avocats
--   (dont la RLS exige statut='verifie') ne renverra pas l'avocat. NOTE : si la
--   Phase 2 révèle un besoin de filtrer ici, on ajustera ; pour l'instant SELECT
--   ouvert, cohérent avec specialites (002) et cabinets (005).
create policy "avocat_specialites_select_public"
  on public.avocat_specialites
  for select
  to anon, authenticated
  using (true);

-- POURQUOI : AUCUNE policy INSERT/UPDATE/DELETE → RLS refuse par défaut toute
--   écriture anon/authenticated. L'avocat gère ses spécialités via une route
--   serveur service_role (bypass RLS). Le client ne doit JAMAIS écrire
--   directement — sinon il pourrait s'attribuer des spécialités sur le profil
--   d'un autre avocat. Le DELETE est volontairement hard (jointure pure, voir
--   l'exception Rule 10 en tête de fichier), mais reste serveur only.
