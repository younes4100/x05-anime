(function () {
  "use strict";

  var CFG = window.X05_CONFIG || {};
  var I18N = {
    ar: {
      navHome: "الرئيسية", navFeatures: "المميزات", navDownload: "تحميل APK",
      navGuide: "دليل الاستخدام", navSupport: "الدعم", navAdmin: "لوحة الأدمن",
      heroEyebrow: "أنمي • مانجا • روايات • تلفاز مباشر",
      heroTitleA: "كل عالمك.", heroTitleB: "تطبيق واحد.",
      heroLead: "X05 ANIME تطبيق عربي بالكامل يجمع الأنمي والمانجا والروايات والقنوات الحية بتجربة نظيفة وسريعة على الهاتف والتلفاز.",
      download: "حمّل APK الآن", features: "اكتشف المميزات",
      badge1: "أندرويد 7+", badge2: "ARM / ARM64 / x86_64", badge3: "واجهة عربية", badge4: "مصادر متعددة",
      featuresTitle: "صُمم ليكون تطبيقك الوحيد", featuresLead: "مكتبة، تتبع، بحث، مشاهدة، قراءة، وتلفاز مباشر — بدون فوضى.",
      f1: "أنمي ومانجا وروايات", f1d: "ابحث وتابع واقرأ وشاهد من مصادر متعددة في مكان واحد.",
      f2: "قنوات تلفاز حية", f2d: "دليل قنوات عالمي يعمل حول العالم مع بحث وتصنيفات.",
      f3: "مزامنة الأجهزة", f3d: "اقترن هاتفك بالتلفاز، وزامن المفضلة والتاريخ بسهولة.",
      f4: "واجهة عربية بامتياز", f4d: "نصوص عربية واضحة مع دعم 12 لغة حول العالم.",
      statsTitle: "حرية، خصوصية، وتحكم", statsLead: "تطبيق مفتوح المصدر يحترم خصوصيتك ويمنحك التحكم في مصادرك وبياناتك.",
      s1: "مفتوح المصدر", s1d: "مرخص GPLv3 مع حفظ حقوق المصادر الأصلية.",
      s2: "بدون إعلانات مزعجة", s2d: "تجربة نظيفة بدون تتبع إعلاني.",
      s3: "تحديثات مستمرة", s3d: "إصدارات جديدة وتحسينات بشكل دوري.",
      s4: "دعم مجتمعي", s4d: "مجتمع عربي للمساعدة والإبلاغ عن المشاكل.",
      releaseTitle: "آخر إصدار", releaseLead: "حمّل النسخة الشاملة التي تعمل على معظم أجهزة أندرويد.",
      latest: "الأحدث", downloadNow: "تحميل مباشر", notes: "ملاحظات الإصدار",
      noRelease: "ستظهر ملاحظات الإصدار هنا بعد نشر أول تحديث من لوحة الأدمن.",
      ctaTitle: "جاهز للتجربة؟", ctaLead: "حمّل التطبيق الآن أو تصفح الدليل قبل التثبيت.",
      screensTitle: "لقطات من التطبيق", screensLead: "شاشات حقيقية من نسخة X05 ANIME على الهاتف والتلفاز.",
      screenHome: "الرئيسية", screenDark: "الوضع الداكن", screenClassic: "الطابع الكلاسيكي",
      footerRights: "جميع الحقوق محفوظة.", privacy: "الخصوصية", terms: "الشروط", github: "GitHub",
    },
    en: {
      navHome: "Home", navFeatures: "Features", navDownload: "Download APK",
      navGuide: "Guide", navSupport: "Support", navAdmin: "Admin",
      heroEyebrow: "Anime • Manga • Novels • Live TV",
      heroTitleA: "Your whole world.", heroTitleB: "One app.",
      heroLead: "X05 ANIME is a fully Arabic-friendly app bringing anime, manga, novels and live channels together in one clean, fast experience for phone and TV.",
      download: "Download APK", features: "Explore features",
      badge1: "Android 7+", badge2: "ARM / ARM64 / x86_64", badge3: "Arabic UI", badge4: "Multiple sources",
      featuresTitle: "Built to be your only app", featuresLead: "Library, tracking, search, watching, reading and live TV — without the clutter.",
      f1: "Anime, manga & novels", f1d: "Search, track, read and watch from multiple sources in one place.",
      f2: "Live TV channels", f2d: "A worldwide channel directory with search and categories.",
      f3: "Device sync", f3d: "Pair your phone with your TV and sync favorites and history.",
      f4: "Arabic-first UI", f4d: "Clear Arabic text with 12 locales worldwide.",
      statsTitle: "Freedom, privacy, control", statsLead: "An open-source app that respects your privacy and puts you in control of your sources and data.",
      s1: "Open source", s1d: "GPLv3 licensed with upstream attribution preserved.",
      s2: "No intrusive ads", s2d: "A clean experience without ad tracking.",
      s3: "Regular updates", s3d: "New builds and improvements on a rolling basis.",
      s4: "Community support", s4d: "An Arabic community for help and bug reports.",
      releaseTitle: "Latest release", releaseLead: "Download the universal build that works on most Android devices.",
      latest: "Latest", downloadNow: "Direct download", notes: "Release notes",
      noRelease: "Release notes will appear here after the first update is published from the admin panel.",
      ctaTitle: "Ready to try?", ctaLead: "Download the app now or read the guide before installing.",
      screensTitle: "App screenshots", screensLead: "Real screens from the X05 ANIME build on phone and TV.",
      screenHome: "Home", screenDark: "Dark theme", screenClassic: "Classic theme",
      footerRights: "All rights reserved.", privacy: "Privacy", terms: "Terms", github: "GitHub",
    },
  };

  function currentLang() {
    try { return localStorage.getItem("x05_lang") === "ar" ? "ar" : "en"; }
    catch (_) { return "en"; }
  }
  function applyLang(lang) {
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
    document.body.dir = lang === "ar" ? "rtl" : "ltr";
    var dict = I18N[lang] || I18N.en;
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      var key = el.getAttribute("data-i18n");
      if (dict[key] !== undefined) el.textContent = dict[key];
    });
    document.querySelectorAll("[data-i18n-ph]").forEach(function (el) {
      var key = el.getAttribute("data-i18n-ph");
      if (dict[key] !== undefined) el.setAttribute("placeholder", dict[key]);
    });
    document.querySelectorAll(".lang-btn").forEach(function (b) {
      b.textContent = lang === "ar" ? "EN" : "عربي";
      b.setAttribute("aria-label", lang === "ar" ? "Switch to English" : "التبديل إلى العربية");
    });
    try { localStorage.setItem("x05_lang", lang); } catch (_) {}
  }

  function supabase() {
    if (!CFG.SUPABASE_URL || !CFG.SUPABASE_ANON_KEY || window.supabase === undefined) return null;
    try { return window.supabase.createClient(CFG.SUPABASE_URL, CFG.SUPABASE_ANON_KEY); }
    catch (_) { return null; }
  }

  function setText(id, text) { var el = document.getElementById(id); if (el) el.textContent = text; }
  function setHref(id, href) { var el = document.getElementById(id); if (el && href) el.href = href; }
  function hideIfEmpty(id, value) { var el = document.getElementById(id); if (el && !value) el.style.display = "none"; }

  function loadDynamic() {
    var sb = supabase();
    if (!sb) return;
    Promise.allSettled([
      sb.from("app_releases").select("version,notes_ar,notes_en,apk_url,published_at")
        .eq("published", true).order("published_at", { ascending: false }).limit(1),
      sb.from("app_announcements").select("title_ar,title_en,body_ar,body_en")
        .eq("active", true).order("created_at", { ascending: false }).limit(2),
    ]).then(function (results) {
      var lang = currentLang();
      var rel = results[0].status === "fulfilled" && results[0].value.data && results[0].value.data[0];
      if (rel) {
        setText("release-version", rel.version);
        setText("release-notes", lang === "ar" ? (rel.notes_ar || rel.notes_en) : (rel.notes_en || rel.notes_ar));
        setHref("release-download", rel.apk_url || CFG.APK_URL);
        setHref("hero-download", rel.apk_url || CFG.APK_URL);
      }
      var ann = results[1].status === "fulfilled" ? results[1].value.data : [];
      var host = document.getElementById("announcements");
      if (host && ann && ann.length) {
        host.innerHTML = "";
        ann.forEach(function (a) {
          var card = document.createElement("div");
          card.className = "card";
          var h = document.createElement("h3");
          h.textContent = lang === "ar" ? (a.title_ar || a.title_en) : (a.title_en || a.title_ar);
          var p = document.createElement("p");
          p.textContent = lang === "ar" ? (a.body_ar || a.body_en) : (a.body_en || a.body_ar);
          card.appendChild(h); card.appendChild(p); host.appendChild(card);
        });
        host.closest("section").classList.remove("hidden");
      }
    });
  }

  function init() {
    applyLang(currentLang());
    document.querySelectorAll(".lang-btn").forEach(function (b) {
      b.addEventListener("click", function () { applyLang(currentLang() === "ar" ? "en" : "ar"); });
    });

    var path = location.pathname.toLowerCase();
    document.querySelectorAll(".nav-links a").forEach(function (a) {
      if (a.getAttribute("href") && path.indexOf(a.getAttribute("href").replace(/^\//, "").split("/")[0]) >= 0) {
        a.classList.add("active");
      }
    });
    setHref("link-apk", CFG.APK_URL);
    setHref("link-github", CFG.GITHUB_URL);
    setHref("link-telegram", CFG.TELEGRAM_URL);
    hideIfEmpty("link-telegram", CFG.TELEGRAM_URL);
    setHref("link-discord", CFG.DISCORD_URL);
    hideIfEmpty("link-discord", CFG.DISCORD_URL);
    setHref("link-support-mail", CFG.SUPPORT_EMAIL ? "mailto:" + CFG.SUPPORT_EMAIL : "#");
    setText("support-email", CFG.SUPPORT_EMAIL || "support@example.com");
    setText("year", String(new Date().getFullYear()));
    loadDynamic();
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
