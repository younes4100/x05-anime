(function () {
  "use strict";

  var CFG = window.X05_CONFIG || {};
  var sb = null;
  if (!CFG.SUPABASE_URL || !CFG.SUPABASE_ANON_KEY || !window.supabase) {
    document.getElementById("loginMsg").className = "msg err";
    document.getElementById("loginMsg").textContent = "Supabase config is missing in web/config.js.";
    return;
  }
  sb = window.supabase.createClient(CFG.SUPABASE_URL, CFG.SUPABASE_ANON_KEY);

  var $ = function (id) { return document.getElementById(id); };
  var loginView = $("loginView"), adminView = $("adminView");
  var loginMsg = $("loginMsg"), globalMsg = $("globalMsg"), busyEl = $("busy");

  function say(el, text, ok) { el.className = "msg " + (ok ? "ok" : "err"); el.textContent = text || ""; }
  function esc(v) {
    return String(v == null ? "" : v).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }[c];
    });
  }
  function busy(on) { busyEl.classList.toggle("hidden", !on); }
  function val(id) { return ($(id) ? $(id).value.trim() : ""); }

  function showAdmin(email) {
    loginView.classList.add("hidden");
    adminView.classList.remove("hidden");
    $("logoutBtn").classList.remove("hidden");
    $("adminEmail").textContent = email || "";
    refreshAll();
  }
  function showLogin(message) {
    adminView.classList.add("hidden");
    loginView.classList.remove("hidden");
    $("logoutBtn").classList.add("hidden");
    $("adminEmail").textContent = "";
    if (message) say(loginMsg, message, false);
  }

  function assert(result) {
    if (result && result.error) throw result.error;
    return result;
  }

  function checkAccess() {
    return sb.rpc("is_admin").then(function (res) {
      if (res.error) throw res.error;
      if (!res.data) throw new Error("This account is not in the admin allowlist.");
      return sb.auth.getUser();
    }).then(function (res) {
      if (res.error) throw res.error;
      showAdmin(res.data.user.email);
    }).catch(function (e) {
      sb.auth.signOut();
      showLogin((e && e.message) || "Access denied.");
    });
  }

  $("loginBtn").addEventListener("click", function () {
    var email = val("email"), password = val("password");
    if (!email || !password) { say(loginMsg, "Email and password required.", false); return; }
    $("loginBtn").disabled = true; say(loginMsg, "Signing in…", true);
    sb.auth.signInWithPassword({ email: email, password: password })
      .then(function (res) { assert(res); return checkAccess(); })
      .catch(function (e) { say(loginMsg, (e && e.message) || "Sign-in failed.", false); })
      .finally(function () { $("loginBtn").disabled = false; });
  });
  $("logoutBtn").addEventListener("click", function () {
    sb.auth.signOut().then(function () { showLogin("Signed out."); });
  });
  sb.auth.onAuthStateChange(function (event, session) {
    if (event === "SIGNED_OUT") showLogin();
  });

  // Tabs
  var titles = {
    overview: ["Overview", "Live data from Supabase."],
    announcements: ["Announcements", "إعلانات التطبيق داخل التطبيق."],
    releases: ["Releases", "إصدارات APK وملاحظات التحديث."],
    reports: ["Reports", "بلاغات المستخدمين."],
    users: ["Users", "المستخدمون المسجّلون."],
    admins: ["Admins", "السماح بالوصول للوحة الأدمن."],
  };
  document.querySelectorAll(".tab-btn").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var tab = btn.getAttribute("data-tab");
      document.querySelectorAll(".tab-btn").forEach(function (b) { b.classList.toggle("active", b === btn); });
      document.querySelectorAll(".tab-panel").forEach(function (p) { p.classList.toggle("active", p.id === "tab-" + tab); });
      $("pageTitle").textContent = titles[tab][0];
      $("pageSub").textContent = titles[tab][1];
      loadTab(tab);
    });
  });

  function refreshAll() {
    ["overview", "announcements", "releases", "reports", "users", "admins"].forEach(loadTab);
  }

  function loadTab(tab) {
    busy(true);
    if (tab === "overview") return loadOverview().finally(function () { busy(false); });
    if (tab === "announcements") return loadAnnouncements().finally(function () { busy(false); });
    if (tab === "releases") return loadReleases().finally(function () { busy(false); });
    if (tab === "reports") return loadReports().finally(function () { busy(false); });
    if (tab === "users") return loadUsers().finally(function () { busy(false); });
    if (tab === "admins") return loadAdmins().finally(function () { busy(false); });
  }

  function loadOverview() {
    return sb.rpc("admin_dashboard_stats").then(function (res) {
      var d = (res.data && typeof res.data === "object") ? res.data : {};
      var cards = [
        ["Users", d.users || 0], ["Announcements", d.announcements || 0],
        ["Releases", d.releases || 0], ["Open reports", d.open_reports || 0],
      ];
      $("statCards").innerHTML = cards.map(function (c) {
        return '<div class="card"><div class="stat">' + esc(c[1]) + '</div><div class="stat-label">' + esc(c[0]) + '</div></div>';
      }).join("");
    }).catch(function () {
      $("statCards").innerHTML = '<div class="notice warn">Run web/admin/schema.sql to enable dashboard stats.</div>';
    });
  }

  function loadAnnouncements() {
    return sb.from("app_announcements").select("*").order("created_at", { ascending: false })
      .then(function (res) {
        assert(res);
        $("anList").innerHTML = (res.data || []).map(function (a) {
          return "<tr><td>" + esc(a.title_en || a.title_ar) + "<br><small style='color:var(--muted)'>" + esc(a.title_ar || "") + "</small></td>" +
            "<td>" + esc((a.body_en || a.body_ar || "").slice(0, 100)) + "</td>" +
            "<td><span class='pill " + (a.active ? "ok" : "off") + "'>" + (a.active ? "Active" : "Hidden") + "</span></td>" +
            "<td><button class='btn btn-ghost btn-small' data-toggle-an='" + esc(a.id) + "' data-val='" + (a.active ? "0" : "1") + "'>" + (a.active ? "Hide" : "Show") + "</button> " +
            "<button class='btn btn-ghost btn-small' data-del-an='" + esc(a.id) + "'>Delete</button></td></tr>";
        }).join("") || "<tr><td colspan='4' style='color:var(--muted)'>No announcements.</td></tr>";
        bind("toggle-an", function (id, node) { return sb.from("app_announcements").update({ active: node.getAttribute("data-val") === "1" }).eq("id", id).then(assert).then(function () { loadAnnouncements(); }); });
        bind("del-an", function (id) { return sb.from("app_announcements").delete().eq("id", id).then(assert).then(function () { loadAnnouncements(); }); });
      }).catch(function (e) { say(globalMsg, (e && e.message) || "Failed to load announcements.", false); });
  }

  function loadReleases() {
    return sb.from("app_releases").select("*").order("published_at", { ascending: false })
      .then(function (res) {
        assert(res);
        $("relList").innerHTML = (res.data || []).map(function (r) {
          var date = r.published_at
            ? new Date(r.published_at).toLocaleDateString("en-GB")
            : "—";
          var apk = r.apk_url
            ? "<a href='" + esc(r.apk_url) + "' target='_blank' rel='noopener'>APK</a>"
            : "—";
          return "<tr><td>" + esc(r.version) + "</td><td>" + esc((r.notes_en || r.notes_ar || "").slice(0, 90)) + "</td>" +
            "<td>" + apk + "</td><td>" + esc(date) + "</td>" +
            "<td><span class='pill " + (r.published ? "ok" : "off") + "'>" + (r.published ? "Published" : "Draft") + "</span></td>" +
            "<td><button class='btn btn-ghost btn-small' data-toggle-rel='" + esc(r.id) + "' data-val='" + (r.published ? "0" : "1") + "'>" + (r.published ? "Unpublish" : "Publish") + "</button> " +
            "<button class='btn btn-ghost btn-small' data-del-rel='" + esc(r.id) + "'>Delete</button></td></tr>";
        }).join("") || "<tr><td colspan='6' style='color:var(--muted)'>No releases.</td></tr>";
        bind("toggle-rel", function (id, node) { return sb.from("app_releases").update({ published: node.getAttribute("data-val") === "1" }).eq("id", id).then(assert).then(function () { loadReleases(); }); });
        bind("del-rel", function (id) { return sb.from("app_releases").delete().eq("id", id).then(assert).then(function () { loadReleases(); }); });
      }).catch(function (e) { say(globalMsg, (e && e.message) || "Failed to load releases.", false); });
  }

  function loadReports() {
    return sb.from("app_reports").select("*").order("created_at", { ascending: false })
      .then(function (res) {
        assert(res);
        $("reportList").innerHTML = (res.data || []).map(function (r) {
          return "<tr><td>" + esc(r.title) + "</td><td>" + esc(r.category || "") + "</td><td>" + esc((r.details || "").slice(0, 90)) + "</td>" +
            "<td><select data-status-report='" + esc(r.id) + "'><option" + (r.status === "open" ? " selected" : "") + ">open</option><option" + (r.status === "reviewing" ? " selected" : "") + ">reviewing</option><option" + (r.status === "resolved" ? " selected" : "") + ">resolved</option></select></td>" +
            "<td><button class='btn btn-ghost btn-small' data-del-report='" + esc(r.id) + "'>Delete</button></td></tr>";
        }).join("") || "<tr><td colspan='5' style='color:var(--muted)'>No reports.</td></tr>";
        document.querySelectorAll("[data-status-report]").forEach(function (sel) {
          sel.addEventListener("change", function () {
            sb.from("app_reports").update({ status: sel.value }).eq("id", sel.getAttribute("data-status-report")).then(assert).catch(function (e) { say(globalMsg, e.message, false); });
          });
        });
        bind("del-report", function (id) { return sb.from("app_reports").delete().eq("id", id).then(assert).then(function () { loadReports(); }); });
      }).catch(function (e) { say(globalMsg, (e && e.message) || "Failed to load reports.", false); });
  }

  function loadUsers() {
    return sb.rpc("admin_list_users").then(function (res) {
      assert(res);
      $("userList").innerHTML = (res.data || []).map(function (u) {
        return "<tr><td>" + esc(u.email) + "</td><td>" + esc(u.created_at || "") + "</td><td>" + esc(u.last_sign_in_at || "") + "</td><td><small>" + esc(u.id) + "</small></td></tr>";
      }).join("") || "<tr><td colspan='4' style='color:var(--muted)'>No users.</td></tr>";
    }).catch(function (e) { say(globalMsg, (e && e.message) || "admin_list_users() is not installed.", false); });
  }

  function loadAdmins() {
    return sb.from("admin_emails").select("email").order("email")
      .then(function (res) {
        assert(res);
        $("adminList").innerHTML = (res.data || []).map(function (a) {
          return "<tr><td>" + esc(a.email) + "</td><td><button class='btn btn-ghost btn-small' data-del-admin='" + esc(a.email) + "'>Remove</button></td></tr>";
        }).join("") || "<tr><td colspan='2' style='color:var(--muted)'>No allowlist rows yet.</td></tr>";
        bind("del-admin", function (email) {
          if (email.toLowerCase() === ($("adminEmail").textContent || "").toLowerCase()) {
            say(globalMsg, "You cannot remove your own admin access.", false); return Promise.resolve();
          }
          return sb.from("admin_emails").delete().eq("email", email).then(assert).then(function () { loadAdmins(); });
        });
      }).catch(function (e) { say(globalMsg, (e && e.message) || "Failed to load admins.", false); });
  }

  function bind(attr, handler) {
    document.querySelectorAll("[" + attr + "]").forEach(function (node) {
      node.addEventListener("click", function () {
        var id = node.getAttribute(attr);
        busy(true);
        handler(id, node).catch(function (e) { say(globalMsg, (e && e.message) || "Action failed.", false); }).finally(function () { busy(false); });
      });
    });
  }

  $("anSave").addEventListener("click", function () {
    var payload = {
      title_ar: val("anTitleAr"), title_en: val("anTitleEn"),
      body_ar: val("anBodyAr"), body_en: val("anBodyEn"), active: true,
    };
    if (!payload.title_ar && !payload.title_en) { say(globalMsg, "Add at least one title.", false); return; }
    sb.from("app_announcements").insert(payload).then(assert).then(function () {
      ["anTitleAr","anTitleEn","anBodyAr","anBodyEn"].forEach(function (id) { $(id).value = ""; });
      say(globalMsg, "Announcement published.", true); loadAnnouncements();
    }).catch(function (e) { say(globalMsg, e.message, false); });
  });

  $("relSave").addEventListener("click", function () {
    var payload = {
      version: val("relVersion"), apk_url: val("relUrl"),
      notes_ar: val("relNotesAr"), notes_en: val("relNotesEn"), published: true,
    };
    if (!payload.version || !payload.apk_url) { say(globalMsg, "Version and APK URL are required.", false); return; }
    sb.from("app_releases").insert(payload).then(assert).then(function () {
      ["relVersion","relUrl","relNotesAr","relNotesEn"].forEach(function (id) { $(id).value = ""; });
      say(globalMsg, "Release published.", true); loadReleases();
    }).catch(function (e) { say(globalMsg, e.message, false); });
  });

  $("adminAdd").addEventListener("click", function () {
    var email = val("adminEmailInput");
    if (!email) { say(globalMsg, "Enter an email.", false); return; }
    sb.from("admin_emails").insert({ email: email.toLowerCase() }).then(assert).then(function () {
      $("adminEmailInput").value = ""; say(globalMsg, "Admin added.", true); loadAdmins();
    }).catch(function (e) { say(globalMsg, e.message, false); });
  });

  sb.auth.getSession().then(function (res) {
    if (res.data && res.data.session) checkAccess(); else showLogin();
  });
})();
