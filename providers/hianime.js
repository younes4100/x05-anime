// HiAnime provider — https://hianime.fm (redirect target of hianime.at).
//
// X05 ANIME bundles this as its ready-to-use source so a fresh install can
// play anime immediately. It uses HiAnime's public pages plus the theme API
// (/api/theme/episode/list/... and /api/theme/episode/servers?episodeId=...)
// and decodes the ZokoAnime/MegaPlay embed payload (window.__P, base64 then
// XOR with `otaku-embed-v1`) to reach the HLS master playlist and its WebVTT
// subtitle tracks.
//
// HiAnime is a third-party site. X05 ANIME does not host or provide any
// content and is not affiliated with HiAnime.

var SOURCE_ID = (typeof __SOURCE_ID !== 'undefined' && __SOURCE_ID)
  ? String(__SOURCE_ID) : 'hianime';
var UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
var EMBED_KEY = 'otaku-embed-v1';
var BASES = ['https://hianime.fm', 'https://hianime.at'];
var BASE = BASES[0];

// A successful embed resolve is reused briefly. The stream host is flaky and
// the app may ask for the same episode again (Retry, mirror sheet, next
// episode preheat), so hammering it on every tap only makes it worse.
var _resolveCache = {};
var _RESOLVE_TTL_MS = 5 * 60 * 1000;

function _errText(e) {
  if (!e) return 'unknown';
  if (typeof e === 'string') return e;
  if (e.message) return String(e.message);
  try { return JSON.stringify(e); } catch (_) { return String(e); }
}

// --- small helpers ----------------------------------------------------------

function _delay(ms) {
  return new Promise(function (resolve) { setTimeout(resolve, ms); });
}

function _origin(u) {
  var m = String(u || '').match(/^(https?:\/\/[^\/]+)/i);
  return m ? m[1] : '';
}

function _has(obj, key) {
  return Object.prototype.hasOwnProperty.call(obj, key);
}

function _abs(base, rel) {
  if (/^https?:\/\//i.test(rel)) return rel;
  if (rel.indexOf('//') === 0) return 'https:' + rel;
  if (rel.charAt(0) === '/') return _origin(base) + rel;
  return base.substring(0, base.lastIndexOf('/') + 1) + rel;
}

function _unescape(s) {
  s = String(s == null ? '' : s);
  s = s.replace(/&#x([0-9a-f]+);/gi, function (_, h) {
    return String.fromCharCode(parseInt(h, 16));
  });
  s = s.replace(/&#(\d+);/g, function (_, d) {
    return String.fromCharCode(parseInt(d, 10));
  });
  return s
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&nbsp;/g, ' ');
}

function _stripTags(s) {
  return _unescape(String(s || '').replace(/<[^>]*>/g, ' '))
    .replace(/\s+/g, ' ')
    .trim();
}

function _slugFromUrl(u) {
  var s = String(u || '').split('#')[0].split('?')[0].replace(/\/+$/, '');
  var i = s.lastIndexOf('/');
  return i >= 0 ? s.substring(i + 1) : s;
}

function _numFromSlug(slug) {
  var m = String(slug || '').match(/-(\d+)$/);
  if (m) return m[1];
  if (/^\d+$/.test(String(slug))) return String(slug);
  return '';
}

