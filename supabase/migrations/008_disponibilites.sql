-- =============================================================================
-- 008_disponibilites.sql — Créneaux de disponibilité hebdomadaire des avocats
-- -----------------------------------------------------------------------------
-- POURQUOI 008 (après avocats 006) : disponibilites.avocat_id référence
--   avocats(id) — la table référencée doit exister d'abord (ordre FK, STATUS.md).
-- POURQUOI un modèle RÉCURRENT HEBDOMADAIRE (jour de semaine, pas de dates) :
--   l'avocat déclare ses créneaux par jour (« lundi 9h-12h ») pour AFFICHAGE sur
--   son profil public (Phase 1). Ce n'est PAS un système de réservation — le
--   booking (créneaux datés, prise de RDV) est hors scope MVP.
-- POURQUOI id uuid propre (et pas une PK composite) : un avocat peut avoir
--   PLUSIEURS créneaux le même jour (ex: lundi 9h-12h ET lundi 14h-17h) — une PK
--   (avocat_id, jour_semaine) interdirait ce cas légitime.
-- POURQUOI soft delete ici (Rule 10), contrairement à avocat_specialites (007) :
--   ce n'est PAS une jointure pure mais une donnée métier (les horaires de
--   l'avocat). Un créneau retiré garde une valeur d'historique léger (l'avocat
--   change ses horaires) — on suit donc Rule 10 par défaut, suppression logique.
-- =============================================================================

create table public.disponibilites (
  id             uuid        primary key default gen_random_uuid(),
  avocat_id      uuid        not null references public.avocats(id) on delete cascade,
                 -- POURQUOI on delete cascade : un créneau n'a aucun sens sans
                 --   l'avocat qu'il concerne — il disparaît avec lui.
  jour_semaine   smallint    not null,
                 -- POURQUOI smallint ISO 8601 (lundi=1 ... dimanche=7) : norme
                 --   internationale, léger, pas besoin d'un enum dédié. NOTE
                 --   Algérie : le week-end est vendredi-samedi, mais les 7 jours
                 --   restent ouverts — aucune hypothèse de week-end câblée ici.
  heure_debut    time        not null,
  heure_fin      time        not null,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  -- Soft delete (Rule 10) : on ne supprime jamais physiquement une ligne.
  deleted_at     timestamptz,
  deleted_by     uuid,
  deleted_reason text,
  -- POURQUOI ce CHECK : empêche un jour invalide (0, 8…) d'entrer en base — la
  --   base protège la donnée, pas seulement la validation app (R20, défense base).
  constraint disponibilites_jour_valide check (jour_semaine between 1 and 7),
  -- POURQUOI ce CHECK : un créneau doit finir après son début — bloque un
  --   « 14h-9h » incohérent au niveau base.
  constraint disponibilites_heures_coherentes check (heure_fin > heure_debut)
);

-- POURQUOI idx avocat_id : afficher les créneaux d'un avocat est la requête
--   fréquente du profil public — l'index l'accélère sur la table appelée à grossir.
create index idx_disponibilites_avocat_id on public.disponibilites (avocat_id);

-- -----------------------------------------------------------------------------
-- Trigger updated_at : tenir la colonne à jour à chaque UPDATE
-- POURQUOI réutiliser public.set_updated_at() (définie en 003) : une seule
--   source de vérité pour l'horodatage, garanti côté base même via service_role.
-- -----------------------------------------------------------------------------
create trigger trg_disponibilites_updated_at
  before update on public.disponibilites
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Couche GRANT/REVOKE explicite (least privilege).
-- POURQUOI revoke d'abord : retire les privilèges hérités de PUBLIC
--   (REFERENCES/TRIGGER/TRUNCATE) — surface minimale, explicite et auditable.
-- POURQUOI grant ensuite : Supabase ne grant plus par défaut (30 mai 2026) ;
--   sans grant explicite la table est injoignable via la Data API.
-- POURQUOI select à anon+authenticated : le profil public affiche les
--   disponibilités. La couche GRANT ouvre la porte, la RLS ci-dessous filtre
--   (les créneaux soft-deleted disparaissent).
-- POURQUOI service_role absent : il bypass RLS et les grants (rôle privilégié) — ne pas y toucher.
-- -----------------------------------------------------------------------------
revoke all on public.disponibilites from anon, authenticated, public;
grant select on public.disponibilites to anon, authenticated;

-- -----------------------------------------------------------------------------
-- RLS : lecture publique des créneaux actifs, écriture interdite côté client
-- -----------------------------------------------------------------------------
alter table public.disponibilites enable row level security;

-- POURQUOI deleted_at is null : un créneau soft-deleted disparaît de l'affichage
--   public — le filtre vit dans la policy (dernière ligne de défense), pas
--   seulement dans la requête app.
create policy "disponibilites_select_public"
  on public.disponibilites
  for select
  to anon, authenticated
  using (deleted_at is null);

-- POURQUOI : AUCUNE policy INSERT/UPDATE/DELETE → RLS refuse par défaut toute
--   écriture anon/authenticated. L'avocat gère ses créneaux via une route serveur
--   service_role (bypass RLS). Le client ne doit JAMAIS écrire directement —
--   sinon il pourrait modifier les horaires d'un autre avocat. Le hard delete est
--   interdit (Rule 10) : suppression via deleted_at/deleted_by/deleted_reason.
