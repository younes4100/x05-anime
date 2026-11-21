# دليل المبتدئ — من الصفر إلى موقع منشور X05 ANIME

اقرأ هذا الملف بالترتيب. لا تحاول تنفيذ كل شيء مرة واحدة؛ نفّذ خطوة وأخبرني، ثم أكمل معك.

## قبل البدء: ماذا تملك بالفعل؟

تحتاج حساب **Google/Gmail** واحداً على الأقل. إن لم يكن لديك:

1. افتح https://accounts.google.com/signup
2. أنشئ حساباً باسمك، وكلمة مرور قوية، ثم فعّل رقم هاتف للتحقق.
3. هذا البريد سيكون: بريد الأدمن + بريد الدعم مؤقتاً.

---

## الخطوة 1 — Supabase (مجاني) — قاعدة البيانات والمصادقة

1. افتح https://supabase.com/dashboard
2. اضغط **Sign in with GitHub** أو **Continue with email** (أسهل لك: Gmail).
3. بعد الدخول اضغط **New project**.
4. املأ:
   - Name: `X05 ANIME`
   - Database Password: اختر كلمة مرور طويلة واحفظها في ورقة أو مدير كلمات مرور. **لن ترسلها لي.**
   - Region: اختر الأقرب لك (مثلاً `Europe (Frankfurt)` أو `Middle East` إن وُجد).
5. اضغط **Create new project** وانتظر 1–2 دقيقة حتى تصبح الحالة `Active`.
6. من القائمة الجانبية اضغط **Project Settings (⚙️) → API**.
7. انسخ:
   - **Project URL** → شيء مثل `https://abcdefghijklmnop.supabase.co`
   - **anon public key** → يبدأ بـ `eyJhbGciOi...`
   - ❌ لا تنسخ `service_role secret` أبداً.
8. الآن افتح **SQL Editor** ← **New query** ← الصق كامل ملف `web/admin/schema.sql` ← **Run**.
9. افتح **Authentication → Users → Add user → Create new user**:
   - Email: بريد Gmail الذي أنشأته.
   - Password: كلمة مرور قوية جداً.
   - فعّل **Auto Confirm user**.
10. ارجع إلى **SQL Editor** وشغّل:

```sql
insert into public.admin_emails(email)
values ('بريدك@gmail.com')
on conflict do nothing;
```

✅ انتهت الخطوة 1. أرسل لي الآن (Project URL + anon key + بريد الأدمن).

---

## الخطوة 2 — GitHub (مجاني) — مستودع الكود وتحميل APK

1. افتح https://github.com/signup وسجّل بحساب Gmail.
2. اضغط **+ → New repository**.
3. Repository name: `x05-anime`
4. اختر **Public** (مهم حتى يعمل تحميل APK للجميع).
5. اضغط **Create repository**.
6. افتح المستودع ← تبويب **Releases** ← **Draft a new release**.
7. Tag: `v1.0.0`، Title: `X05 ANIME v1.0.0`.
8. اسحب ملف `X05-ANIME-universal-release.apk` إلى منطقة **Attach binaries** أو اضغط **selecting them**.
9. اضغط **Publish release**.
10. بعد النشر، انسخ:
   - رابط المستودع: `https://github.com/اسمك/x05-anime`
   - رابط ملف APK: اضغط على اسم الملف ثم **Copy link** (ينتهي بـ `.apk`).

> لماذا GitHub؟ لأن Cloudflare Pages يسمح بملف أقصاه 25 MiB، وملف APK حوالي 143 MiB. GitHub Releases يستقبل هذا الملف مجاناً.

✅ انتهت الخطوة 2. أرسل لي رابط GitHub + رابط APK.

---

## الخطوة 3 — Cloudflare (مجاني) — نشر الموقع

1. افتح https://dash.cloudflare.com/sign-up وسجّل بحساب Gmail.
2. بعد الدخول اضغط **Workers & Pages → Create application → Pages → Connect to Git**.
3. اختر مستودع `x05-anime` الذي أنشأته.
4. إعدادات البناء:
   - Project name: `x05-anime`
   - Production branch: `main`
   - **Build command:** اتركه فارغاً
   - **Build output directory:** اكتب `web`
5. اضغط **Save and Deploy**.
6. بعد دقائق ستحصل على رابط مجاني مثل: `https://x05-anime.pages.dev`.

✅ انتهت الخطوة 3. أرسل لي هذا الرابط؛ سأضعه في `SITE_BASE_URL` مؤقتاً.

---

## الخطوة 4 — بريد الدعم وIP الأدمن (مجاني)

