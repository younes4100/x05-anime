(function () {
  "use strict";
  var CFG = window.X05_CONFIG || {};
  var scheme = CFG.APP_SCHEME || "x05";
  var deep = scheme + "://open" + (location.search || "?");
  var btn = document.getElementById("openBtn");
  if (btn) btn.href = deep;
  setTimeout(function () { location.replace(deep); }, 700);
})();
