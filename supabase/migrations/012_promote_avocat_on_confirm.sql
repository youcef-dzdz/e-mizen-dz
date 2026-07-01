-- =============================================================================
-- 012_promote_avocat_on_confirm.sql — Trigger défensif : promotion avocat
--   déclenchée par la CONFIRMATION EMAIL (email_confirmed_at NULL → NOT NULL)
-- -----------------------------------------------------------------------------
-- PRINCIPE DÉFENSIF ABSOLU : ce trigger ne doit JAMAIS faire échouer la
--   confirmation email. Toute la logique de promotion (lecture du pending, appel
--   register_avocat 009, suppression du pending) vit sous garde exception. Le pire
--   cas est « pending conservé, promotion retentée plus tard » — jamais une
--   confirmation email en échec (qui laisserait l'utilisateur incapable de se
--   connecter alors qu'il a cliqué le lien).
-- POURQUOI déclenché par email_confirmed_at (événement EN BASE) et non par le
--   callback HTTP : c'est la garantie maximale de niveau entreprise. L'événement
--   de confirmation est atomique côté Postgres et survient quoi qu'il arrive côté
--   client — indépendamment d'un callback HTTP qui échoue (auth_error=1), d'un
--   onglet fermé avant redirection, ou d'un lien rouvert après expiration de la
--   session navigateur. La source de vérité est la transition de la colonne, pas
--   un aller-retour réseau faillible.
-- POURQUOI un trigger SÉPARÉ (et non une extension de 004/011) : responsabilité
--   unique. 011 a une seule mission (écrire le sas pending au signUp) ; 012 a une
--   seule mission (promouvoir à la confirmation). Les chaîner dans une fonction
--   les coupleraient et un échec de l'un menacerait l'autre. La promotion réelle
--   (cabinet + ligne avocats + role='avocat') reste l'affaire de register_avocat
--   (009) — 012 ne fait que l'orchestrer au bon moment, sous garde.
-- POURQUOI 012 (après 009 register_avocat, 010 pending, 011 sas) : la fonction
--   appelle register_avocat (009) et lit pending_avocat_registrations (010) — les
--   deux doivent exister. Ordre de dépendance verrouillé (STATUS.md).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Fonction de promotion, déclenchée à la transition de confirmation email
-- -----------------------------------------------------------------------------
create or replace function public.promote_avocat_on_email_confirm()
returns trigger
language plpgsql
-- POURQUOI SECURITY DEFINER : la fonction appelle register_avocat (009), dont
--   l'EXECUTE est révoqué pour anon/authenticated (réservé service_role), et
--   supprime une ligne de pending_avocat_registrations (010) qui n'a aucune policy
--   client. Elle doit donc tourner avec les droits du créateur. Même durcissement
--   que 004 et 011.
security definer
-- POURQUOI search_path explicite et figé : empêche le détournement de search_path,
--   faille classique des fonctions SECURITY DEFINER. On épingle public + pg_temp.
set search_path = public, pg_temp
as $$
declare
  v_pending public.pending_avocat_registrations%rowtype;
begin
  -- 1. Récupère le pending de cet utilisateur. Pas de pending → c'est un citoyen
  --    normal qui confirme son email : rien à promouvoir, sortie immédiate.
  select * into v_pending
    from public.pending_avocat_registrations
   where user_id = new.id;
  if not found then
    return new;
  end if;

  -- 2. Promotion DÉFENSIVE : toute erreur (register_avocat lève, role déjà avocat,
  --    FK invalide…) est capturée → la confirmation email ne doit JAMAIS échouer à
  --    cause de la promotion. Pire cas = pending conservé, promotion retentée plus
  --    tard (le sas reste, aucune donnée orpheline).
  begin
    perform public.register_avocat(
      v_pending.user_id, v_pending.nom, v_pending.prenom,
      v_pending.telephone, v_pending.wilaya_id, v_pending.cabinet_nom
    );
    -- Succès → on supprime le pending. Idempotence : plus de pending = un
    --   re-déclenchement du trigger sortira à l'étape 1 (not found), aucune
    --   double promotion possible.
    delete from public.pending_avocat_registrations where user_id = new.id;
  exception when others then
    -- Échec : on n'interrompt PAS la confirmation (return new plus bas). Le pending
    --   reste pour une tentative ultérieure. EXCEPTION : si l'erreur est « non
    --   éligible » (double-déclenchement improbable sur un compte déjà avocat),
    --   c'est un no-op bénin — on nettoie quand même le pending résiduel par
    --   sécurité, car il ne sera jamais promu (l'utilisateur n'est plus citoyen).
    if sqlerrm like '%non éligible%' then
      delete from public.pending_avocat_registrations where user_id = new.id;
    end if;
  end;

  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Trigger : relie la fonction à la confirmation email sur auth.users
-- -----------------------------------------------------------------------------
-- POURQUOI DROP IF EXISTS avant CREATE : rend la migration rejouable sans erreur.
drop trigger if exists on_auth_email_confirmed_promote on auth.users;

-- POURQUOI AFTER UPDATE OF email_confirmed_at : on cible précisément la colonne de
--   confirmation. La clause OF limite l'évaluation du trigger aux UPDATE touchant
--   cette colonne (optimisation + intention explicite).
-- POURQUOI WHEN (old NULL and new NOT NULL) : on ne se déclenche QU'à la transition
--   de première confirmation. Sans ce WHEN, le trigger tournerait à chaque update
--   de email_confirmed_at (ex. un re-confirm, un changement d'email) et tenterait
--   une promotion à contretemps. La transition NULL→NOT NULL = « email confirmé
--   pour la première fois », le seul instant où promouvoir.
create trigger on_auth_email_confirmed_promote
  after update of email_confirmed_at on auth.users
  for each row
  when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
  execute function public.promote_avocat_on_email_confirm();