function _canonicalPageUrl(href) {
  return String(href || '').replace(/\/watch\//, '/');
}

function _matchAll(text, re) {
  var out = [];
  var m;
  while ((m = re.exec(text)) !== null) out.push(m);
  if (re.lastIndex) re.lastIndex = 0;
  return out;
}

// --- transport --------------------------------------------------------------

// Resolves `path` against the cached domain and falls back to the other entry
// domains when a host is unreachable. The final URL (after redirects, e.g.
// hianime.at -> hianime.fm) becomes the cached base for later API calls.
function _request(url, opts, tries) {
  opts = opts || {};
  var headers = {};
  var src = opts.headers || {};
  for (var k in src) if (_has(src, k)) headers[k] = src[k];
  if (!_has(headers, 'User-Agent')) headers['User-Agent'] = UA;
  if (!_has(headers, 'Accept')) headers['Accept'] = 'text/html,application/xhtml+xml,application/json;q=0.9,*/*;q=0.8';

  var remaining = tries == null ? 3 : tries;
  function retry(n) {
    var wait = 180 + 220 * (remaining - n);
    return _delay(wait > 1100 ? 1100 : wait).then(function () {
      return attempt(n - 1);
    });
  }
  function attempt(n) {
    var o = {
      headers: headers,
      method: opts.method || 'GET',
      // Short attempts + real retries beat one long hang on the flaky host.
      timeoutMs: opts.timeoutMs || 9000,
      browser: opts.browser === true
    };
    if (opts.body != null) o.body = opts.body;
    return fetch(url, o).then(function (r) {
      if (r.status >= 500 && n > 1) return retry(n);
      return r;
    }).catch(function (e) {
      if (n > 1) return retry(n);
      throw e;
    });
  }
  return attempt(Math.max(1, remaining));
}

function _get(path, opts) {
  opts = opts || {};
  var bases = [BASE];
  for (var i = 0; i < BASES.length; i++) {
    if (bases.indexOf(BASES[i]) < 0) bases.push(BASES[i]);
  }
  var idx = 0;
  function attempt() {
    if (idx >= bases.length) {
      return Promise.reject(new Error('HiAnime: every domain failed'));
    }
    var base = bases[idx++];
    var url = /^https?:\/\//i.test(path) ? path : base + path;
    return _request(url, opts, 2).then(function (r) {
      var body = r.body == null ? '' : String(r.body);
      var challenged = r.status === 403 || r.status === 503 ||
        /just a moment|checking your browser|cf-challenge/i.test(body.substring(0, 2500));
      if (challenged && !opts.browser) {
        // One Cloudflare-solver pass, then treat the answer normally.
        return _request(url, {
          headers: opts.headers, timeoutMs: opts.timeoutMs, browser: true
        }, 1).then(function (cf) {
          if (!cf.ok) throw new Error('HiAnime: challenge ' + cf.status);
          var o0 = _origin(cf.url); if (o0) BASE = o0;
          return cf;
        });
      }
      if (!r.ok) throw new Error('HiAnime: HTTP ' + r.status + ' ' + path);
      if (body.length < 20) throw new Error('HiAnime: empty response ' + path);
      var o = _origin(r.url); if (o) BASE = o;
      return r;
    }).catch(function () {
      return attempt();
    });
  }
  return attempt();
}

function _getJson(path, opts) {
  return _get(path, opts).then(function (r) {
    var body = String(r.body || '').replace(/^\uFEFF/, '');
    try { return JSON.parse(body); }
    catch (e) { throw new Error('HiAnime: bad JSON ' + path); }
  });
}

// --- HTML parsing -----------------------------------------------------------

// Splits the page into per-title blocks. Search/home rows use `flw-item`;
// the Trending carousel uses plain `swiper-slide` items.
function _itemBlocks(html) {
  html = String(html || '');
  var marker = '<div class="flw-item';
  var start = html.indexOf(marker);
  if (start < 0) {
    marker = '<div class="swiper-slide">';
    start = html.indexOf(marker);
  }
  if (start < 0) return [];
  var blocks = [];
  var i = start;
  while (i >= 0) {
    var next = html.indexOf(marker, i + marker.length);
    blocks.push(html.substring(i, next < 0 ? html.length : next));
    i = next;
  }
  return blocks;
}

function _parseItemBlock(block) {
  var hrefs = _matchAll(block, /href="(https?:\/\/[^"]+)"/gi);
  var href = '';
  for (var i = 0; i < hrefs.length; i++) {
    var h = hrefs[i][1];
    if (/hianime\.(fm|at)\/(community|news|genre|az-list|auth|app|user|contact|dmca)/i.test(h)) continue;
    href = h;
    break;
  }
  if (!href) return null;
  href = _canonicalPageUrl(href);
  var slug = _slugFromUrl(href);
  if (!slug) return null;

  var title = '';
  var tm = block.match(/class="(?:dynamic-name|film-title[^"]*)"[^>]*>([\s\S]*?)<\/(?:a|div)>/i);
  if (tm) title = _stripTags(tm[1]);
  if (!title) {
    var tt = block.match(/\btitle="([^"]+)"/i);
    if (tt) title = _unescape(tt[1]);
  }
  if (!title) return null;

  var cover = '';
  var cm = block.match(/<img[^>]+src="([^"]+)"[^>]*class="film-poster-img"/i) ||
    block.match(/class="film-poster-img"[^>]*src="([^"]+)"/i) ||
    block.match(/<img[^>]+src="(https?:\/\/[^"]+)"/i);
  if (cm) cover = _unescape(cm[1]);

  var subM = block.match(/tick-sub[^>]*>[\s\S]{0,160}?(\d+)\s*</i);
  var dubM = block.match(/tick-dub[^>]*>[\s\S]{0,160}?(\d+)\s*</i);
  var idM = block.match(/data-id="(\d+)"/i);

  return {
    id: idM ? idM[1] : slug,
    title: title,
    cover: cover || null,
    url: href,
    type: 'anime',
    sourceId: SOURCE_ID,
    subCount: subM ? parseInt(subM[1], 10) : 0,
    dubCount: dubM ? parseInt(dubM[1], 10) : 0
  };
}

