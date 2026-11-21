# Cloudflare Pages — نشر وحماية X05 ANIME

## 1) تجهيز المستودع

المجلد الذي يجب نشره هو `web/` فقط.

- إذا رفعت كامل مشروع Flutter إلى GitHub، اجعل **Build output directory = `web`**.
- إذا رفعت محتويات `web/` مباشرة، اجعل output directory = `/`.
- **Build command:** اتركه فارغاً (موقع ثابت بدون npm).

تأكد أن هذه الملفات موجودة داخل مجلد النشر:

```text
_headers
config.js
index.html
admin/  assets/  css/  js/  vendor/  reset/  open/  pair/
robots.txt  security.txt  sitemap.xml  vercel.json  .htaccess  web.config
```

> ملفات `vercel.json` و`.htaccess` و`web.config` خاصة باستضافة أخرى؛ وجودها لا يضر Cloudflare.

> مهم: لا تضع ملف الـ APK داخل `web/`. حد Cloudflare Pages الأقصى للملف الواحد هو **25 MiB**،
> وملفك حوالي 143 MiB. استضف الـ APK في GitHub Releases أو Cloudflare R2 public bucket،
> ثم ضع الرابط النهائي في `config.js` ← `APK_URL`.

## 2) إنشاء المشروع على Cloudflare

1. افتح https://dash.cloudflare.com → **Workers & Pages**.
2. **Create application → Pages → Connect to Git**.
3. اختر مستودع GitHub، ثم **Begin setup**.
4. Project name: `x05-anime` (أو ما تريد).
5. Production branch: `main`.
6. Build command: فارغ.
7. Build output directory: `web` (أو `/` إن رفعت المحتوى مباشرة).
8. اضغط **Save and Deploy**.

بعد أول نشر ستحصل على رابط مثل `https://x05-anime.pages.dev`.

## 3) ربط الدومين

1. في المشروع: **Custom domains → Set up a custom domain**.
2. أدخل دومينك الحقيقي، مثل `x05-anime.com` و `www.x05-anime.com`.
3. Cloudflare سيعرض سجلات DNS المطلوبة. أضفها عند مزوّد الدومين:
   - غالباً `CNAME www → x05-anime.pages.dev`
   - للـ apex يفضّل استخدام Cloudflare nameservers مع CNAME flattening أو سجلات A التي تعرضها Cloudflare.
4. انتظر تفعيل SSL (عادة دقائق).

## 4) إجبار HTTPS وHSTS

**SSL/TLS → Overview**

- Encryption mode: **Full (strict)** (بعد تفعيل شهادة Cloudflare الأصلية).
- **Edge Certificates**: فعّل `Always Use HTTPS`.
- فعّل `HSTS` مع `max-age=31536000; includeSubDomains; preload` بعد التأكد أن كل الروابط تعمل.
- Minimum TLS Version: **TLS 1.2**.

## 5) ترؤوس الأمان

ملف `_headers` الموجود في `web/` يفعّل تلقائياً على Cloudflare Pages:

- CSP صارم بدون CDN خارجي
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy`
- `Permissions-Policy`
- `noindex` لصفحات `/admin/` و`/reset/`

تحقق بعد النشر:

```powershell
Invoke-WebRequest https://YOUR_DOMAIN/ -Method Head | Select-Object -ExpandProperty Headers
```

يجب أن ترى `content-security-policy` و`x-frame-options`.

## 6) حماية لوحة الأدمن بـ Cloudflare Access (MFA + IP)

هذه هي الطبقة الأقوى، وتعمل قبل أن تصل إلى Supabase.

1. افتح **Cloudflare Zero Trust → Access → Applications → Add an application**.
2. اختر **Self-hosted**.
3. Application name: `X05 ANIME Admin`.
4. Application domain: `YOUR_DOMAIN`، و Path: `admin/*`.
   - إن أردت نطاقاً فرعياً منفصلاً استخدم `admin.YOUR_DOMAIN` ووجهه إلى Pages.
5. Session duration: `12h` أو أقل.
6. Policy name: `Admins only`.
7. Action: **Allow**.
8. Rules:
   - **Include → Email → is → `ADMIN_EMAIL@example.com`**
   - **Require → IP → is in → عناوينك الخاصة** (أو `Country is in` لبلدك)
   - **Require → Authentication Method → is → One-time PIN** (هذا يفعّل MFA عبر البريد)
9. Apply.

النتيجة: أي شخص يفتح `/admin/` يجب أن:
1. يأتي من عنوان IP المسموح.
2. يدخل بريده ويستلم رمزاً لمرة واحدة (OTP).
3. ثم يجد صفحة تسجيل دخول Supabase الخاصة بالأدمن.

> إذا أردت TOTP بدل OTP، اربط Cloudflare Access بمزوّد هوية (Google Workspace / Okta / Authentik) وفعّل TOTP هناك.

## 7) قواعد WAF إضافية (اختياري لكن موصى به)

**Security → WAF → Managed rules**

- فعّل Cloudflare Managed Ruleset.
- فعّل OWASP Core Ruleset.
- أضف Rate limiting على `/admin/*`: مثلاً 10 طلبات / دقيقة لكل IP.

**Bot Fight Mode** أو **Super Bot Fight Mode** → فعّل.

## 8) قائمة تحقق بعد النشر

- [ ] `https://YOUR_DOMAIN/` يعمل ويظهر شعار X05 ANIME.
- [ ] `https://YOUR_DOMAIN/download.html` يحمّل رابط APK الصحيح.
- [ ] `https://YOUR_DOMAIN/reset/` يعمل ويرسل رابط الاستعادة.
- [ ] `https://YOUR_DOMAIN/admin/` يطلب OTP من Cloudflare Access قبل أي شيء.
- [ ] `curl -I https://YOUR_DOMAIN/admin/` يُظهر `x-robots-tag` وCSP.
- [ ] `https://YOUR_DOMAIN/security.txt` و`robots.txt` و`sitemap.xml` تعمل.
- [ ] لا يظهر `service_role` في أي ملف داخل `web/`.
