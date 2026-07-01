-- =============================================================================
-- tests/rls/reset_trigger_test_account.sql — Récupération manuelle du compte de
--   test 22349d59 (trigger 012, promote_avocat_on_confirm)
-- -----------------------------------------------------------------------------
-- SCRIPT DE RÉCUPÉRATION MANUEL — pas une migration, pas exécuté automatiquement.
-- À lancer (Ctrl+A → Run dans le SQL Editor Supabase, en postgres) UNIQUEMENT si
--   l'exécution de tests/rls/promote_avocat_on_confirm.test.sql s'est interrompue
--   en cours de route (erreur, "Run selected" partiel, coupure réseau) et a laissé
--   le compte de test réel 22349d59-75a3-4bbb-accc-8ff240747796
--   (mokhtari.yusif@gmail.com — compte de test jetable, confirmé par le fondateur)
--   dans un état incohérent : email_confirmed_at à NULL, role avocat résiduel, ou
--   lignes pending/avocat/cabinet de test orphelines.
--
-- POURQUOI ce script existe séparément du nettoyage final du test 012 : le
--   nettoyage final de promote_avocat_on_confirm.test.sql ne s'exécute QUE si les
--   blocs précédents du même script ont tourné jusqu'au bout. Une interruption au
--   milieu (ex. TEST 1 échoue et le reste du script n'est jamais lancé) saute ce
--   nettoyage. Ce script est donc un filet de sécurité indépendant, ré-exécutable
--   à tout moment pour remettre le compte dans un état propre connu.
--
-- Résultat après exécution : role='citoyen', email_confirmed_at=now() (confirmé
--   cohérent — compte réel, jamais laissé NULL), aucune ligne pending/avocat/
--   cabinet de test résiduelle. Idempotent — rejouable sans erreur, y compris si
--   le compte est déjà propre.
-- =============================================================================


do $$
begin
  -- POURQUOI ordre avocats → cabinets → pending → users → auth.users : respecte
  --   les dépendances FK (avocats.cabinet_id → cabinets) — on nettoie toujours
  --   l'enfant avant le parent, jamais l'inverse (sinon violation FK).
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

  -- POURQUOI email_confirmed_at = now() et JAMAIS null : 22349d59 est un VRAI
  --   compte de test réel ; le laisser non confirmé le rendrait inutilisable
  --   (connexion impossible). On le restaure dans un état confirmé cohérent.
  update auth.users set email_confirmed_at = now()
   where id = '22349d59-75a3-4bbb-accc-8ff240747796';

  raise notice 'Compte test 22349d59 restaure : citoyen, email confirme, aucune donnee de test residuelle.';
end $$;
