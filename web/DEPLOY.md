# X05 ANIME website + admin panel

This folder is a static site. No npm build is required.

**ابدأ هنا:** `BEGINNER_SETUP.md` (من الصفر) ← ثم `SUPABASE_SETUP.md` ← `CLOUDFLARE_PAGES.md` ← `DATA_CHECKLIST.md`.

## What is here

| Path | Purpose |
| --- | --- |
| `index.html` | Public landing page (AR/EN, dynamic latest release + announcements) |
| `download.html` | Universal APK download + install instructions |
| `guide.html` | Setup, TV pairing, Live TV, unreleased-title explanation |
| `support.html` | Support links and report guidance |
| `privacy.html`, `terms.html` | Legal/privacy pages |
| `reset/index.html` | Supabase password reset (replaces the old Appwrite `web_reset` flow) |
| `open/index.html`, `pair/index.html` | HTTPS → `x05://` deep-link handoff pages |
| `admin/index.html`, `admin/app.js` | Supabase-authenticated admin panel |
| `admin/schema.sql` | Tables, RLS policies, admin RPCs, audit trigger |
| `config.js` | All public URLs/keys in one place |

`../web_reset/index.html` is kept as a backward-compatible Supabase reset page for the old URL.

## 1. Replace placeholders

Edit `config.js`:

- `SITE_BASE_URL` → your real domain, e.g. `https://x05-anime.com`
- `APK_URL` → your real APK/release URL
- `SUPABASE_URL` / `SUPABASE_ANON_KEY` → your real Supabase project values
- `TELEGRAM_URL`, `DISCORD_URL`, `SUPPORT_EMAIL` → your real contacts

Also update the placeholder domains in the Flutter app (`lib/core/environment.dart`,
`lib/core/app_config.dart`), `server/sync/Caddyfile` and the Cloudflare worker names.
The current placeholders are `x05-anime.example` / `sync.x05-anime.example` /
`auth.x05-anime.example` / `cdn.x05-anime.example` / `logs.x05-anime.example`.

## 2. Supabase setup

1. Create a Supabase project.
2. Run `admin/schema.sql` in the SQL Editor.
3. Bootstrap your first admin:

   ```sql
   insert into public.admin_emails(email)
   values ('you@example.com') on conflict do nothing;
   ```

4. In Supabase Auth → URL Configuration:
   - Site URL: `https://your-domain/`
   - Redirect URLs: `https://your-domain/reset/index.html`, `https://your-domain/reset/`
5. The anon key is public and safe. **Never put the service_role key in this site.**

## 3. Deploy

Copy the whole `web/` folder to any static host (Cloudflare Pages, Netlify, Vercel,
GitHub Pages, nginx, Caddy). Example with Caddy:

```caddyfile
x05-anime.example {
  root * /var/www/x05-web
  try_files {path} {path}/index.html =404
  file_server
}
```

Important: `reset/`, `open/` and `pair/` must resolve their `index.html` when accessed
as directories. Most static hosts already do this.

## 4. Admin access

Open `https://your-domain/admin/`, sign in with a Supabase Auth account whose email is
in `public.admin_emails`. If the account is not in the allowlist, access is denied and
the session is signed out.

Available admin actions:

- overview counters (users, announcements, published releases, open reports)
- publish/hide announcements (bilingual AR/EN)
- publish/unpublish APK releases with bilingual notes
- review/delete user reports
- list Supabase users (via `admin_list_users()`)
- add/remove other admins (you cannot remove your own access)

All writes are recorded in `admin_audit` by the SQL trigger.

## 5. Security notes

- Admin authorization is checked by `public.is_admin()` against `admin_emails`, **not**
  by the anon key or a client-side flag.
- RLS is enabled on every new table. Public users can only read active announcements
  and published releases; authenticated users can only insert/read their own reports.
- If you need deeper moderation later, add server-side functions rather than exposing
  the service_role key in browser JavaScript.
- The app still uses `x05://` for OAuth/share/pair redirects. Update the redirect URLs
  registered with AniList, MAL, Simkl and MangaBaka when you go live.

### Hardening already applied

- Supabase JS is vendored in `vendor/supabase.min.js`; no CDN script is loaded at runtime.
- All page logic is external JavaScript. There are no inline `<script>` blocks.
- A strict Content-Security-Policy is set both in host headers and as a meta fallback.
- Security headers are provided for Netlify/Cloudflare Pages (`_headers`), Vercel
  (`vercel.json`), Apache (`.htaccess`), IIS (`web.config`) and nginx
  (`deploy/nginx.conf.example`).
- `/admin/`, `/reset/` and `/web_reset/` are `noindex`; `robots.txt`, `security.txt`
  and `sitemap.xml` are included.
- Real app preview assets from the shipped APK are served from `assets/screens/`.
  Replace the three PNGs with your own screenshots if you have better ones.

If you use a custom Supabase auth domain instead of `*.supabase.co`, add it to
`connect-src` in every header config and meta CSP before deploying.

### Admin lockdown checklist

1. Use a unique, strong password and enable Supabase Auth MFA for every admin email.
2. Keep the allowlist in `public.admin_emails` minimal; remove it immediately when an admin leaves.
3. Restrict `/admin/` at the edge (Cloudflare Access, Vercel password protection, or
   nginx allow/deny) to your own IP ranges if possible.
4. Rotate the Supabase anon key only if it was ever exposed in a private repo; the
   `service_role` key must never appear in `web/`.
5. Enable HTTPS only and keep HSTS enabled at the CDN/edge.

## 6. Legal

The site keeps X05 ANIME branding. Upstream attribution stays in the repository's
`NOTICE.md`, `LICENSE` and `CLA.md`; those files are intentionally excluded from renames.
