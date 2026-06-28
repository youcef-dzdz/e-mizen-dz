-- =============================================================================
-- 011_handle_new_avocat_pending.sql — Trigger défensif : sas pending avocat
-- -----------------------------------------------------------------------------
-- PRINCIPE DÉFENSIF ABSOLU : ce trigger ne doit JAMAIS faire échouer le signUp.
--   À signUp(), le navigateur passe options.data = { intent:'avocat', nom, prenom,
--   telephone, wilaya_id, cabinet_nom } → stocké dans auth.users.raw_user_meta_data.
--   Ce trigger lit ces données et écrit UNE ligne pending_avocat_registrations (010).
--   Si l'intent n'est pas avocat, OU si un champ obligatoire manque, OU si la
--   wilaya_id est illisible/invalide (FK), il n'écrit RIEN et laisse le compte en
--   citoyen normal. Toute la logique d'écriture est sous garde exception → le pire
--   cas est « pas de pending écrit », jamais un signUp en échec (compte à ré-inscrire).
-- POURQUOI un trigger SÉPARÉ de 004 (handle_new_user) et non une extension de
--   celui-ci : responsabilité unique. 004 a une seule mission — créer le profil
--   citoyen public.users, et elle ne doit JAMAIS pouvoir échouer à cause de la
--   logique avocat. Deux triggers AFTER INSERT indépendants : si 011 abandonne en
--   silence, 004 a déjà créé le citoyen, intact. La promotion réelle (rpc
--   register_avocat, 009 — crée cabinet + ligne avocats + role='avocat') reste
--   post-confirmation email, jamais ici.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Fonction déclenchée à chaque nouvel auth.users (en plus de handle_new_user)
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_avocat_pending()
returns trigger
language plpgsql
-- POURQUOI SECURITY DEFINER : la fonction insère dans pending_avocat_registrations
--   qui n'a AUCUNE policy INSERT client (010 — registre serveur pur). Elle s'exécute
--   avec les droits du créateur, pas de l'utilisateur. Même durcissement que 004.
security definer
-- POURQUOI search_path explicite et figé : empêche le détournement de search_path,
--   faille classique des fonctions SECURITY DEFINER. On épingle public + pg_temp.
set search_path = public, pg_temp
as $$
declare
  v_intent      text     := new.raw_user_meta_data->>'intent';
  v_nom         text     := new.raw_user_meta_data->>'nom';
  v_prenom      text     := new.raw_user_meta_data->>'prenom';
  v_telephone   text     := new.raw_user_meta_data->>'telephone';
  v_wilaya_id   smallint;
  v_cabinet_nom text     := new.raw_user_meta_data->>'cabinet_nom';
begin
  -- 1. Pas un avocat → on ne fait rien (citoyen normal). Sortie immédiate.
  --    is distinct from gère aussi le cas intent NULL (signUp citoyen classique).
  if v_intent is distinct from 'avocat' then
    return new;
  end if;

  -- 2. Conversion défensive de wilaya_id (texte JSON → smallint). Si non numérique
  --    ou hors plage → on capture et on sort sans écrire (pas d'échec signUp).
  begin
    v_wilaya_id := (new.raw_user_meta_data->>'wilaya_id')::smallint;
  exception when others then
    return new; -- wilaya_id illisible : on abandonne le pending, citoyen normal.
  end;

  -- 3. Champs obligatoires manquants → pas de pending (mais signUp réussit).
  --    On vérifie NULL ET chaîne vide après trim (un champ rempli d'espaces n'est
  --    pas une donnée valide pour la promotion).
  if v_nom is null or v_prenom is null or v_wilaya_id is null or v_cabinet_nom is null
     or length(trim(v_nom)) = 0 or length(trim(v_prenom)) = 0 or length(trim(v_cabinet_nom)) = 0 then
    return new;
  end if;

  -- 4. INSERT pending défensif : toute erreur (FK wilaya invalide, doublon PK…)
  --    est capturée → JAMAIS d'échec de signUp. Pire cas = pas de pending écrit.
  begin
    insert into public.pending_avocat_registrations
      (user_id, nom, prenom, telephone, wilaya_id, cabinet_nom)
    values
      (new.id, v_nom, v_prenom, v_telephone, v_wilaya_id, v_cabinet_nom);
  exception when others then
    null; -- échec silencieux : le compte reste citoyen, à ré-inscrire.
  end;

  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Trigger : relie la fonction à auth.users
-- -----------------------------------------------------------------------------
-- POURQUOI DROP IF EXISTS avant CREATE : rend la migration rejouable sans erreur.
drop trigger if exists on_auth_user_avocat_pending on auth.users;

-- POURQUOI AFTER INSERT (pas BEFORE) : la ligne auth.users doit être committée pour
--   que new.id existe — la FK user_id → auth.users(id) de pending (010) l'exige.
--   Indépendant de on_auth_user_created (004) : deux triggers AFTER INSERT distincts.
create trigger on_auth_user_avocat_pending
  after insert on auth.users
  for each row
  execute function public.handle_new_avocat_pending();
