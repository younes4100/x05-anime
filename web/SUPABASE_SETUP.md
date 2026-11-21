# Supabase setup — X05 ANIME (خطوة بخطوة)

> لا تشارك `service_role` مع أي أحد، ولا تضعه أبداً داخل مجلد `web/`.
> المفتاح `anon` عام بالتصميم، وهو الوحيد الذي يستخدمه الموقع والتطبيق.

## 1) إنشاء المشروع

1. افتح https://supabase.com/dashboard وسجّل الدخول.
2. اضغط **New project**.
3. الاسم: `X05 ANIME`.
4. Database password: أنشئ كلمة مرور قوية جداً (32 حرفاً مثلًا) واحفظها في مدير كلمات المرور.
5. Region: اختر الأقرب لجمهورك (مثلاً `eu-central-1` أو `me-south-1` إن توفر).
6. Plan: Free يكفي للبداية.
7. اضغط **Create new project** وانتظر حتى يصبح الحالة `Active`.

## 2) نسخ مفاتيح API

في لوحة Supabase الحديثة لا توجد صفحة باسم `API` منفردة. المفاتيح الآن هنا:

**Project Settings (⚙️) → API Keys**

أعلى تلك الصفحة تجد:

- **Project URL** → مثلاً `https://abcdefghijklmnop.supabase.co`
- **Publishable key** → يبدأ بـ `sb_publishable_...` (هذا هو الذي نستخدمه)
- **Secret key** → يبدأ بـ `sb_secret_...` ❌ لا تستخدمه أبداً في الموقع

طريقة بديلة أسهل: اضغط زر **Connect** أعلى صفحة المشروع، ثم اختر أي إطار عمل (مثل JavaScript)، وستظهر لك القيمتان `SUPABASE_URL` و publishable key جاهزة للنسخ.

> إن كان مشروعك قديماً، قد ترى الاسم القديم `anon key` الذي يبدأ بـ `eyJ...`؛ يعمل أيضاً، لكن Publishable أحدث.

الصقهما في `web/config.js`:

```js
SUPABASE_URL: "https://abcdefghijklmnop.supabase.co",
SUPABASE_ANON_KEY: "eyJhbGciOi...",
```

ثم حدّث `lib/core/environment.dart` في التطبيق بالقيم نفسها:

```dart
defaultValue: 'https://abcdefghijklmnop.supabase.co',
defaultValue: 'eyJhbGciOi...',
static const String supabaseSessionStorageKey = 'sb-abcdefghijklmnop-auth-token';
```

> اسم الـ storage key يجب أن يطابق أول جزء من اسم المضيف قبل `.supabase.co`.

## 3) إعداد Auth

**Authentication → Providers → Email**

- تأكد أن Email مفعّل.
- فعّل **Confirm email** (مهم قبل النشر).

**Authentication → URL Configuration**

- Site URL: `https://YOUR_DOMAIN/`
- Redirect URLs أضف واحداً تلو الآخر:

```text
https://YOUR_DOMAIN/reset/
https://YOUR_DOMAIN/reset/index.html
https://YOUR_DOMAIN/open/
https://YOUR_DOMAIN/pair/
http://localhost:3000/
```

> استبدل `YOUR_DOMAIN` بدومينك الحقيقي على Cloudflare Pages.

## 4) تشغيل قاعدة البيانات

1. افتح **SQL Editor**.
2. اضغط **New query**.
3. الصق كامل محتوى `web/admin/schema.sql`.
4. اضغط **Run**.
5. يجب أن يظهر `Success. No rows returned`.

هذا ينشئ:

- `admin_emails` (قائمة الأدمن)
- `app_announcements`, `app_releases`, `app_reports`
- `admin_audit` + trigger للتدقيق
- دوال `is_admin()`, `admin_dashboard_stats()`, `admin_list_users()`
- RLS على كل الجداول

## 5) إنشاء حساب الأدمن وإضافته للقائمة

1. **Authentication → Users → Add user → Create new user**
2. Email: بريد الأدمن الذي سترسله.
3. Password: كلمة مرور قوية جداً (20+ حرف، رموز وأرقام).
4. فعّل **Auto Confirm** لهذا المستخدم.
5. ارجع إلى **SQL Editor** وشغّل (بعد استبدال البريد):

```sql
insert into public.admin_emails(email)
values ('ADMIN_EMAIL@example.com')
on conflict do nothing;
```

6. تحقق من الإضافة:

```sql
select email, created_at from public.admin_emails;
```

## 6) اختبار الدخول محلياً

```powershell
cd web
python -m http.server 8000
```

افتح `http://localhost:8000/admin/` وسجّل الدخول بالبريد وكلمة المرور.
يجب أن تظهر لوحة الأدمن. إذا ظهر `not in the admin allowlist` فالخطأ في الخطوة 5.

## 7) رفع الموقع

الآن انتقل إلى `CLOUDFLARE_PAGES.md` في نفس المجلد.

## 8) تأمين إضافي موصى به بعد النشر

- فعّل MFA على حساب الأدمن من Cloudflare Access (الإجراءات في `CLOUDFLARE_PAGES.md`).
- قيّد `/admin/*` بعناوين IP الخاصة بك.
- راقب `admin_audit` أسبوعياً:

```sql
select actor, table_name, action, created_at
from public.admin_audit
order by created_at desc
limit 50;
```

- لا تمنح صلاحية `admin_emails` لأكثر من حساب واحد إلا إذا احتجت فعلاً.
