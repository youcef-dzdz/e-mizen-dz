-- =============================================================================
-- register_avocat.test.sql — Tests négatifs + happy path de l'inscription avocat
-- -----------------------------------------------------------------------------
-- COUVERTURE (migration 009) :
--   TEST 2 — permissions : authenticated ne peut PAS exécuter register_avocat.
--   TEST 3 — happy path : register_avocat (service/postgres) promeut le citoyen.
--   TEST 4 — éligibilité : ré-inscrire un avocat lève 'Utilisateur non éligible'.
--   (Libellés TEST 2/3/4 conservés tels quels pour rester cohérents avec l'historique.)
--
-- GARDE-FOU role (défense en profondeur) : le trigger trg_guard_user_role (verrou
--   role, migration 009) reste actif EN BASE comme couche de défense en profondeur.
--   Sa validation négative (un client authenticated ne peut pas changer son role)
--   est reportée en Phase 7 (test E2E via l'app, contexte authenticated réel) : le
--   SQL Editor ne reproduit pas fidèlement le contexte de rôle d'une session
--   applicative, rendant ce test non concluant ici.
--
-- POURQUOI rejouable : le fichier nettoie ses propres données AVANT de commencer
--   (lignes avocats/cabinets de test + reset du rôle à 'citoyen'). Exécuté en tant
--   que postgres → RLS et garde-fou contournés (current_user = postgres).
-- POURQUOI les fixtures insèrent une wilaya : 001 précise que les 69 wilayas
--   arrivent dans un seed SÉPARÉ — la table peut être vide ici. Le cabinet de test
--   a une FK wilaya_id ; on garantit la ligne (ON CONFLICT DO NOTHING) pour ne pas
--   dépendre de l'état du seed. Insert défensif, RLS bypassée (postgres).
--
-- UUID de test fixe : 22349d59-75a3-4bbb-accc-8ff240747796 (vrai compte créé via
--   le Dashboard Auth — le trigger 004 a déjà créé sa ligne public.users citoyen).
-- Lecture des résultats : convention alignée sur les 4 anciens tests du projet —
--   toute exception 'ECHEC: ...' = test rouge visible ; fin propre sans erreur
--   (« select all → Run → Success ») = les 4 tests passent.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- NETTOYAGE DÉFENSIF (rejouabilité) — exécuté en postgres, RLS + garde-fou off.
-- POURQUOI ordre avocats → cabinets : avocats.cabinet_id référence cabinets (FK).
-- -----------------------------------------------------------------------------
do $$
begin
  delete from public.avocats
   where id = '22349d59-75a3-4bbb-accc-8ff240747796'
      or cabinet_id in (
           select id from public.cabinets
            where nom in ('Cabinet Test Mizen', 'Cabinet Test Mizen 2')
         );

  delete from public.cabinets
   where nom in ('Cabinet Test Mizen', 'Cabinet Test Mizen 2');

  -- Reset du rôle : rend TEST 3 (happy path) rejouable. current_user = postgres
  -- → le garde-fou guard_user_role laisse passer ce retour à 'citoyen'.
  update public.users
     set role = 'citoyen', nom = null, prenom = null, telephone = null
   where id = '22349d59-75a3-4bbb-accc-8ff240747796';
end $$;


-- -----------------------------------------------------------------------------
-- FIXTURES idempotentes.
-- POURQUOI plus d'INSERT auth.users : le compte de test existe déjà réellement
--   (créé via le Dashboard Auth, vrai UUID), et le trigger 004 a déjà créé sa
--   ligne public.users en citoyen. Un INSERT auth.users depuis un test échouait
--   silencieusement (table système Supabase) — on s'appuie sur le vrai compte.
-- -----------------------------------------------------------------------------
-- Wilaya de test (garantit la FK cabinets.wilaya_id même si le seed n'a pas tourné).
insert into public.wilaya (id, code, nom_fr, nom_ar, latitude, longitude)
values (16, '16', 'Alger', 'الجزائر', 36.753800, 3.058800)
on conflict (id) do nothing;


-- -----------------------------------------------------------------------------
-- TEST 2 — Permissions : authenticated ne peut PAS exécuter register_avocat.
-- POURQUOI : l'EXECUTE est révoqué pour authenticated (009) → seule une route
--   serveur (service_role) inscrit un avocat. Un appel client doit échouer en
--   insufficient_privilege AVANT même d'entrer dans le corps.
-- POURQUOI set local role (et pas set_config('role',...)) : un check de permission
--   EXECUTE est évalué contre current_user. Seul SET LOCAL ROLE change réellement
--   current_user — le GUC 'role' n'est pas toujours consulté au même moment par le
--   contrôle de privilège, ce qui rendrait le test peu fiable. Il impose une
--   transaction explicite ; rollback derrière garantit qu'aucune écriture (ni le
--   rôle de connexion) ne survit au test.
-- -----------------------------------------------------------------------------
begin;

set local role authenticated;

do $$
begin
  perform public.register_avocat(
    '22349d59-75a3-4bbb-accc-8ff240747796',
    'Benali', 'Sofiane', '0550000000', 16::smallint, 'Cabinet Test Mizen'
  );
  -- Si l'appel passe, l'EXECUTE n'était pas révoqué → faille = échec.
  raise exception 'ECHEC: TEST 2 — register_avocat executable par authenticated';
exception
  -- Refus attendu (EXECUTE révoqué) = succès silencieux.
  when insufficient_privilege then null;
  -- Toute autre erreur (y compris notre ECHEC) doit remonter = test rouge.
  when others then raise;
end $$;

reset role;
rollback;


-- -----------------------------------------------------------------------------
-- TEST 3 — Happy path : register_avocat (postgres/service) promeut le citoyen.
-- Vérifie : users.role='avocat', exactement 1 cabinet, slug au format attendu,
--   1 avocat statut='en_attente', cabinet_id cohérent entre cabinet et avocat.
-- -----------------------------------------------------------------------------
do $$
declare
  v_result     json;
  v_cabinet_id uuid;
  v_slug       text;
  v_role       user_role;
  v_cab_count  int;
  v_statut     avocat_statut;
  v_av_cabinet uuid;
begin
  v_result := public.register_avocat(
    '22349d59-75a3-4bbb-accc-8ff240747796',
    'Benali', 'Sofiane', '0551234567', 16::smallint, 'Cabinet Test Mizen'
  );
  v_cabinet_id := (v_result ->> 'cabinet_id')::uuid;
  v_slug       :=  v_result ->> 'slug';

  select role into v_role
    from public.users where id = '22349d59-75a3-4bbb-accc-8ff240747796';

  select count(*) into v_cab_count
    from public.cabinets where id = v_cabinet_id;

  select statut, cabinet_id into v_statut, v_av_cabinet
    from public.avocats where id = '22349d59-75a3-4bbb-accc-8ff240747796';

  -- Succès = toutes les conditions vraies → ne rien faire (succès silencieux).
  --   Le moindre écart lève ECHEC = test rouge visible.
  if not (v_role = 'avocat'
     and v_cab_count = 1
     and v_slug ~ '^cabinet-test-mizen-[0-9a-f]{8}$'
     and v_statut = 'en_attente'
     and v_av_cabinet = v_cabinet_id) then
    raise exception 'ECHEC: TEST 3 — role=% cab_count=% slug=% statut=% cabinet_match=%',
      v_role, v_cab_count, v_slug, v_statut, (v_av_cabinet = v_cabinet_id);
  end if;
end $$;


-- -----------------------------------------------------------------------------
-- TEST 4 — Éligibilité : ré-inscrire le même user (désormais avocat) doit échouer.
-- POURQUOI : empêche la double inscription et l'écrasement d'un cabinet existant.
--   Exécuté en postgres (execute autorisé) → on atteint bien le contrôle métier.
-- -----------------------------------------------------------------------------
do $$
begin
  begin
    perform public.register_avocat(
      '22349d59-75a3-4bbb-accc-8ff240747796',
      'Benali', 'Sofiane', '0551234567', 16::smallint, 'Cabinet Test Mizen 2'
    );
    -- Si l'appel passe, le contrôle d'éligibilité n'a pas bloqué → échec.
    raise exception 'ECHEC: TEST 4 — re-inscription d''un avocat acceptee';
  exception when others then
    -- Refus attendu ('non éligible') = succès silencieux ; toute autre erreur
    --   (y compris une absence de blocage) lève ECHEC = test rouge.
    if sqlerrm like '%non éligible%' then
      null;
    else
      raise exception 'ECHEC: TEST 4 — erreur inattendue: %', sqlerrm;
    end if;
  end;
end $$;


-- -----------------------------------------------------------------------------
-- NETTOYAGE FINAL (self-cleaning) — exécuté en postgres, RLS + garde-fou off.
-- POURQUOI : le test remet l'environnement dans l'état initial (user citoyen,
--   aucune donnée de test résiduelle) afin que toute ré-exécution parte d'un état
--   propre, indépendamment de ce que TEST 3 a committé.
-- POURQUOI ordre avocats → cabinets : avocats.cabinet_id référence cabinets (FK).
-- -----------------------------------------------------------------------------
do $$
begin
  delete from public.avocats
   where id = '22349d59-75a3-4bbb-accc-8ff240747796'
      or cabinet_id in (
           select id from public.cabinets
            where nom in ('Cabinet Test Mizen', 'Cabinet Test Mizen 2')
         );

  delete from public.cabinets
   where nom in ('Cabinet Test Mizen', 'Cabinet Test Mizen 2');

  update public.users
     set role = 'citoyen', nom = null, prenom = null, telephone = null
   where id = '22349d59-75a3-4bbb-accc-8ff240747796';
end $$;