function _dedupe(items) {
  var seen = {};
  var out = [];
  for (var i = 0; i < items.length; i++) {
    var it = items[i];
    if (!it || !it.url || seen[it.url]) continue;
    seen[it.url] = 1;
    out.push(it);
  }
  return out;
}

function _parseItems(html) {
  var blocks = _itemBlocks(html);
  var out = [];
  for (var i = 0; i < blocks.length; i++) {
    var it = _parseItemBlock(blocks[i]);
    if (it) out.push(it);
  }
  return _dedupe(out);
}

// --- provider API -----------------------------------------------------------

function getInfo() {
  return {
    name: SOURCE_ID === 'hianime_mirror' ? 'HiAnime Mirror' : 'HiAnime',
    lang: 'en',
    baseUrl: BASE,
    logo: BASE + '/favicon.ico',
    type: 'anime',
    version: '1.0.0'
  };
}

function search(query, page, opts) {
  var p = Math.max(1, parseInt(page, 10) || 1);
  var q = String(query == null ? '' : query).trim();
  if (!q) return Promise.resolve([]);
  return _get('/search?keyword=' + encodeURIComponent(q) + '&page=' + p, {
    timeoutMs: 9000
  }).then(function (r) { return _parseItems(r.body); });
}

var _homeCache = null;
var _homeAt = 0;

function _homeItems() {
  var now = Date.now ? Date.now() : 0;
  if (_homeCache && _homeCache.length && now - _homeAt < 10 * 60 * 1000) {
    return Promise.resolve(_homeCache);
  }
  return _get('/home', { timeoutMs: 9000 }).then(function (r) {
    var items = _parseItems(r.body);
    if (items.length) { _homeCache = items; _homeAt = now; }
    return items;
  });
}

function popular(opts) {
  opts = opts || {};
  return _homeItems().then(function (items) {
    if (!items.length) return [];
    var page = Math.max(1, parseInt(opts.page, 10) || 1);
    var size = Math.max(6, Math.min(30, parseInt(opts.size, 10) || 24));
    var start = ((page - 1) * size) % Math.max(1, items.length);
    return items.slice(start, start + size);
  }).catch(function () { return []; });
}

function getHome(opts) {
  return _homeItems().then(function (items) {
    if (!items.length) return [];
    var rows = [];
    function add(title, from, to) {
      var slice = items.slice(from, to);
      if (slice.length) rows.push({ title: title, items: slice });
    }
    add('Trending on HiAnime', 0, 24);
    add('Popular Now', 24, 48);
    add('More to Watch', 48, 72);
    return rows;
  }).catch(function () { return []; });
}

