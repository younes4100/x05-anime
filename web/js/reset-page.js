(function () {
  "use strict";
  var CFG = window.X05_CONFIG || {};
  var msg = document.getElementById("msg");
  function say(text, ok) {
    if (!msg) return;
    msg.className = "msg " + (ok ? "ok" : "err");
    msg.textContent = text;
  }
  if (!CFG.SUPABASE_URL || !CFG.SUPABASE_ANON_KEY || !window.supabase) {
    say("Supabase config is missing in config.js.", false);
    return;
  }
  var sb = window.supabase.createClient(CFG.SUPABASE_URL, CFG.SUPABASE_ANON_KEY);

  function hashObject() {
    var out = {};
    location.hash.replace(/^#/, "").split("&").forEach(function (part) {
      if (!part) return;
      var kv = part.split("=");
      out[decodeURIComponent(kv[0])] = decodeURIComponent((kv[1] || "").replace(/\+/g, " "));
    });
    return out;
  }
  function showUpdate() {
    var requestBox = document.getElementById("requestBox");
    var updateBox = document.getElementById("updateBox");
    var subtitle = document.getElementById("subtitle");
    if (requestBox) requestBox.classList.add("hidden");
    if (updateBox) updateBox.classList.remove("hidden");
    if (subtitle) subtitle.textContent = "كلمة مرور جديدة / Choose a new password";
  }

  var h = hashObject();
  var code = new URLSearchParams(location.search).get("code");
  if (h.error_description) say(h.error_description, false);

  var ready = h.access_token && h.refresh_token
    ? sb.auth.setSession({ access_token: h.access_token, refresh_token: h.refresh_token })
    : code ? sb.auth.exchangeCodeForSession(code) : Promise.resolve(null);

  ready.then(function (res) {
    if (res && res.error) throw res.error;
    if ((h.access_token && h.refresh_token) || code) showUpdate();
  }).catch(function (e) {
    say((e && e.message) || "Invalid or expired reset link.", false);
  });

  var sendBtn = document.getElementById("sendBtn");
  if (sendBtn) sendBtn.addEventListener("click", function () {
    var email = document.getElementById("email").value.trim();
    if (!email) { say("أدخل البريد الإلكتروني / Enter your email.", false); return; }
    sendBtn.disabled = true;
    say("جارٍ الإرسال… / Sending…", true);
    sb.auth.resetPasswordForEmail(email, { redirectTo: CFG.SITE_BASE_URL + "/reset/" })
      .then(function (res) {
        if (res.error) throw res.error;
        say("تم الإرسال. تحقق من بريدك الإلكتروني. / Check your inbox.", true);
      })
      .catch(function (e) { say((e && e.message) || "Reset request failed.", false); })
      .finally(function () { sendBtn.disabled = false; });
  });

  var updateBtn = document.getElementById("updateBtn");
  if (updateBtn) updateBtn.addEventListener("click", function () {
    var pw = document.getElementById("pw").value;
    var pw2 = document.getElementById("pw2").value;
    if (pw.length < 8) { say("8 أحرف على الأقل / At least 8 characters.", false); return; }
    if (pw !== pw2) { say("كلمتا المرور غير متطابقتين / Passwords do not match.", false); return; }
    updateBtn.disabled = true;
    say("جارٍ التحديث… / Updating…", true);
    sb.auth.updateUser({ password: pw })
      .then(function (res) {
        if (res.error) throw res.error;
        say("✓ تم التحديث. افتح تطبيق X05 ANIME وسجّل الدخول. / Updated. Open X05 ANIME and sign in.", true);
        var box = document.getElementById("updateBox");
        if (box) box.querySelectorAll("input,button").forEach(function (i) { i.disabled = true; });
      })
      .catch(function (e) { say((e && e.message) || "Update failed.", false); updateBtn.disabled = false; });
  });
})();
