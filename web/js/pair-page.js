(function () {
  "use strict";
  var CFG = window.X05_CONFIG || {};
  var scheme = CFG.APP_SCHEME || "x05";
  var q = new URLSearchParams(location.search);
  var input = document.getElementById("code");
  if (input && q.get("code")) input.value = q.get("code");
  function go() {
    if (!input) return;
    var code = input.value.trim();
    if (!code) return;
    location.replace(scheme + "://pair?code=" + encodeURIComponent(code));
  }
  var btn = document.getElementById("pairBtn");
  if (btn) btn.addEventListener("click", go);
  if (q.get("code")) setTimeout(go, 500);
})();