// Parses both the detail page metadata and the theme episode-list JSON.
function _parseEpisodes(listHtml, slug, mode) {
  var out = [];
  var seen = {};
  var re = /data-number="([^"]*)"[\s\S]{0,240}?data-id="(\d+)"/g;
  var m;
  while ((m = re.exec(listHtml)) !== null) {
    var label = String(m[1] == null ? '' : m[1]).trim();
    var id = String(m[2]);
    if (!id || seen[id]) continue;
    seen[id] = 1;
    var n = parseFloat(label);
    if (!isFinite(n)) n = out.length + 1;
    out.push({
      id: 'hi:' + id,
      title: label ? ('Episode ' + label) : ('Episode ' + (out.length + 1)),
      number: n,
      url: 'hianime://' + slug + '/' + mode + '/' + id + '/' + label
    });
  }
  out.sort(function (a, b) { return a.number - b.number; });
  return out;
}

function _detailMeta(html) {
  var title = '';
  var tm = html.match(/<h2 class="film-name[^"]*"[^>]*>([\s\S]*?)<\/h2>/i);
  if (tm) title = _stripTags(tm[1]);

  var cover = '';
  var cm = html.match(/<img[^>]+src="([^"]+)"[^>]*class="film-poster-img"/i) ||
    html.match(/class="film-poster-img"[^>]*src="([^"]+)"/i);
  if (cm) cover = _unescape(cm[1]);

  var description = '';
  var dm = html.match(/class="film-description[^"]*"[\s\S]*?<div class="text">([\s\S]*?)<\/div>/i);
  if (dm) description = _stripTags(dm[1]);

  var genres = [];
  var gm = html.match(/class="film-genres"[\s\S]*?<\/div>/i);
  if (gm) {
    var links = _matchAll(gm[0], /<a[^>]*>([\s\S]*?)<\/a>/gi);
    for (var i = 0; i < links.length; i++) {
      var g = _stripTags(links[i][1]);
      if (g) genres.push(g);
    }
  }
  var sm = html.match(/tick-sub[^>]*>[\s\S]{0,160}?(\d+)\s*</i);
  var dmm = html.match(/tick-dub[^>]*>[\s\S]{0,160}?(\d+)\s*</i);
  return {
    title: title,
    cover: cover,
    description: description,
    genres: genres,
    subCount: sm ? parseInt(sm[1], 10) : 0,
    dubCount: dmm ? parseInt(dmm[1], 10) : 0
  };
}

function _assembleDetail(slug, mode, numeric, html, j) {
  var meta = _detailMeta(html);
  var episodes = _parseEpisodes(String((j && j.html) || ''), slug, mode);
  return {
    id: numeric,
    title: meta.title || slug,
    englishTitle: null,
    cover: meta.cover || null,
    url: BASE + '/' + slug,
    description: meta.description || '',
    status: 'unknown',
    genres: meta.genres || [],
    studios: [],
    type: 'anime',
    sourceId: SOURCE_ID,
    episodes: episodes,
    subCount: meta.subCount || episodes.length,
    dubCount: meta.dubCount || 0
  };
}

function getDetail(url, opts) {
  opts = opts || {};
  var mode = opts.category === 'dub' ? 'dub' : 'sub';
  var slug = _slugFromUrl(url);
  if (!slug) return Promise.reject(new Error('HiAnime: bad show url'));
  var numeric = _numFromSlug(slug);
  var listOpts = {
    timeoutMs: 9000,
    headers: { 'Referer': BASE + '/' + slug }
  };
  if (numeric) {
    // The id is already in HiAnime's URL, so these two calls are independent.
    // Fetching them together avoids paying one slow hop after the other.
    return Promise.all([
      _get('/' + slug, { timeoutMs: 9000 }),
      _getJson('/api/theme/episode/list/' + numeric, listOpts)
    ]).then(function (both) {
      return _assembleDetail(
        slug, mode, numeric, String(both[0].body || ''), both[1]
      );
    });
  }
  return _get('/' + slug, { timeoutMs: 9000 }).then(function (r) {
    var html = String(r.body || '');
    var dm = html.match(/data-id="(\d+)"/i);
    var id = dm ? dm[1] : '';
    if (!id) throw new Error('HiAnime: show id missing');
    return _getJson('/api/theme/episode/list/' + id, listOpts).then(function (j) {
      return _assembleDetail(slug, mode, id, html, j);
    });
  });
}

