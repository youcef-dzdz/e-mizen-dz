-- =============================================================================
-- 004_handle_new_user.sql — Création automatique du profil public.users
-- -----------------------------------------------------------------------------
-- POURQUOI un trigger base (et pas seulement la route /api/auth/create-profile) :
--   approche atomique et fiable. Dès qu'une ligne auth.users est créée, le profil
--   public.users l'est aussi, dans la même transaction — impossible d'avoir un
--   auth.users orphelin si le client ferme l'onglet (dette orphelins, STATUS.md).
-- POURQUOI role hardcodé 'citoyen' ici aussi : la création du profil ne doit JAMAIS
--   accepter un rôle venu du client — empêche l'escalade de privilège (T01/T03).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Fonction déclenchée à chaque nouvel auth.users
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
-- POURQUOI SECURITY DEFINER : la fonction insère dans public.users en contournant
--   RLS (la table n'a aucune policy INSERT client, par design — 003). Elle s'exécute
--   avec les droits du créateur de la fonction, pas de l'utilisateur. C'est
--   l'équivalent contrôlé de service_role, côté base.
security definer
-- POURQUOI search_path explicite et figé : empêche le détournement de search_path,
--   faille classique des fonctions SECURITY DEFINER (un schéma malveillant en tête
--   de chemin pourrait masquer public). On épingle public + pg_temp.
set search_path = public, pg_temp
as $$
begin
  -- id et email viennent de NEW (la ligne auth.users tout juste insérée) : sources
  -- vérifiées côté base, jamais d'entrée client. role forcé à 'citoyen' (T01/T03).
  -- locale/created_at/updated_at prennent leurs valeurs par défaut DB (003).
  insert into public.users (id, email, role)
  values (new.id, new.email, 'citoyen');

  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Trigger : relie la fonction à auth.users
-- -----------------------------------------------------------------------------
-- POURQUOI DROP IF EXISTS avant CREATE : rend la migration rejouable sans erreur.
drop trigger if exists on_auth_user_created on auth.users;

-- POURQUOI AFTER INSERT (pas BEFORE) : la ligne auth.users doit être committée pour
--   que son id existe, sinon la FK de public.users (id references auth.users) échoue.
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
