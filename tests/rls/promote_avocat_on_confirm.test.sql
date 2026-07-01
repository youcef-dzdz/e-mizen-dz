-- =============================================================================
-- tests/rls/promote_avocat_on_confirm.test.sql — Tests du trigger de promotion
--   avocat déclenché par la confirmation email (012)
-- -----------------------------------------------------------------------------
-- POURQUOI une simulation et non un vrai signUp : on ne peut PAS provoquer un vrai
--   cycle signUp → email → clic depuis le SQL Editor. On SIMULE donc la transition
--   de confirmation (email_confirmed_at NULL → NOT NULL) sur le compte de test réel
--   22349d59-75a3-4bbb-accc-8ff240747796 (déjà présent dans auth.users, créé via le
--   Dashboard Auth ; le trigger 004 lui a déjà donné une ligne public.users citoyen).
--   Exécuté en postgres → RLS et garde-fou role contournés (current_user = postgres).
--
-- POURQUOI forcer la transition NULL → NOT NULL : le trigger 012 ne se déclenche
--   QUE sur cette transition (clause WHEN). On remet donc email_confirmed_at à NULL
--   puis à now() pour reproduire fidèlement « email confirmé pour la première fois »
--   et déclencher promote_avocat_on_email_confirm().
--
-- ATTENTION — REPLI STRUCTUREL : si l'UPDATE de auth.users échoue dans votre
--   environnement (permissions restreintes sur la table système Supabase), la
--   validation comportementale (TEST 1/2) n'est pas exécutable ici → elle est
--   reportée en E2E Phase 7 (vrai signUp + confirmation). Dans ce cas, commentez
--   les blocs TEST 1/2 et conservez le TEST 0 (vérification structurelle : fonction
--   + trigger présents et actifs, comme handle_new_avocat_pending.test.sql 011).
--   Essayez D'ABORD la simulation réelle ci-dessous ; en postgres dans le SQL
--   Editor Supabase, l'UPDATE de auth.users passe généralement.
--
-- POURQUOI remettre email_confirmed_at à now() au nettoyage final (et JAMAIS le
--   laisser à NULL) : 22349d59 est un VRAI compte. Le laisser non confirmé le
--   casserait (impossible de se connecter). On le restaure à un état confirmé
--   cohérent.
--
-- Convention : exception 'ECHEC: ...' = test rouge visible ; fin propre sans
--   erreur (« select all → Run → Success ») = tous les tests passent. Les handlers
--   laissent TOUJOURS remonter une exception 'ECHEC:%' (if sqlerrm like 'ECHEC:%'
--   then raise) pour ne jamais masquer un échec réel.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- TEST 0 — Structurel : la fonction et le trigger 012 existent et sont actifs.
-- POURQUOI le garder même avec la simulation : c'est le filet minimal. Si la
--   simulation n'est pas exécutable (repli structurel), TEST 0 reste la preuve que
--   la migration 012 a bien été appliquée.
-- -----------------------------------------------------------------------------
do $$
declare n int; r record;
begin
  -- (a) Fonction de promotion présente.
  select count(*) into n
  from pg_proc p
  join pg_namespace ns on ns.oid = p.pronamespace
  where ns.nspname = 'public'
    and p.proname = 'promote_avocat_on_email_confirm';
  if n <> 1 then
    raise exception 'ECHEC: TEST 0 — fonction public.promote_avocat_on_email_confirm introuvable (vu %)', n;
  end if;

  -- (b) Trigger présent ET activé (tgenabled = 'O' = Origin, mode normal).
  select tgname, tgenabled into r
  from pg_trigger
  where tgname = 'on_auth_email_confirmed_promote'
    and not tgisinternal;
  if not found then
    raise exception 'ECHEC: TEST 0 — trigger on_auth_email_confirmed_promote introuvable sur auth.users';
  end if;
  if r.tgenabled <> 'O' then
    raise exception 'ECHEC: TEST 0 — trigger on_auth_email_confirmed_promote desactive (tgenabled = %)', r.tgenabled;
  end if;
end $$;


-- -----------------------------------------------------------------------------
-- NETTOYAGE INITIAL (rejouabilité) — exécuté en postgres, RLS + garde-fou off.
-- POURQUOI ordre avocats → cabinets : avocats.cabinet_id référence cabinets (FK).
-- POURQUOI reset du rôle à 'citoyen' : rend la fixture pending promouvable (la
--   garde interne de register_avocat exige role = 'citoyen').
-- -----------------------------------------------------------------------------
do $$
begin
  delete from public.avocats
   where id = '22349d59-75a3-4bbb-accc-8ff240747796'
      or cabinet_id in (
           select id from public.cabinets where nom = 'Cabinet Promo'
         );

  delete from public.cabinets where nom = 'Cabinet Promo';

  delete from public.pending_avocat_registrations
   where user_id = '22349d59-75a3-4bbb-accc-8ff240747796';

  update public.users
     set role = 'citoyen', nom = null, prenom = null, telephone = null
   where id = '22349d59-75a3-4bbb-accc-8ff240747796';
end $$;


