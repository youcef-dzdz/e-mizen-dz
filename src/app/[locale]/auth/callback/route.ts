import { NextResponse } from "next/server";
import { createSupabaseSessionClient } from "@/lib/supabase/server-session";

// Route de callback auth (Phase 0.3) — échange le code PKCE contre une session.
// POURQUOI: c'est le point de retour commun après confirmation d'email ET après
// OAuth (Google). Supabase renvoie l'utilisateur ici avec un `code` en query ;
// on l'échange contre une vraie session, ce qui "connecte" réellement le compte.
// Un route handler ne rend AUCUNE UI — il ne fait que poser le cookie et rediriger.
// Le message d'erreur/succès affiché à l'utilisateur est géré par la page de
// destination (étape ultérieure), jamais ici (Règle 1: pas d'erreur brute exposée).

export async function GET(
  request: Request,
  { params }: { params: { locale: string } },
) {
  const { origin, searchParams } = new URL(request.url);

  // Lu depuis le segment [locale] pour rediriger dans la bonne langue (FR/AR/EN).
  const { locale } = params;

  const code = searchParams.get("code");
  // Cible de redirection post-connexion ; défaut = racine de l'app localisée.
  const next = searchParams.get("next") ?? "/";
  // POURQUOI type=recovery : après l'échange du code, l'utilisateur a une session
  // valide mais doit définir un nouveau mot de passe ; on l'envoie vers la page
  // dédiée au lieu de l'accueil. L'échange du code reste identique (récupération =
  // aussi un code PKCE).
  const type = searchParams.get("type");

  // Construit un chemin propre dans la locale courante en évitant un double slash
  // (next = "/" ne doit pas produire "/fr/").
  const safePath = next.startsWith("/") ? next : `/${next}`;
  const successUrl = `${origin}/${locale}${safePath === "/" ? "" : safePath}`;

  // POURQUOI absolu via l'origin de la requête: NextResponse.redirect exige une URL
  // absolue, et l'origin garantit qu'on reste sur le même hôte (pas d'open redirect).
  const errorUrl = `${origin}/${locale}?auth_error=1`;

  if (code) {
    // Réutilise le client cookie de session (@supabase/ssr) — le même set() de
    // cookies que le middleware/server-session, pour écrire correctement la session.
    const supabase = await createSupabaseSessionClient();

    // POURQUOI: échange le code PKCE contre une vraie session ; @supabase/ssr écrit
    // le cookie de session via le set() du client (le même que middleware/server-session).
    // C'est l'étape qui "connecte" réellement l'utilisateur après confirmation email/OAuth.
    const { error } = await supabase.auth.exchangeCodeForSession(code);

    if (!error) {
      if (type === "recovery") {
        return NextResponse.redirect(`${origin}/${locale}/auth/reset-password`);
      }
      return NextResponse.redirect(successUrl);
    }

    // POURQUOI: en cas d'échec d'échange, on ne fuite jamais l'erreur brute (Règle 1) ;
    // un simple indicateur en query laisse la page de destination afficher un message
    // générique traduit.
    return NextResponse.redirect(errorUrl);
  }

  // POURQUOI: pas de code = lien invalide/expiré, ou ancien flow implicite (hash)
  // non supporté côté serveur. On redirige vers une page sûre avec l'indicateur d'erreur.
  return NextResponse.redirect(errorUrl);
}
