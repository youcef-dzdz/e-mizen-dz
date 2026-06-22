/** @type {import('next').NextConfig} */
// Next.js 14 ne lit que .js/.mjs — config TypeScript réservée à Next 15+.
const nextConfig = {
  // Strict mode React: détecte les effets non idempotents tôt (qualité démo jury).
  reactStrictMode: true,
};

export default nextConfig;
