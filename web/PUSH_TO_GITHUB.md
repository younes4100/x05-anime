# رفع المستودع إلى GitHub — الخطوة الأخيرة من طرفك

تم تجهيز كل شيء محلياً:

- المستودع مهيّأ في مجلد المشروع: `C:\Users\dilam\Desktop\X05 ANIME`
- الفرع: `main`
- الـ remote: `https://github.com/younes4100/x05-anime.git`
- أول commit جاهز ويحتوي مجلد `web` كاملاً (40 ملفاً).
- ملف الـ APK **مستبعد** من Git لأنه أكبر من حد GitHub (100 MiB)، وسيُرفع في **Releases**.

> لم أستطع تنفيذ `git push` من بيئتي لأن الشبكة هنا لا تصل إلى `github.com:443`.
> الخطوة التالية يجب تنفيذها من جهازك أنت.

## 1) ادفع المستودع

افتح PowerShell في مجلد المشروع وشغّل:

```powershell
cd "C:\Users\dilam\Desktop\X05 ANIME"
git push -u origin main
```

إن ظهرت نافذة تسجيل دخول GitHub:
- Username: `younes4100`
- Password: **Personal Access Token** وليس كلمة مرور الحساب.

### إنشاء Personal Access Token (إن طُلب)
1. افتح https://github.com/settings/tokens
2. **Generate new token → Generate new token (classic)**
3. الاسم: `X05 ANIME`
4. فعّل ✅ `repo` فقط.
5. **Generate token** ثم انسخه فوراً (لن يظهر مرة أخرى).

## 2) ارفع الـ APK كإصدار

1. افتح https://github.com/younes4100/x05-anime
2. **Releases → Draft a new release**
3. Tag: `v1.0.0`، Title: `X05 ANIME v1.0.0`
4. اسحب الملف:
   `C:\Users\dilam\Desktop\X05 ANIME\X05-ANIME-universal-release.apk`
5. **Publish release**
6. اضغط على اسم ملف `.apk` ← **Copy link**

## 3) أرسل لي

```text
رابط المستودع: https://github.com/younes4100/x05-anime
رابط APK: https://github.com/younes4100/x05-anime/releases/download/v1.0.0/X05-ANIME-universal-release.apk
```

ثم أجهّز لك نشر Cloudflare Pages على `https://x05-anime.pages.dev`.
