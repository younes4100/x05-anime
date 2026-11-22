# Admin Developer Console — Roblox

مُشغّل سكربتات **داخل لعبتك أنت** للإدمن فقط. الواجهة تفتح بـ `F2`، وتقدر تشغّل الكود على **السيرفر** أو على **العميل**.

## التثبيت (5 دقائق)

1. افتح اللعبة في **Roblox Studio**.
2. أضف `Script` داخل `ServerScriptService` وسمّه `AdminConsoleSERVER`، والصق محتوى:
   `ServerScriptService/AdminConsoleSERVER.lua`
3. **مهم:** بدّل الرقم `123456789` داخل جدول `Admins` إلى `UserId` الخاص بك. تجده من رابط profile الخاص بك أو عبر:
   ```lua
   print(game:GetService("Players").LocalPlayer.UserId)
   ```
   (شغّلها مؤقتاً في LocalScript أو استخدم موقع/profile Roblox).
4. أضف `LocalScript` داخل `StarterPlayerScripts` وسمّه `AdminConsoleCLIENT`، والصق محتوى:
   `StarterPlayerScripts/AdminConsoleCLIENT.lua`
5. اضغط على `ServerScriptService` → نافذة **Properties** →فعّل **LoadStringEnabled = true**.
   (السكربت يحاول يفعّلها تلقائياً، لكن التفعيل اليدوي أضمن).
6. شغّل اللعبة بـ `F5`، واضغط `F2` تفتح لك الواجهة.

## طريقة الاستخدام

- اكتب الكود في الصندوق الكبير واضغط **RUN**.
- الزر **🖥 SERVER / 👤 CLIENT** يبدّل مكان التنفيذ:
  - **SERVER**: الكود ينفّذ على السيرفر، و `print(...)` وقيمة `return` تظهر في مربع الإخراج.
  - **CLIENT**: يتم زرع `LocalScript` داخل `PlayerGui/AdminConsoleScripts`، ومخرجات `print` تظهر في Output / F9 Console عند العميل.
- **CLEAR** يمسح الكود والإخراج.

أمثلة:

```lua
-- مثال 1: إرجاع قيمة
return game.Workspace.Name

-- مثال 2: طباعة معلومات
print("اللاعبون:", game:GetService("Players"):GetPlayers())

-- مثال 3: تعديل الإضاءة
game.Lighting.TimeOfDay = "10:00:00"
return "تم تعديل الإضاءة"
```

## الأمان

- التحقق من الصلاحية يتم **فقط على السيرفر** في كل طلب (`CONFIG.Admins[player.UserId]`).
- العميل لا يحتوي على قائمة إدمن؛ السيرفر يرسل إشارة `Auth` للإدمن فقط، وبدونها ما تظهر الواجهة أصلاً.
- أي محاولة من غير إدمن تُرفض وتُسجّل في الـ Output بصيغة `محاولة غير مصرّحة`.
- لا تعطي `UserId` الخاص بك لأحد، ولا تضيف أشخاص لا تثق بهم في `Admins`.
- الكود المُنفّذ يقدر يغيّر أي شيء في اللعبة — استخدمه بحذر ويفضّل على Place تجريبي أولاً.

## ملاحظات

- الأكواد اللي فيها `wait()` / yielding قد لا تُرجع نتيجة مباشرة؛ استخدم `task.spawn(function() ... end)` داخل الكود واطبع النتائج عبر `print`.
- `loadstring` متاح للسيرفر فقط في Roblox، لذلك قسم CLIENT يستخدم `LocalScript.Source` بدلاً منه.
- المسارات في هذا المجلد تمثّل هيكل Studio؛ انسخ محتوى كل ملف إلى المكان المذكور.