function getEpisodes(url, opts) {
  return getDetail(url, opts).then(function (d) { return d.episodes; });
}

// --- episode servers / embed decode ----------------------------------------

function _parseEpisodeUrl(episodeUrl) {
  var raw = String(episodeUrl || '').trim();
  var mode = 'sub';
  var slug = '';
  var epId = '';
  var m;
  if (raw.indexOf('hianime://') === 0) {
    var parts = raw.substring('hianime://'.length).split('/');
    slug = parts[0] || '';
    mode = parts[1] === 'dub' ? 'dub' : 'sub';
    epId = parts[2] || '';
  } else {
    slug = _slugFromUrl(raw);
    m = raw.match(/[?&]ep=(\d+)/i);
    if (m) epId = m[1];
  }
  if (!/^\d+$/.test(epId)) return null;
  return { slug: slug, mode: mode, epId: epId };
}

function _parseServers(html) {
  html = String(html || '');
  var marker = '<div class="item server-item';
  var out = [];
  var seen = {};
  var i = html.indexOf(marker);
  while (i >= 0) {
    var next = html.indexOf(marker, i + marker.length);
    var block = html.substring(i, next < 0 ? html.length : next);
    var typeM = block.match(/data-type="(sub|dub)"/i);
    var nameM = block.match(/data-server-name="([^"]*)"/i);
    var hashM = block.match(/data-hash="([^"]+)"/i);
    if (typeM && nameM && hashM && !seen[hashM[1]]) {
      seen[hashM[1]] = 1;
      out.push({
        type: typeM[1].toLowerCase(),
        name: _unescape(nameM[1]),
        hash: hashM[1]
      });
    }
    i = next;
  }
  return out;
}

function _bytesToUtf8(bytes) {
  var out = '';
  var i = 0;
  var n = bytes.length;
  while (i < n) {
    var c = bytes[i++] & 255;
    if (c < 0x80) {
      out += String.fromCharCode(c);
    } else if (c < 0xE0 && i < n) {
      out += String.fromCharCode(((c & 0x1F) << 6) | (bytes[i++] & 0x3F));
    } else if (c < 0xF0 && i + 1 < n) {
      out += String.fromCharCode(
        ((c & 0x0F) << 12) | ((bytes[i++] & 0x3F) << 6) | (bytes[i++] & 0x3F)
      );
    } else if (i + 2 < n) {
      var cp = ((c & 0x07) << 18) | ((bytes[i++] & 0x3F) << 12) |
        ((bytes[i++] & 0x3F) << 6) | (bytes[i++] & 0x3F);
      cp -= 0x10000;
      out += String.fromCharCode(0xD800 + (cp >> 10), 0xDC00 + (cp & 0x3FF));
    }
  }
  return out;
}

function _decodeEmbedBlob(b64) {
  var bytes = base64ToBytes(String(b64));
  var key = [];
  for (var k = 0; k < EMBED_KEY.length; k++) key.push(EMBED_KEY.charCodeAt(k));
  var out = [];
  for (var i = 0; i < bytes.length; i++) {
    out.push((bytes[i] ^ key[i % key.length]) & 255);
  }
  return _bytesToUtf8(out);
}

function _extractBlob(html) {
  var m = String(html || '').match(/window\.__P\s*=\s*["']([^"']+)["']/i) ||
    String(html || '').match(/__P\s*=\s*["']([^"']+)["']/i);
  return m ? m[1] : '';
}

function _b64ToUtf8(b64) {
  return _bytesToUtf8(base64ToBytes(String(b64)));
}