-- -----------------------------------------------------------------------------
-- FIXTURES idempotentes.
-- Wilaya de test (garantit la FK cabinets.wilaya_id même si le seed n'a pas tourné).
-- -----------------------------------------------------------------------------
insert into public.wilaya (id, code, nom_fr, nom_ar, latitude, longitude)
values (16, '16', 'Alger', 'الجزائر', 36.753800, 3.058800)
on conflict (id) do nothing;

-- Pending de test : l'acteur que le trigger 012 doit promouvoir à la confirmation.
insert into public.pending_avocat_registrations
  (user_id, nom, prenom, telephone, wilaya_id, cabinet_nom)
values
  ('22349d59-75a3-4bbb-accc-8ff240747796', 'Promo', 'Test', null, 16::smallint, 'Cabinet Promo');


-- -----------------------------------------------------------------------------
-- TEST 1 — Déclenchement : la confirmation email promeut l'avocat.
-- POURQUOI deux UPDATE : reset à NULL puis à now() pour forcer la transition
--   NULL → NOT NULL exigée par la clause WHEN du trigger.
-- Vérifie : role='avocat' (promu) ET aucun pending restant (supprimé après succès)
--   ET exactement 1 ligne avocats en statut='en_attente'.
-- -----------------------------------------------------------------------------
do $$
declare
  v_role        user_role;
  v_pending_cnt int;
  v_av_cnt      int;
  v_statut      avocat_statut;
begin
  -- Simulation de la confirmation email (déclenche le trigger 012).
  update auth.users set email_confirmed_at = null
   where id = '22349d59-75a3-4bbb-accc-8ff240747796';
  update auth.users set email_confirmed_at = now()
   where id = '22349d59-75a3-4bbb-accc-8ff240747796';

  select role into v_role
    from public.users where id = '22349d59-75a3-4bbb-accc-8ff240747796';

  select count(*) into v_pending_cnt
    from public.pending_avocat_registrations
   where user_id = '22349d59-75a3-4bbb-accc-8ff240747796';

  select count(*) into v_av_cnt
    from public.avocats where id = '22349d59-75a3-4bbb-accc-8ff240747796';

  select statut into v_statut
    from public.avocats where id = '22349d59-75a3-4bbb-accc-8ff240747796';

  -- Succès = toutes les conditions vraies → succès silencieux ; le moindre écart
  --   lève ECHEC = test rouge visible.
  if not (v_role = 'avocat'
     and v_pending_cnt = 0
     and v_av_cnt = 1
     and v_statut = 'en_attente') then
    raise exception 'ECHEC: TEST 1 — promotion non effectuee (role=% pending=% avocat=% statut=%)',
      v_role, v_pending_cnt, v_av_cnt, v_statut;
  end if;
end $$;


-- -----------------------------------------------------------------------------
-- TEST 2 — Idempotence : re-déclencher la transition sur un compte DÉJÀ avocat
--   ne casse rien. Le pending ayant été supprimé au TEST 1, le trigger sort à
--   l'étape 1 (not found) → no-op pur, aucune exception, role reste 'avocat'.
-- POURQUOI ce test : prouve qu'un double-déclenchement (rouverture du lien,
--   re-confirm) n'entraîne ni double promotion ni erreur remontée à auth.users.
-- -----------------------------------------------------------------------------
do $$
declare
  v_role user_role;
begin
  -- Re-simulation de la transition de confirmation sur l'utilisateur déjà avocat.
  update auth.users set email_confirmed_at = null
   where id = '22349d59-75a3-4bbb-accc-8ff240747796';
  update auth.users set email_confirmed_at = now()
   where id = '22349d59-75a3-4bbb-accc-8ff240747796';

  select role into v_role
    from public.users where id = '22349d59-75a3-4bbb-accc-8ff240747796';

  -- Aucune exception ne doit casser la transition, et le role reste 'avocat'.
  if v_role <> 'avocat' then
    raise exception 'ECHEC: TEST 2 — idempotence brisee (role attendu avocat, vu %)', v_role;
  end if;
exception
  -- Si une exception remonte jusqu'ici, c'est que le trigger a fait échouer la
  --   confirmation (interdit). On laisse remonter un ECHEC déjà formé, sinon on en
  --   formule un pour la rendre visible.
  when others then
    if sqlerrm like 'ECHEC:%' then
      raise;
    else
      raise exception 'ECHEC: TEST 2 — la confirmation a echoue a cause de la promotion: %', sqlerrm;
    end if;
end $$;


-- -----------------------------------------------------------------------------
-- NETTOYAGE FINAL (self-cleaning) — exécuté en postgres, RLS + garde-fou off.
-- POURQUOI : remet l'environnement dans l'état initial (compte citoyen, aucune
--   donnée de test résiduelle) pour une ré-exécution propre.
-- POURQUOI ordre avocats → cabinets : avocats.cabinet_id référence cabinets (FK).
-- POURQUOI email_confirmed_at = now() (et JAMAIS null) : 22349d59 est un VRAI
--   compte ; le laisser non confirmé le rendrait inutilisable. On le restaure dans
--   un état confirmé cohérent.
-- -----------------------------------------------------------------------------
do $$
begin
  delete from public.avocats
   where id = '22349d59-75a3-4bbb-accc-8ff240747796'
      or cabinet_id in (
           select id from public.cabinets where nom = 'Cabinet Promo'
         );

  delete from public.cabinets where nom = 'Cabinet Promo';

  delete from public.pending_avocat_registrations
   where user_id = '22349d59-75a3-4bbb-accc-8ff240747796';

  update public.users
     set role = 'citoyen', nom = null, prenom = null, telephone = null
   where id = '22349d59-75a3-4bbb-accc-8ff240747796';

  -- Restaure un email confirmé cohérent (compte réel — ne jamais le laisser NULL).
  update auth.users set email_confirmed_at = now()
   where id = '22349d59-75a3-4bbb-accc-8ff240747796';
end $$;
