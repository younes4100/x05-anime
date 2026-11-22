/* X05 ANIME discover rail.
 * Pulls real cover art and titles from AniList's public GraphQL API, caches it
 * briefly in localStorage, and degrades to a hand-picked poster set when the
 * network is unavailable. No keys, no backend, no content hosted by X05.
 */
(function () {
  "use strict";

  var CFG = window.X05_CONFIG || {};
  var CACHE_KEY = "x05_discover_v1";
  var CACHE_TTL = 30 * 60 * 1000;
  var API = "https://graphql.anilist.co";
  var QUERY = [
    "query X05Discover {",
    "  trending: Page(page: 1, perPage: 14) {",
    "    media(type: ANIME, sort: TRENDING_DESC) {",
    "      id title { romaji english native } coverImage { extraLarge large color }",
    "      bannerImage averageScore genres format seasonYear episodes duration",
    "      isAdult siteUrl",
    "    }",
    "  }",
    "  movies: Page(page: 1, perPage: 14) {",
    "    media(type: ANIME, format: MOVIE, sort: POPULARITY_DESC) {",
    "      id title { romaji english native } coverImage { extraLarge large color }",
    "      bannerImage averageScore genres format seasonYear episodes duration",
    "      isAdult siteUrl",
    "    }",
    "  }",
    "}",
  ].join("\n");

  // Real AniList cover URLs. Used only if the API cannot be reached, so the
  // page still looks like a cinema shelf instead of an empty blue box.
  var FALLBACK = {
    trending: [
      m(195604, "Black Clover Season 2", "bx195604-tSZcfKbVqSEG.jpg", "195604-lQpCzTziSA17.jpg", 88, 2026, "TV"),
      m(189123, "Blue Box Season 2", "bx189123-0secXELIhkIW.jpg", "189123-aGJ7pIDUo2Xs.jpg", 81, 2026, "TV"),
      m(191788, "Aoashi Season 2", "bx191788-XC6F24LdX6a4.jpg", "191788-tyhsHpXeF26X.jpg", 81, 2026, "TV"),
      m(21, "ONE PIECE", "bx21-ELSYx3yMPcKM.jpg", "21-wf37VakJmZqs.jpg", 87, 1999, "TV"),
      m(191656, "Even the Student Council Has Its Holes!", "bx191656-xFHtxM8SUTdU.png", "191656-JQILdzh3FQxN.jpg", 74, 2026, "TV"),
      m(202250, "Magic Repo Man", "bx202250-mpm2cvr92Au2.jpg", "", 62, 2026, "TV"),
    ],
    movies: [
      m(20954, "A Silent Voice", "bx20954-sYRfE5jQRtSB.jpg", "20954-f30bHMXa5Qoe.jpg", 88, 2016, "MOVIE"),
      m(21519, "Your Name.", "bx21519-SUo3ZQuCbYhJ.png", "21519-1ayMXgNlmByb.jpg", 85, 2016, "MOVIE"),
      m(112151, "Demon Slayer: Mugen Train", "bx112151-1qlQwPB1RrJe.png", "112151-eHCBz19nf2yC.jpg", 84, 2020, "MOVIE"),
      m(199, "Spirited Away", "bx199-sWefXJvXkDOb.jpg", "199-Sm2RU5PSqw7T.jpg", 86, 2001, "MOVIE"),
      m(131573, "JUJUTSU KAISEN 0", "bx131573-rpl82vDEDRm6.jpg", "131573-3veuVz5p0z2I.jpg", 83, 2021, "MOVIE"),
      m(99750, "I Want to Eat Your Pancreas", "bx99750-pNyly9d3MEgV.jpg", "99750-KPFW2Jv03b2B.jpg", 84, 2018, "MOVIE"),
    ],
  };

  function m(id, title, cover, banner, score, year, format) {
    return {
      id: id,
      title: { english: title, romaji: title },
      coverImage: {
        large: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/" + cover,
        extraLarge: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/" + cover,
      },
      bannerImage: banner
        ? "https://s4.anilist.co/file/anilistcdn/media/anime/banner/" + banner
        : "",
      averageScore: score,
      seasonYear: year,
      format: format,
      genres: [],
      siteUrl: "https://anilist.co/anime/" + id,
      isAdult: false,
    };
  }

  // Text-first cards for the Live tab: channels change constantly, so a static
  // logo set would go stale. The gradient fallback still keeps the shelf even.
  var LIVE = [
    live("bbc", "BBC World News", "News"),
    live("cnn", "CNN International", "News"),
    live("aljazeera", "Al Jazeera English", "News"),
    live("france24", "France 24", "News"),
    live("nhk", "NHK World", "Culture"),
    live("dw", "DW News", "News"),
  ];

  function live(id, title, genre) {
    return {
      id: id,
      title: { english: title, romaji: title },
      coverImage: {},
      format: "LIVE",
      genres: [genre],
      siteUrl: "#live",
      averageScore: null,
    };
  }

  var state = { data: null, tab: "trending", query: "", loading: false };
  var $ = function (id) { return document.getElementById(id); };

  function lang() {
    try { return localStorage.getItem("x05_lang") === "ar" ? "ar" : "en"; }
    catch (_) { return "en"; }
  }

  function L(ar, en) { return lang() === "ar" ? ar : en; }

  function esc(v) {
    return String(v == null ? "" : v).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }[c];
    });
  }

  function nameOf(item) {
    var t = item.title || {};
    return t.english || t.romaji || t.native || L("بدون عنوان", "Untitled");
  }

  function coverOf(item) {
    var c = item.coverImage || {};
    return c.extraLarge || c.large || "";
  }

  function scoreOf(item) {
    return item.averageScore == null ? "" : (item.averageScore / 10).toFixed(1);
  }

  function formatOf(item) {
    if (item.format === "LIVE") return L("مباشر", "LIVE");
    if (item.format === "MOVIE") return L("فيلم", "Movie");
    if (item.format === "OVA") return L("OVA", "OVA");
    if (item.format === "ONA") return L("ONA", "ONA");
    return L("مسلسل", "Series");
  }

  function cached() {
    try {
      var raw = localStorage.getItem(CACHE_KEY);
      if (!raw) return null;
      var parsed = JSON.parse(raw);
      if (!parsed || !parsed.at || Date.now() - parsed.at > CACHE_TTL) return null;
      return parsed.data;
    } catch (_) { return null; }
  }

  function remember(data) {
    try { localStorage.setItem(CACHE_KEY, JSON.stringify({ at: Date.now(), data: data })); }
    catch (_) {}
  }

  function clean(list) {
    return (list || []).filter(function (item) {
      return item && !item.isAdult && coverOf(item);
    }).slice(0, 14);
  }

  function load() {
    var hit = cached();
    if (hit && hit.trending && hit.movies) {
      state.data = hit;
      render();
      return Promise.resolve(hit);
    }
    state.loading = true;
    renderStatus(L("جارٍ تحميل الأغلفة…", "Loading cover art…"));
    return fetch(API, {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({ query: QUERY }),
    })
      .then(function (r) {
        if (!r.ok) throw new Error("HTTP " + r.status);
        return r.json();
      })
      .then(function (json) {
        if (json.errors && json.errors.length) throw new Error(json.errors[0].message);
        var data = {
          trending: clean(json.data.trending.media),
          movies: clean(json.data.movies.media),
        };
        if (!data.trending.length || !data.movies.length) throw new Error("empty");
        state.data = data;
        remember(data);
        return data;
      })
      .catch(function () {
        state.data = FALLBACK;
        return FALLBACK;
      })
      .then(function (data) {
        state.loading = false;
        render();
        return data;
      });
  }

  function visible() {
    if (state.tab === "live") {
      var liveList = LIVE;
      var lq = state.query.trim().toLowerCase();
      return lq
        ? liveList.filter(function (item) {
            return nameOf(item).toLowerCase().indexOf(lq) >= 0 ||
              (item.genres || []).join(" ").toLowerCase().indexOf(lq) >= 0;
          })
        : liveList;
    }
    if (!state.data) return [];
    var list = state.data[state.tab] || [];
    var q = state.query.trim().toLowerCase();
    if (!q) return list;
    return list.filter(function (item) {
      return nameOf(item).toLowerCase().indexOf(q) >= 0 ||
        (item.title.native || "").toLowerCase().indexOf(q) >= 0 ||
        (item.genres || []).join(" ").toLowerCase().indexOf(q) >= 0;
    });
  }

  function card(item, index) {
    var cover = coverOf(item);
    var score = scoreOf(item);
    var title = nameOf(item);
    var href = item.siteUrl || "#";
    var external = item.format !== "LIVE";
    var target = external ? ' target="_blank" rel="noopener"' : "";
    var art = cover
      ? '<img class="poster-art" src="' + esc(cover) + '" alt="' + esc(title) + '" loading="lazy" referrerpolicy="no-referrer" />'
      : '<div class="poster-art poster-fallback"><span>' + esc(title.charAt(0)) + '</span></div>';
    return '<article class="poster-card reveal" style="--delay:' + Math.min(index * 45, 360) + 'ms">' +
      '<a class="poster-link" href="' + esc(href) + '"' + target + ' ' +
      'aria-label="' + esc(title) + '">' +
      art +
      '<span class="poster-shade"></span>' +
      '<span class="poster-rank">' + String(index + 1).padStart(2, "0") + '</span>' +
      (score ? '<span class="poster-score">★ ' + esc(score) + '</span>' : '') +
      '<span class="poster-info">' +
      '<span class="poster-format">' + esc(formatOf(item)) + (item.seasonYear ? ' · ' + esc(item.seasonYear) : '') + '</span>' +
      '<strong>' + esc(title) + '</strong>' +
      '</span></a></article>';
  }

  function skeleton(count) {
    var out = "";
    for (var i = 0; i < count; i++) out += '<div class="poster-card skeleton"></div>';
    return out;
  }

  function renderWall() {
    var host = $("heroPosterWall");
    if (!host || !state.data) return;
    var picks = (state.data.trending || []).slice(0, 6);
    host.innerHTML = picks.map(function (item, i) {
      return '<div class="wall-poster" style="--i:' + i + '">' +
        '<img src="' + esc(coverOf(item)) + '" alt="" loading="lazy" referrerpolicy="no-referrer" />' +
        '</div>';
    }).join("");
  }

  function renderTicker() {
    var host = $("discoverTicker");
    if (!host || !state.data) return;
    var picks = (state.data.trending || []).slice(0, 10);
    var line = picks.map(function (item) {
      return '<span class="ticker-item"><i></i>' + esc(nameOf(item)) + '</span>';
    }).join("");
    host.innerHTML = line + line; // duplicated for a seamless loop
  }

  function renderSpotlight() {
    var host = $("spotlight");
    if (!host || !state.data) return;
    var item = (state.data.movies || state.data.trending || [])[0];
    if (!item) return;
    var banner = item.bannerImage || coverOf(item);
    var score = scoreOf(item);
    var desc = (item.description || "").replace(/<[^>]*>/g, "").slice(0, 180);
    host.style.setProperty("--spotlight", banner ? "url('" + banner.replace(/'/g, "%27") + "')" : "none");
    host.innerHTML =
      '<div class="spotlight-glow"></div>' +
      '<div class="spotlight-copy">' +
      '<span class="eyebrow">' + L("فيلم الأسبوع", "Film of the week") + '</span>' +
      '<h3>' + esc(nameOf(item)) + '</h3>' +
      '<p>' + esc(desc || L("أغلق عينيك وابدأ الماراثون.", "Pick a title and start the marathon.")) + '</p>' +
      '<div class="spotlight-meta">' +
      (score ? '<span class="meta-pill">★ ' + esc(score) + '</span>' : '') +
      (item.seasonYear ? '<span class="meta-pill">' + esc(item.seasonYear) + '</span>' : '') +
      '<span class="meta-pill">' + esc(formatOf(item)) + '</span>' +
      '</div>' +
      '<div class="hero-cta">' +
      '<a class="btn btn-primary" href="' + esc(item.siteUrl || "#") + '" target="_blank" rel="noopener">' + L("عرض التفاصيل", "View details") + '</a>' +
      '<a class="btn btn-ghost" href="download.html">' + L("شاهد في التطبيق", "Watch in the app") + '</a>' +
      '</div></div>';
  }

  function renderRail() {
    var host = $("discoverRail");
    if (!host || !state.data) return;
    var list = visible();
    if (!list.length) {
      host.innerHTML = '<div class="discover-empty">' +
        L("لا نتائج. جرّب اسمًا آخر.", "No matches. Try another title.") + '</div>';
      return;
    }
    host.innerHTML = list.map(card).join("");
    observeReveals(host);
  }

  function renderStatus(text) {
    var host = $("discoverStatus");
    if (host) host.textContent = text || "";
  }

  function observeReveals(root) {
    if (!("IntersectionObserver" in window)) return;
    var nodes = root.querySelectorAll(".reveal");
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add("in-view"); io.unobserve(e.target); }
      });
    }, { threshold: 0.12 });
    nodes.forEach(function (n) { io.observe(n); });
  }

  function render() {
    if (!state.data) {
      var wall = $("heroPosterWall");
      if (wall) wall.innerHTML = skeleton(6);
      var rail = $("discoverRail");
      if (rail) rail.innerHTML = skeleton(8);
      return;
    }
    renderWall();
    renderTicker();
    renderSpotlight();
    renderRail();
    renderStatus("");
    document.querySelectorAll("[data-discover-tab]").forEach(function (btn) {
      btn.classList.toggle("active", btn.getAttribute("data-discover-tab") === state.tab);
    });
  }

  function init() {
    if (!$("discoverRail")) return;
    render();
    observeReveals(document);
    document.querySelectorAll("[data-discover-tab]").forEach(function (btn) {
      btn.addEventListener("click", function () {
        state.tab = btn.getAttribute("data-discover-tab");
        renderRail();
      });
    });
    var search = $("discoverSearch");
    if (search) {
      search.addEventListener("input", function () {
        state.query = search.value || "";
        renderRail();
      });
    }
    document.addEventListener("x05:langchange", function () {
      render();
      var ph = $("discoverSearch");
      if (ph) ph.placeholder = L("ابحث عن عنوان أو نوع…", "Search a title or genre…");
    });
    var ph = $("discoverSearch");
    if (ph) ph.placeholder = L("ابحث عن عنوان أو نوع…", "Search a title or genre…");
    load();
  }

  window.X05Discover = { init: init, render: render, load: load };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