function _mapSubtitles(list) {
  var out = [];
  if (!list || !list.length) return out;
  for (var i = 0; i < list.length; i++) {
    var st = list[i] || {};
    var src = st.src || st.url || st.file || '';
    if (!src) continue;
    var lang = st.lang || st.language || 'en';
    out.push({
      url: String(src),
      lang: String(lang),
      label: String(st.label || st.name || lang),
      format: /\.srt(\?|$)/i.test(src) ? 'srt' : 'vtt',
      'default': st['default'] === true
    });
  }
  return out;
}

function _qualityFromInf(inf) {
  var r = inf.match(/RESOLUTION=(\d+)x(\d+)/i);
  if (r) return String(parseInt(r[2], 10)) + 'p';
  var b = inf.match(/BANDWIDTH=(\d+)/i);
  if (b) return Math.round(parseInt(b[1], 10) / 1000) + 'kbps';
  return 'auto';
}

function _makeSource(url, quality, serverName, headers, mode, subs) {
  return {
    url: url,
    quality: quality || 'auto',
    label: serverName ? (serverName + (quality && quality !== 'auto' ? ' · ' + quality : '')) : null,
    container: /\.m3u8(\?|$)/i.test(url) ? 'hls' : (/\.mp4(\?|$)/i.test(url) ? 'mp4' : 'unknown'),
    headers: headers,
    kind: mode,
    audioLang: mode === 'dub' ? 'en' : 'ja',
    subtitles: subs || []
  };
}

// Expands a master playlist into one source per variant so the quality picker
// has real resolutions. Any failure falls back to the master URL itself.
function _expandVariants(masterUrl, headers, serverName, mode, subs) {
  var fallback = [_makeSource(masterUrl, 'auto', serverName, headers, mode, subs)];
  if (!/\.m3u8(\?|$)/i.test(masterUrl)) return Promise.resolve(fallback);
  return _request(masterUrl, { headers: headers, timeoutMs: 7000 }, 1)
    .then(function (r) {
      if (!r.ok) return fallback;
      var text = String(r.body || '');
      if (text.indexOf('#EXTM3U') < 0) return fallback;
      var lines = text.split(/\r?\n/);
      var base = masterUrl.substring(0, masterUrl.lastIndexOf('/') + 1);
      var out = [];
      var pending = null;
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (!line) continue;
        if (line.indexOf('#EXT-X-STREAM-INF:') === 0) {
          pending = line;
          continue;
        }
        if (line.charAt(0) === '#') continue;
        if (pending != null) {
          out.push(_makeSource(
            _abs(base, line), _qualityFromInf(pending),
            serverName, headers, mode, subs
          ));
          pending = null;
        }
      }
      return out.length ? out : fallback;
    })
    .catch(function () { return fallback; });
}

// ZokoAnime returns HTTP 200 with a themed "404 / Not found" page when a show
// has no stream yet (typical for titles that only premiered in cinemas). Never
// mistake that page for a missing embed blob — it means "not released here".
function _embedNotAvailable(body) {
  var s = String(body || '');
  if (s.indexOf('__P') >= 0 || s.indexOf('.m3u8') >= 0) return false;
  return /class="code">\s*404\s*</.test(s) ||
      /Not\s*<\s*span[^>]*>\s*found\./i.test(s) ||
      /couldn't find anything to play here/i.test(s);
}