- **بريد الدعم:** استخدم Gmail نفسه مؤقتاً. لاحقاً نجعل `support@دومينك` يحول إليه.
- **IP المسموح:** افتح https://ifconfig.me في متصفحك على الكمبيوتر، وانسخ الرقم الذي يظهر (مثل `185.123.45.67`). ومن الجوال اقطع Wi-Fi وافتح الرابط مرة أخرى إن أردت إضافة IP الجوال.

✅ أرسل لي: بريد الدعم + IP.

---

## الخطوة 5 — حماية الأدمن بـ Cloudflare Access (مجاني غالباً)

> هذه الخطوة تحتاج رابط `pages.dev` من الخطوة 3، ويمكن تأجيلها حتى تشتري الدومين.

1. في Cloudflare افتح **Zero Trust** (قد يطلب تفعيل الخطة المجانية Free؛ اختر Free — يكفي 50 مستخدماً).
2. اذهب إلى **Access controls → Applications → Add an application**.
3. اختر **Self-hosted**.
4. Application name: `X05 ANIME Admin`.
5. Public hostname:
   - Subdomain: `x05-anime`
   - Domain: `pages.dev`
   - Path: `/admin/*`
6. Session duration: `12h`.
7. Policy:
   - Action: **Allow**
   - Include → **Emails** → أضف بريدك Gmail.
   - Require → **Authentication Method** → **One-time PIN** (هذا هو الـ MFA).
   - Require → **IP** → أضف IP من الخطوة 4.
8. اضغط **Create application**.

النتيجة: من يفتح `/admin/` سيُطلب منه رمز OTP على بريده قبل الوصول لصفحة تسجيل الدخول.

> إن لم يظهر حقل Path، أرسل لي صورة من الصفحة وأرشدك حسب واجهتك.

---

## الخطوة 6 — الدومين (مدفوع، اختياري الآن)

إن أردت اسماً مثل `x05-anime.com`:

1. من Cloudflare Dashboard افتح **Domain Registration → Register domains**.
2. ابحث عن الاسم، أضفه للسلة، وادفع بالبطاقة أو PayPal (عادة ~10–15 دولار/سنة).
3. بعد الشراء سيظهر في **Websites/Domains**.
4. في مشروع Pages افتح **Custom domains → Set up a custom domain** وأضف `x05-anime.com` و`www.x05-anime.com`.
5. Cloudflare سيضيف سجلات DNS تلقائياً لأن الدومين عنده.

إن لم تكن مستعداً للدفع الآن، استخدم رابط `pages.dev` وأجّل هذه الخطوة.

---

## الخطوة 7 — Telegram وDiscord (مجانيان، اختياريان)

**Telegram**
1. حمّل تطبيق Telegram وأنشئ حساباً برقم هاتفك.
2. اضغط ✏️ → **New Channel**، الاسم: `X05 ANIME`.
3. افتح القناة ← اضغط على اسمها ← **Copy Link** → `https://t.me/...`.

**Discord**
1. افتح https://discord.com/register وأنشئ حساباً.
2. اضغط **+ → Create a server** → اختر اسم `X05 ANIME`.
3. افتح **Server Settings → Invites → New Invite** ثم **Copy Invite** → `https://discord.gg/...`.

> إن لم تردهما الآن، قل "تخطي" وسأخفي زريهما من الموقع.

---

## الخطوة 8 — صور التطبيق (مجاني)

1. افتح التطبيق على هاتفك واعرض الشاشة التي تريدها.
2. التقط صورة: زر **الطاقة + خفض الصوت** معاً.
3. أو عبر الكمبيوتر وADB:
   ```powershell
   adb exec-out screencap -p > screen1.png
   ```
4. أرفق الصور هنا في المحادثة.

> إن لم تستطع، الصور الحالية من أصول التطبيق موجودة في `web/assets/screens/` وسأكتفي بها مؤقتاً.

---

## الترتيب العملي المقترح لك الآن

لا تقلق من كثرة الخطوات. ابدأ هكذا فقط:

1. أنشئ Gmail إن لم يكن لديك.
2. نفّذ **الخطوة 1 (Supabase)** وأرسل لي Project URL + anon key + بريد الأدمن.
3. ثم **الخطوة 2 (GitHub)** وأرسل الرابطين.
4. ثم **الخطوة 3 (Cloudflare)** وأرسل رابط pages.dev.
5. الباقي نفعله تدريجياً.

أنا سأستبدل البيانات في الملفات فور كل رسالة ترسلها، ولن أنشر إلا بعد اكتمالها.
