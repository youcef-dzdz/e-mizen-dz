-- =============================================================================
-- 009_register_avocat.sql — Inscription avocat atomique + verrou du rôle (T01/T03)
-- -----------------------------------------------------------------------------
-- POURQUOI 009 (après users 003, cabinets 005, avocats 006) : la fonction écrit
--   dans ces trois tables dans l'ordre des dépendances FK — elles doivent exister.
-- POURQUOI ce fichier existe : transformer un citoyen en avocat touche 3 tables
--   (cabinets, users.role, avocats). Le faire en 3 appels client = fenêtre de
--   corruption (cabinet créé sans avocat, rôle changé sans cabinet…). Une seule
--   fonction SECURITY DEFINER garantit l'atomicité dans UNE transaction.
-- POURQUOI le trigger garde-fou (Partie 3) : l'audit a montré que `authenticated`
--   a un UPDATE sur TOUTES les colonnes de users (policy users_update_own, 003),
--   y compris role — un client pourrait s'auto-promouvoir avocat/admin (escalade
--   T01/T03). Le trigger verrouille la colonne role contre tout UPDATE client.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- PARTIE 1 — Helper slug
-- POURQUOI une fonction base (et pas côté app) : le slug est généré au cœur de la
--   transaction d'inscription (Partie 2). Le calculer en SQL garantit la même
--   normalisation partout, sans dépendre du client.
-- POURQUOI ne PAS utiliser l'extension unaccent : elle n'est pas activée sur le
--   projet. On translate à la main les accents français courants — suffisant ici.
-- -----------------------------------------------------------------------------
create or replace function public.slugify(p_text text)
returns text
language sql
immutable
as $$
  -- 1. lower() d'abord pour normaliser la casse (et les accents majuscules via lower).
  -- 2. translate() : accents français courants → équivalents ascii.
  -- 3. regexp_replace [^a-z0-9]+ → '-' : tout caractère non alphanumérique devient
  --    un tiret (le quantificateur + collapse déjà les runs en un seul tiret).
  -- 4. regexp_replace '-+' → '-' : sécurité explicite si des tirets se cumulent.
  -- 5. trim(both '-') : retire les tirets en début/fin.
  select trim(both '-' from
           regexp_replace(
             regexp_replace(
               translate(
                 lower(coalesce(p_text, '')),
                 'àâäéèêëîïôöùûüç',
                 'aaaeeeeiioouuuc'
               ),
               '[^a-z0-9]+', '-', 'g'
             ),
             '-+', '-', 'g'
           )
         );
$$;


-- -----------------------------------------------------------------------------
-- PARTIE 2 — Fonction d'inscription atomique
-- POURQUOI SECURITY DEFINER : la fonction écrit dans cabinets/avocats (aucune
--   policy INSERT client, par design 005/006) et change users.role (interdit au
--   client par le trigger Partie 3). Elle s'exécute avec les droits du créateur
--   (le propriétaire), équivalent contrôlé de service_role côté base — même
--   durcissement que handle_new_user (004).
-- POURQUOI search_path figé : empêche le détournement de search_path, faille
--   classique des fonctions SECURITY DEFINER (public + pg_temp uniquement).
-- -----------------------------------------------------------------------------
create or replace function public.register_avocat(
  p_user_id     uuid,
  p_nom         text,
  p_prenom      text,
  p_telephone   text,
  p_wilaya_id   smallint,
  p_cabinet_nom text
)
returns json
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_role       user_role;
  v_cabinet_id uuid;
  v_slug       text;