function _resolveServer(server, mode) {
  var key = mode + '|' + server.hash;
  var now = Date.now ? Date.now() : 0;
  var hit = _resolveCache[key];
  if (hit && hit.sources && hit.sources.length &&
      now - hit.at < _RESOLVE_TTL_MS) {
    return Promise.resolve(hit.sources);
  }
  var embedUrl = '';
  try {
    embedUrl = _b64ToUtf8(server.hash);
  } catch (e) {
    return Promise.reject(new Error('HiAnime: bad server hash'));
  }
  if (!/^https?:\/\//i.test(embedUrl)) {
    return Promise.reject(new Error('HiAnime: bad embed url'));
  }
  var embedOrigin = _origin(embedUrl);
  var headers = {
    'Referer': embedOrigin + '/',
    'User-Agent': UA,
    'Accept': '*/*'
  };
  return _request(embedUrl, {
    headers: { 'Referer': BASE + '/', 'User-Agent': UA },
    timeoutMs: 9000
  }, 3).then(function (r) {
    if (!r.ok) throw new Error('HiAnime: embed ' + r.status);
    if (_embedNotAvailable(r.body)) {
      throw new Error('HiAnime: stream not available yet (not released)');
    }
    var blob = _extractBlob(r.body);
    if (!blob) throw new Error('HiAnime: embed payload missing');
    var info;
    try { info = JSON.parse(_decodeEmbedBlob(blob)); }
    catch (e) {
      // A few mirrors put a plain m3u8 straight in the page.
      var direct = String(r.body || '').match(/https?:\/\/[^"'\\]+\.m3u8[^"'\\]*/i);
      if (!direct) throw new Error('HiAnime: embed decode failed');
      return [_makeSource(direct[0], 'auto', server.name, headers, mode, [])];
    }
    var src = info && (info.src || (info.sources && info.sources[0] && info.sources[0].file));
    if (!src) throw new Error('HiAnime: no stream url');
    var subs = _mapSubtitles(info.subtitles || info.tracks || []);
    return _expandVariants(String(src), headers, server.name, mode, subs);
  }).then(function (groups) {
    if (groups && groups.length) {
      _resolveCache[key] = {
        at: Date.now ? Date.now() : 0,
        sources: groups
      };
    }
    return groups;
  });
}

// Sequential on purpose: firing every embed at once used to trigger the flaky
// host's connection limit and turn a working episode into "no playable
// sources". One good server already yields all quality variants, so stop at
// the first success and only fall through when it genuinely fails.
function _resolveServersInOrder(list, mode) {
  var i = 0;
  var failures = [];
  function next() {
    if (i >= list.length) {
      var suffix = failures.length ? ' (' + failures.join('; ') + ')' : '';
      // If every mirror reports "not released", say so plainly instead of
      // burying the useful reason inside a generic "no playable sources".
      var unreleased = failures.length > 0 && failures.every(function (f) {
        return /not available yet|not released|embed 404/i.test(f);
      });
      if (unreleased) {
        throw new Error('HiAnime: not released yet - no stream' + suffix);
      }
      throw new Error('HiAnime: no playable sources' + suffix);
    }
    var server = list[i++];
    return _resolveServer(server, mode).then(function (groups) {
      if (groups && groups.length) return groups;
      failures.push(server.name + ': empty');
      return next();
    }).catch(function (e) {
      var msg = _errText(e);
      failures.push(server.name + ': ' + msg);
      if (typeof console !== 'undefined' && console.warn) {
        console.warn('[hianime] ' + server.name + ' failed: ' + msg);
      }
      return next();
    });
  }
  return next();
}

function getVideoSources(episodeUrl) {
  var info = _parseEpisodeUrl(episodeUrl);
  if (!info) return Promise.reject(new Error('HiAnime: bad episode url'));
  return _getJson('/api/theme/episode/servers?episodeId=' + info.epId, {
    timeoutMs: 9000
  }).then(function (j) {
    var all = _parseServers(String((j && j.html) || ''));
    var list = [];
    for (var i = 0; i < all.length; i++) {
      if (all[i].type === info.mode) list.push(all[i]);
    }
    if (!list.length && info.mode === 'sub') list = all;
    if (!list.length) throw new Error('HiAnime: no ' + info.mode + ' servers');
    // ZokoAnime is the live mirror; HD-1 (megaply.buzz) no longer resolves.
    // Try Zoko first regardless of the order HiAnime happens to return.
    list.sort(function (a, b) {
      var pa = /zoko/i.test(a.name) ? 0 : 1;
      var pb = /zoko/i.test(b.name) ? 0 : 1;
      return pa - pb;
    });
    return _resolveServersInOrder(list.slice(0, 4), info.mode);
  });
}
