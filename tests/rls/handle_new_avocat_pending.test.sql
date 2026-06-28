-- =============================================================================
-- tests/rls/handle_new_avocat_pending.test.sql — Tests structurels du trigger
--   défensif pending avocat (011)
-- -----------------------------------------------------------------------------
-- POURQUOI ces tests sont STRUCTURELS et non comportementaux : la fonction
--   handle_new_avocat_pending() ne se déclenche QUE sur un INSERT réel dans
--   auth.users — table système qu'on ne peut PAS alimenter depuis le SQL Editor.
--   On ne peut donc pas fabriquer un trigger NEW à la main ni provoquer le trigger.
--   Insérer manuellement dans pending « selon les mêmes règles » ne testerait PAS
--   la fonction (on testerait notre propre copie de la logique) → sans valeur.
--   On se limite donc à ce qui EST testable sans toucher auth.users : prouver que
--   la fonction et le trigger existent et sont actifs.
--
-- VALIDATION COMPORTEMENTALE COMPLÈTE → E2E via l'app, Phase 7. Elle requiert un
--   vrai INSERT auth.users (signUp réel) et couvre :
--     - signUp avocat (metadata complet)      → 1 ligne pending créée
--     - signUp citoyen (intent absent/autre)  → AUCUN pending, citoyen normal
--     - metadata corrompu (wilaya non num.,   → AUCUN pending, signUp RÉUSSIT
--       champ manquant, FK wilaya invalide)     (principe défensif : jamais d'échec)
--   Ces trois cas ne sont pas reproductibles ici car ils dépendent du déclenchement
--   réel du trigger sur auth.users.
--
-- Convention : exception 'ECHEC: ...' = test raté ; fin sans exception = OK.
-- POURQUOI pas de begin/rollback : uniquement des SELECT de vérification dans le
--   catalogue (pg_proc, pg_trigger). Aucune écriture → rien à annuler, fichier simple.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- (1) La fonction public.handle_new_avocat_pending() DOIT exister. POURQUOI :
--     le trigger référence cette fonction ; si elle manque, la migration 011 n'a
--     pas été appliquée et le sas pending avocat n'existe pas.
-- ---------------------------------------------------------------------------
do $$
declare n int;
begin
  select count(*) into n
  from pg_proc p
  join pg_namespace ns on ns.oid = p.pronamespace
  where ns.nspname = 'public'
    and p.proname = 'handle_new_avocat_pending';
  if n <> 1 then
    raise exception 'ECHEC: fonction public.handle_new_avocat_pending introuvable (vu %)', n;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- (2) Le trigger on_auth_user_avocat_pending DOIT exister ET être activé.
--     POURQUOI tgenabled = 'O' : une fonction présente mais un trigger désactivé
--     (ou absent) = aucun pending jamais écrit, panne silencieuse. 'O' = Origin
--     (activé en mode normal) ; tout autre état (D désactivé, etc.) = ECHEC.
-- ---------------------------------------------------------------------------
do $$
declare r record;
begin
  select tgname, tgenabled into r
  from pg_trigger
  where tgname = 'on_auth_user_avocat_pending'
    and not tgisinternal;
  if not found then
    raise exception 'ECHEC: trigger on_auth_user_avocat_pending introuvable sur auth.users';
  end if;
  if r.tgenabled <> 'O' then
    raise exception 'ECHEC: trigger on_auth_user_avocat_pending desactive (tgenabled = %)', r.tgenabled;
  end if;
end $$;
