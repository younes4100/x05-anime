(function () {
  "use strict";

  var CFG = window.X05_CONFIG || {};
  var lastReleases = null;
  var I18N = {
    ar: {
      navHome: "الرئيسية", navDiscover: "اكتشف", navFeatures: "المميزات", navDownload: "تحميل APK",
      navVersions: "الإصدارات", navGuide: "دليل الاستخدام", navSupport: "الدعم",
      navAdmin: "لوحة الأدمن",
      heroEyebrow: "أنمي • أفلام • مانجا • تلفاز مباشر",
      heroTitleA: "كل عالمك.", heroTitleB: "تطبيق واحد.",
      heroLead: "أغلفة حقيقية، أفلام أنمي، قنوات حية ومكتبتك — في تجربة زجاجية زرقاء نظيفة وسريعة.",
      download: "حمّل APK الآن", features: "اكتشف المميزات", exploreNow: "تصفح العناوين",
      kickerDiscover: "كتالوج حي", discoverTitle: "شاهد ما يشاهده الجميع",
      discoverLead: "الأغلفة والعناوين تتحدث مباشرة من AniList. اختر مسلسلًا رائجًا أو فيلم أنمي أو انتقل إلى التلفاز المباشر.",
      tabTrending: "الأكثر رواجًا", tabMovies: "أفلام أنمي", tabLive: "التلفاز المباشر",
      discoverSearch: "ابحث عن عنوان أو نوع…",
      discoverCredit: "الأغلفة والعناوين من AniList. X05 لا يستضيف أي بث ولا أي ملف محمي.",
      kickerFeatures: "لماذا X05", kickerStats: "حرية", kickerLive: "التلفاز المباشر",
      kickerScreens: "داخل التطبيق", kickerRelease: "آخر نسخة", kickerVersions: "السجل", kickerFaq: "إجابات",
      liveTitle: "دليل حقيقي، ليست قائمة روابط",
      liveLead: "قناة مميزة، صف من خمس قنوات، مفضلة، وتصفية حسب الدولة والتصنيف، وتشغيل بضغطة واحدة عبر نفس المشغّل.",
      channel1: "العالم", channel2: "العربية", channel3: "الأخبار", channel4: "الرياضة",
      livePlay: "شاهد في التطبيق",
      badge1: "أندرويد 7+", badge2: "ARM / ARM64 / x86_64", badge3: "واجهة عربية", badge4: "5 تبويبات في الشريط",
      featuresTitle: "صُمم ليكون تطبيقك الوحيد", featuresLead: "مكتبة، تتبع، بحث، مشاهدة، قراءة، وتلفاز مباشر — بدون فوضى.",
      f1: "أنمي ومانجا وروايات", f1d: "ابحث وتابع واقرأ وشاهد من مصادر متعددة في مكان واحد.",
      f2: "دليل التلفاز المباشر", f2d: "قناة مميزة، أفضل خمس قنوات، مفضلة، وتصفية حسب الدولة والتصنيف.",
      f3: "مزامنة الأجهزة", f3d: "اقترن هاتفك بالتلفاز، وزامن المفضلة والتاريخ بسهولة.",
      f4: "واجهة عربية بامتياز", f4d: "نصوص عربية واضحة مع دعم 12 لغة حول العالم.",
      f5: "Auto Resolve", f5d: "مطابقة سريعة للأفلام والمسلسلات مع ترتيب أولوية وإعادة محاولة ذكية.",
      f6: "خمس تبويبات", f6d: "التلفاز المباشر أصبح تبويبًا أساسيًا بدل أن يكون مخفيًا في القوائم.",
      f7: "واجهة زجاجية", f7d: "أسطح زجاجية زرقاء شفافة وحركة سلسة على الهاتف والتلفاز.",
      f8: "خصوصية بالتصميم", f8d: "لا نستضيف أي محتوى، وسجل المشاهدة يبقى على جهازك.",
      statsTitle: "حرية، خصوصية، وتحكم", statsLead: "تطبيق مفتوح المصدر يحترم خصوصيتك ويمنحك التحكم في مصادرك وبياناتك.",
      s1: "مفتوح المصدر", s1d: "مرخص GPLv3 مع حفظ حقوق المصادر الأصلية.",
      s2: "بدون إعلانات مزعجة", s2d: "تجربة نظيفة بدون تتبع إعلاني.",
      s3: "تحديثات مستمرة", s3d: "إصدارات جديدة وتحسينات بشكل دوري.",
      s4: "دعم مجتمعي", s4d: "مجتمع عربي للمساعدة والإبلاغ عن المشاكل.",
      s5: "أندرويد 7+", s5d: "يعمل على أندرويد 7 فأعلى.",
      s6: "ثلاث معماريات", s6d: "ARM و ARM64 و x86_64 في ملف واحد.",
      releaseTitle: "آخر إصدار", releaseLead: "حمّل النسخة الشاملة التي تعمل على معظم أجهزة أندرويد.",
      latest: "الأحدث", downloadNow: "تحميل مباشر", notes: "ملاحظات الإصدار",
      noRelease: "ستظهر ملاحظات الإصدار هنا بعد نشر أول تحديث من لوحة الأدمن.",
      ctaTitle: "جاهز للتجربة؟", ctaLead: "حمّل التطبيق الآن أو تصفح الدليل قبل التثبيت.",
      screensTitle: "لقطات من التطبيق", screensLead: "شاشات حقيقية من نسخة X05 ANIME على الهاتف والتلفاز.",
      screenHome: "الرئيسية", screenDark: "الوضع الداكن", screenClassic: "الطابع الكلاسيكي",
      versionsTitle: "كل الإصدارات", versionsLead: "كل نسخة منشورة، من الأحدث إلى الأقدم. النسخ القديمة متاحة ما دامت مفيدة.",
      viewAllReleases: "كل الإصدارات على GitHub",
      githubReleasesNote: "ملفات الإصدارات مستضافة على GitHub. X05 ANIME لا يستضيف أي محتوى ولا ملف APK على هذا الموقع.",
      downloadEyebrow: "نسخة شاملة · ملف واحد", downloadTitle: "حمّل X05 ANIME",
      downloadLead: "تطبيق خفيف بواجهة زجاجية زرقاء للأنمي والمانجا والروايات والتلفاز المباشر. ملف واحد للهاتف والتابلت والتلفاز.",
      metaSize: "≈ 143 ميجابايت",
      downloadNotice: "ملف APK منشور على GitHub Releases. بلا حساب، بلا دفع، بلا مُثبّت.",
      verifyTitle: "تحقق من الملف", verifyLead: "قارن بصمة SHA-256 بعد التنزيل. يجب أن تطابق البصمة الرسمية أدناه.",
      beforeTitle: "قبل التثبيت",
      check1: "اسمح بتثبيت التطبيقات من مصادر غير معروفة للمتصفح أو مدير الملفات فقط.",
      check2: "أعد إغلاق هذا الإذن بعد انتهاء التثبيت.",
      check3: "على تلفاز أندرويد، انسخ الملف إلى USB وافتحه من مدير ملفات التلفاز.",
      faqTitle: "أسئلة متكررة", faqLead: "إجابات مختصرة قبل التثبيت.",
      faq1q: "من أين تأتي القنوات؟", faq1a: "يقرأ دليل التلفاز المباشر قوائم عامة من مشروع iptv-org. التطبيق لا يستضيف أي بث.",
      faq2q: "لماذا لا أجد فيلمًا بعد؟", faq2a: "المصادر الخارجية تتغير. العناوين المعروضة في السينما أو لم تُعرض بعد لن تعمل حتى يتوفر بث قانوني؛ استخدم Auto Resolve أو اختر مصدرًا يدويًا.",
      faq3q: "كيف أعيد تعيين كلمة المرور؟", faq3a: "استخدم «نسيت كلمة المرور؟» في التطبيق أو صفحة الدخول. رابط البريد يفتح الآن صفحة إعادة التعيين المخصصة على هذا الموقع.",
      faq4q: "هل يعمل على تلفاز أندرويد؟", faq4a: "نعم. افتح APK من USB عبر مدير ملفات التلفاز، أو ثبّته داخل محاكي مثل MSI App Player، ثم اقترن هاتفك من قسم التلفاز.",
      faq5q: "أي معمارية أختار؟", faq5a: "هذه هي النسخة الشاملة: ARM و ARM64 و x86_64 في نفس الملف. أندرويد 7.0 أو أحدث مطلوب.",
      faq6q: "من أين تأتي القنوات والبث؟", faq6a: "التلفاز المباشر يقرأ قوائم iptv-org العامة. مصادر الفيديو خارجية وتتغير مع الوقت؛ التطبيق لا يستضيف أي بث.",
      footerRights: "جميع الحقوق محفوظة.", privacy: "الخصوصية", terms: "الشروط", github: "GitHub",
    },
    en: {
      navHome: "Home", navDiscover: "Discover", navFeatures: "Features", navDownload: "Download APK",
      navVersions: "Versions", navGuide: "Guide", navSupport: "Support",
      navAdmin: "Admin",
      heroEyebrow: "Anime • Movies • Manga • Live TV",
      heroTitleA: "Your whole world.", heroTitleB: "One app.",
      heroLead: "Real poster art, anime films, live channels and your library — in one clean, fast blue-glass experience.",
      download: "Download APK", features: "Explore features", exploreNow: "Explore titles",
      kickerDiscover: "Live catalogue", discoverTitle: "See what everyone is watching",
      discoverLead: "Posters and titles update live from AniList. Pick a trending series, an anime film, or jump straight into live TV.",
      tabTrending: "Trending", tabMovies: "Anime films", tabLive: "Live TV",
      discoverSearch: "Search a title or genre…",
      discoverCredit: "Cover art and titles come from AniList. X05 hosts no stream and no copyrighted file.",
      kickerFeatures: "Why X05", kickerStats: "Freedom", kickerLive: "Live TV",
      kickerScreens: "Inside the app", kickerRelease: "Latest build", kickerVersions: "History", kickerFaq: "Answers",
      liveTitle: "A real guide, not a link list",
      liveLead: "Featured channel, a five-channel top row, favourites, and country/category filters, with one-tap playback through the same player as everything else.",
      channel1: "Worldwide", channel2: "Arabic", channel3: "News", channel4: "Sports",
      livePlay: "Watch in the app",
      badge1: "Android 7+", badge2: "ARM / ARM64 / x86_64", badge3: "Arabic UI", badge4: "5 dock tabs",
      featuresTitle: "Built to be your only app", featuresLead: "Library, tracking, search, watching, reading and live TV — without the clutter.",
      f1: "Anime, manga & novels", f1d: "Search, track, read and watch from multiple sources in one place.",
      f2: "Live TV guide", f2d: "A featured channel, top five, favourites, and country/category filters.",
      f3: "Device sync", f3d: "Pair your phone with your TV and sync favorites and history.",
      f4: "Arabic-first UI", f4d: "Clear Arabic text with 12 locales worldwide.",
      f5: "Auto Resolve", f5d: "Fast source matching for films and series, with priority ordering and smart retries.",
      f6: "Five dock tabs", f6d: "Live TV is now a first-class destination instead of a buried menu item.",
      f7: "Glass interface", f7d: "Translucent blue surfaces and smooth motion on phone and TV.",
      f8: "Private by design", f8d: "No content hosted here. Your history stays on your device.",
      statsTitle: "Freedom, privacy, control", statsLead: "An open-source app that respects your privacy and puts you in control of your sources and data.",
      s1: "Open source", s1d: "GPLv3 licensed with upstream attribution preserved.",
      s2: "No intrusive ads", s2d: "A clean experience without ad tracking.",
      s3: "Regular updates", s3d: "New builds and improvements on a rolling basis.",
      s4: "Community support", s4d: "An Arabic community for help and bug reports.",
      s5: "Android 7+", s5d: "Works on Android 7 and newer devices.",
      s6: "Three architectures", s6d: "ARM, ARM64 and x86_64 in one APK.",
      releaseTitle: "Latest release", releaseLead: "Download the universal build that works on most Android devices.",
      latest: "Latest", downloadNow: "Direct download", notes: "Release notes",
      noRelease: "Release notes will appear here after the first update is published from the admin panel.",
      ctaTitle: "Ready to try?", ctaLead: "Download the app now or read the guide before installing.",
      screensTitle: "App screenshots", screensLead: "Real screens from the X05 ANIME build on phone and TV.",
      screenHome: "Home", screenDark: "Dark theme", screenClassic: "Classic theme",
      versionsTitle: "All versions", versionsLead: "Every published build, newest first. Older versions stay available while they are useful.",
      viewAllReleases: "All releases on GitHub",
      githubReleasesNote: "Release files are hosted on GitHub. X05 ANIME hosts no content and no APK on this site.",
      downloadEyebrow: "Universal build · one file", downloadTitle: "Download X05 ANIME",
      downloadLead: "A light, transparent blue-glass app for anime, manga, novels and live TV. One APK for phones, tablets and TV boxes.",
      metaSize: "≈ 143 MB",
      downloadNotice: "The APK is published on GitHub Releases. No account, no payment, no installer.",
      verifyTitle: "Verify the file", verifyLead: "Compare the SHA-256 fingerprint after downloading. It should match the official build below.",
      beforeTitle: "Before installing",
      check1: "Allow “install from unknown sources” for your browser or file manager only.",
      check2: "Turn that permission off again after the install finishes.",
      check3: "On Android TV, copy the APK to USB and open it from the TV file manager.",
      faqTitle: "Frequently asked", faqLead: "Short answers before you install.",
      faq1q: "Where do the channels come from?", faq1a: "The Live TV guide reads public playlists from the iptv-org project. X05 does not host any stream.",
      faq2q: "Why can't I find a movie yet?", faq2a: "External sources change. Titles still in cinemas or not yet aired cannot be played until a legal stream exists; use Auto Resolve or pick a source manually.",
      faq3q: "How do I reset my password?", faq3a: "Use “Forgot password?” in the app or sign-in page. The email link now opens the dedicated reset page on this site.",
      faq4q: "Does it work on Android TV?", faq4a: "Yes. Use the TV file manager to open the APK from USB, or install it inside an Android emulator such as MSI App Player. Pair your phone from the TV section for remote control.",
      faq5q: "Which architecture should I choose?", faq5a: "This is the universal build: ARM, ARM64 and x86_64 are all inside the same APK. Android 7.0 or newer is required.",
      faq6q: "Where do channels and streams come from?", faq6a: "Live TV reads public playlists from iptv-org. Video sources are external and change over time; X05 hosts no streams.",
      footerRights: "All rights reserved.", privacy: "Privacy", terms: "Terms", github: "GitHub",
    },
  };

  function currentLang() {
    try { return localStorage.getItem("x05_lang") === "ar" ? "ar" : "en"; }
    catch (_) { return "en"; }
  }

  function esc(v) {
    return String(v == null ? "" : v).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }[c];
    });
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
    if (lastReleases) renderVersions(lastReleases, lang);
    try { localStorage.setItem("x05_lang", lang); } catch (_) {}
    document.dispatchEvent(new CustomEvent("x05:langchange", { detail: { lang: lang } }));
  }

  function supabase() {
    if (!CFG.SUPABASE_URL || !CFG.SUPABASE_ANON_KEY || window.supabase === undefined) return null;
    try { return window.supabase.createClient(CFG.SUPABASE_URL, CFG.SUPABASE_ANON_KEY); }
    catch (_) { return null; }
  }

  function setText(id, text) { var el = document.getElementById(id); if (el) el.textContent = text; }
  function setHref(id, href) { var el = document.getElementById(id); if (el && href) el.href = href; }
  function hideIfEmpty(id, value) { var el = document.getElementById(id); if (el && !value) el.style.display = "none"; }

  function renderVersions(rows, lang) {
    var dict = I18N[lang] || I18N.en;
    var list = rows && rows.length ? rows : [{
      version: CFG.APP_VERSION || "v1.0",
      apk_url: CFG.APK_URL,
      notes_en: "Universal build for Android 7+ (ARM, ARM64, x86_64).",
      notes_ar: "نسخة شاملة لأندرويد 7 فأعلى (ARM، ARM64، x86_64).",
      published_at: "",
    }];
    var html = list.map(function (r, i) {
      var notes = lang === "ar"
        ? (r.notes_ar || r.notes_en || dict.noRelease)
        : (r.notes_en || r.notes_ar || dict.noRelease);
      var version = r.version || CFG.APP_VERSION || "v1.0";
      var url = r.apk_url || CFG.APK_URL || "#";
      var date = r.published_at
        ? new Date(r.published_at).toLocaleDateString(lang === "ar" ? "ar" : "en-GB")
        : "";
      return '<div class="version-card' + (i === 0 ? " latest" : "") + '">' +
        '<div class="version-tag">' + esc(version) + '</div>' +
        '<div><b>' + esc(version) + '</b>' + (i === 0 ? ' · ' + esc(dict.latest) : '') +
        '<p class="version-note">' + esc(notes) + '</p>' +
        (date ? '<div class="version-date">' + esc(date) + '</div>' : '') + '</div>' +
        '<a class="btn ' + (i === 0 ? "btn-primary" : "btn-ghost") + ' btn-small" href="' + esc(url) + '">' +
        esc(dict.downloadNow) + '</a></div>';
    }).join("");
    ["version-list", "version-list-home"].forEach(function (id) {
      var host = document.getElementById(id);
      if (host) host.innerHTML = html;
    });
  }

  function loadDynamic() {
    var lang = currentLang();
    setText("apk-sha", CFG.APK_SHA256 || "");
    setText("download-version", CFG.APP_VERSION || "v1.0");
    renderVersions(null, lang);
    var sb = supabase();
    if (!sb) return;
    Promise.allSettled([
      sb.from("app_releases").select("version,notes_ar,notes_en,apk_url,published_at")
        .eq("published", true).order("published_at", { ascending: false }).limit(50),
      sb.from("app_announcements").select("title_ar,title_en,body_ar,body_en")
        .eq("active", true).order("created_at", { ascending: false }).limit(2),
    ]).then(function (results) {
      var lang = currentLang();
      var rows = results[0].status === "fulfilled" ? (results[0].value.data || []) : [];
      if (rows.length) {
        lastReleases = rows;
        var rel = rows[0];
        setText("release-version", rel.version || CFG.APP_VERSION || "v1.0");
        setText("release-notes", lang === "ar"
          ? (rel.notes_ar || rel.notes_en || "")
          : (rel.notes_en || rel.notes_ar || ""));
        setText("download-version", rel.version || CFG.APP_VERSION || "v1.0");
        setHref("release-download", rel.apk_url || CFG.APK_URL);
        setHref("hero-download", rel.apk_url || CFG.APK_URL);
        renderVersions(rows, lang);
      }
      var ann = results[1].status === "fulfilled" ? results[1].value.data : [];
      var host = document.getElementById("announcements");
      if (host && ann && ann.length) {
        host.innerHTML = "";
        ann.forEach(function (a) {
          var card = document.createElement("div");
          var h = document.createElement("h3");
          h.textContent = lang === "ar" ? (a.title_ar || a.title_en) : (a.title_en || a.title_ar);
          var p = document.createElement("p");
          p.textContent = lang === "ar" ? (a.body_ar || a.body_en) : (a.body_en || a.body_ar);
          card.appendChild(h); card.appendChild(p); host.appendChild(card);
        });
        var section = host.closest("section");
        if (section) section.classList.remove("hidden");
      }
    });
  }

  function hideAdminLinks() {
    document.querySelectorAll('a[href*="/admin/"], a[href^="admin/"], [data-i18n="navAdmin"]')
      .forEach(function (el) { el.parentNode && el.parentNode.removeChild(el); });
  }

  function init() {
    hideAdminLinks();
    applyLang(currentLang());
    document.querySelectorAll(".lang-btn").forEach(function (b) {
      b.addEventListener("click", function () { applyLang(currentLang() === "ar" ? "en" : "ar"); });
    });

    var path = location.pathname.toLowerCase();
    document.querySelectorAll(".nav-links a").forEach(function (a) {
      var href = a.getAttribute("href") || "";
      if (href.indexOf("#") > 0) href = href.split("#")[0];
      if (href && path.indexOf(href.replace(/^\//, "").split("/")[0]) >= 0) {
        a.classList.add("active");
      }
    });
    setHref("link-apk", CFG.APK_URL);
    setHref("link-github", CFG.GITHUB_URL);
    setHref("link-releases", CFG.RELEASES_URL || (CFG.GITHUB_URL ? CFG.GITHUB_URL + "/releases" : "#"));
    setHref("link-releases-download", CFG.RELEASES_URL || (CFG.GITHUB_URL ? CFG.GITHUB_URL + "/releases" : "#"));
    setHref("link-telegram", CFG.TELEGRAM_URL);
    hideIfEmpty("link-telegram", CFG.TELEGRAM_URL);
    setHref("link-discord", CFG.DISCORD_URL);
    hideIfEmpty("link-discord", CFG.DISCORD_URL);
    setHref("link-support-mail", CFG.SUPPORT_EMAIL ? "mailto:" + CFG.SUPPORT_EMAIL : "#");
    setText("support-email", CFG.SUPPORT_EMAIL || "support@example.com");
    setText("year", String(new Date().getFullYear()));
    loadDynamic();

    // Discreet staff shortcut: the console stays unlinked and unindexed, but
    // an authorised admin can still reach it without publishing a URL.
    document.addEventListener("keydown", function (e) {
      if (e.ctrlKey && e.shiftKey && (e.key === "A" || e.key === "a")) {
        e.preventDefault();
        window.location.href = (CFG.SITE_BASE_URL || "") + "/admin/";
      }
    });
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