begin
  -- 1. Éligibilité : seul un citoyen peut devenir avocat. Bloque la double
  --    inscription (avocat existant) ET l'escalade (un admin ne se "réinscrit" pas).
  select role into v_role from public.users where id = p_user_id;
  if not found then
    raise exception 'Utilisateur introuvable';
  end if;
  if v_role <> 'citoyen' then
    raise exception 'Utilisateur non éligible (déjà avocat/admin)';
  end if;

  -- 2. Slug déterministe : slugify(nom) + suffixe = 8 premiers caractères de
  --    l'uuid du cabinet. L'unicité de l'uuid garantit l'unicité du slug —
  --    aucune boucle anti-collision, aucun risque de violer cabinets.slug UNIQUE.
  v_cabinet_id := gen_random_uuid();
  v_slug := slugify(p_cabinet_nom) || '-' || left(v_cabinet_id::text, 8);

  -- 3. Cabinet (tenant root) AVANT l'avocat : avocats.cabinet_id le référence (FK).
  insert into public.cabinets (id, nom, slug, wilaya_id)
  values (v_cabinet_id, p_cabinet_nom, v_slug, p_wilaya_id);

  -- 4. Promotion du profil. updated_at est géré par trg_users_updated_at (003) ;
  --    cet UPDATE de role passe car la fonction tourne en SECURITY DEFINER (son
  --    current_user n'est pas 'authenticated' → le garde-fou Partie 3 la laisse).
  update public.users
     set role      = 'avocat',
         nom       = p_nom,
         prenom    = p_prenom,
         telephone = p_telephone,
         wilaya_id = p_wilaya_id
   where id = p_user_id;

  -- 5. Extension avocat 1:1. statut='en_attente' et pratique_generale=false
  --    proviennent de leurs DEFAULT (006) — on ne les passe pas explicitement :
  --    un avocat fraîchement inscrit attend la vérification admin (T03).
  insert into public.avocats (id, cabinet_id)
  values (p_user_id, v_cabinet_id);

  -- 6. Retour minimal pour la route serveur appelante (redirection, affichage).
  return json_build_object(
    'avocat_id',  p_user_id,
    'cabinet_id', v_cabinet_id,
    'slug',       v_slug
  );
end;
$$;

-- POURQUOI revoke puis grant ciblé : seule une route serveur (service_role) doit
--   pouvoir inscrire un avocat. Exposer cette fonction à anon/authenticated
--   rouvrirait l'escalade que le trigger Partie 3 ferme. Least privilege strict.
revoke execute on function public.register_avocat(uuid, text, text, text, smallint, text)
  from public, anon, authenticated;
grant execute on function public.register_avocat(uuid, text, text, text, smallint, text)
  to service_role;


-- -----------------------------------------------------------------------------
-- PARTIE 3 — Trigger garde-fou du rôle (verrou T01/T03)
-- POURQUOI PAS SECURITY DEFINER ici : le trigger DOIT voir le current_user réel de
--   l'appelant. En SECURITY DEFINER, current_user deviendrait le propriétaire et
--   le test ne distinguerait plus un client d'un appel serveur.
-- POURQUOI current_user et PAS auth.role() : auth.role() lit le JWT et resterait
--   'authenticated' même à l'intérieur de register_avocat (SECURITY DEFINER) — il
--   bloquerait alors l'inscription légitime. current_user, lui, bascule sur le
--   propriétaire dans une fonction SECURITY DEFINER → la rpc passe, le client non.
-- -----------------------------------------------------------------------------
create or replace function public.guard_user_role()
returns trigger
language plpgsql
as $$
begin
  -- Un changement de role provenant directement d'un client (authenticated/anon)
  -- est une tentative d'escalade de privilège → refus. La rpc register_avocat
  -- échappe à ce test car son current_user est le propriétaire de la fonction.
  if old.role is distinct from new.role
     and current_user in ('authenticated', 'anon') then
    raise exception 'Modification du rôle non autorisée';
  end if;
  return new;
end;
$$;

-- POURQUOI DROP IF EXISTS avant CREATE : rend la migration rejouable sans erreur.
drop trigger if exists trg_guard_user_role on public.users;

create trigger trg_guard_user_role
  before update on public.users
  for each row
  execute function public.guard_user_role();
