# البيانات المطلوبة منك (Placeholder slots)

أرسل القيم التالية وسأستبدلها في الملفات المخصصة خلال دقائق:

| # | البيانات | مكان الاستبدال | الحالة |
| --- | --- | --- | --- |
| 1 | الدومين أو رابط `pages.dev` المجاني مؤقتاً | `web/config.js` → `SITE_BASE_URL`, `SUPPORT_EMAIL`, `security.txt`, `robots.txt`, `sitemap.xml`, `lib/core/environment.dart`, `server/sync/Caddyfile` | في انتظارك — القرار: pages.dev أولاً |
| 2 | بريد الأدمن | `web/admin/schema.sql` سطر Bootstrap + سياسة Cloudflare Access | `innerhnghto@gmail.com` ✅ |
| 3 | Supabase URL + publishable key | `web/config.js` و`lib/core/environment.dart` | `https://qewqhswybbeffdosdboj.supabase.co` + `sb_publishable_...` ✅ |
| 4 | لقطات شاشة حقيقية | `web/assets/screens/home.png`, `dark.png`, `classic.png` | في انتظارك |
| 5 | رابط APK النهائي + SHA-256 (GitHub Releases أو R2 — ليس Cloudflare Pages) | `web/config.js` → `APK_URL`, و`web/download.html` | في انتظارك |
| 6 | رابط GitHub | `web/config.js` → `GITHUB_URL` | في انتظارك |
| 7 | Telegram / Discord | `web/config.js` → `TELEGRAM_URL`, `DISCORD_URL` | في انتظارك |
| 8 | بريد الدعم | `web/config.js` → `SUPPORT_EMAIL`, `security.txt` | في انتظارك |
| 9 | نصوص الخصوصية والشروط | `web/privacy.html`, `web/terms.html` | اعتُمدت النسخة الحالية افتراضياً |
| 10 | عناوين IP المسموحة للأدمن | سياسة Cloudflare Access | في انتظارك |

> الصور الموجودة حالياً مأخوذة من أصول التطبيق نفسها (`assets/icon/preview_*.png`)
> وهي حقيقية من المشروع، لكن إن كانت لديك لقطات أحدث أرسلها وسأستبدلها.

لا ترسل `service_role` أو كلمة مرور قاعدة البيانات أبداً.
