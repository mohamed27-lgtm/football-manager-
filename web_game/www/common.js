/* common.js — معالجة موحدة للصور المفقودة (شعارات الأندية والبطولات) + إصلاح حساسية حالة الأحرف */
(function () {
  function hash(s) { var h = 0; for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0; return h; }
  function crest(name) {
    var h = hash(name), hue = h % 360;
    var w = name.replace(/\b(FC|CF|SC|AC|AS|SD|UD|CD|RCD|FK|SK|BK|IF|FF|SV|VfL|VfB|TSG|1\.|de|la|the|club|club de)\b/gi, '').trim().split(/\s+/).filter(Boolean);
    var ini = ((w[0] || name).charAt(0) + (w[1] ? w[1].charAt(0) : '')).toUpperCase();
    var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 120"><defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="hsl(' + hue + ',55%,42%)"/><stop offset="1" stop-color="hsl(' + hue + ',60%,24%)"/></linearGradient></defs><path d="M10 8h80v50c0 30-22 46-40 54C32 104 10 88 10 58z" fill="url(#g)" stroke="rgba(255,255,255,.55)" stroke-width="4"/><text x="50" y="68" text-anchor="middle" font-family="Arial,sans-serif" font-weight="800" font-size="38" fill="#fff">' + ini.replace(/[<&]/g, '') + '</text></svg>';
    return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
  }
  function cup() {
    var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="46" fill="#1b293b" stroke="#D5AE62" stroke-width="3"/><text x="50" y="66" text-anchor="middle" font-size="46">🏆</text></svg>';
    return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
  }
  document.addEventListener('error', function (e) {
    var t = e.target;
    if (!t || t.tagName !== 'IMG') return;
    var src = t.getAttribute('src') || '';
    if (src.indexOf('data:') === 0) return;
    var step = +(t.dataset.fb || 0);
    var m = src.match(/^(teams_logos|leagues_logos|competition_logos|trophies|confed_logos|company_logos)\/(.*)\.png$/i);
    if (!m) return;
    var dir = m[1], file;
    try { file = decodeURIComponent(m[2]); } catch (x) { file = m[2]; }
    if (step === 0 && file !== file.toLowerCase()) {      // نظام ملفات حسّاس لحالة الأحرف
      t.dataset.fb = 1; t.src = dir + '/' + encodeURIComponent(file.toLowerCase()) + '.png'; return;
    }
    t.dataset.fb = 9;
    t.src = dir === 'teams_logos' ? crest(file || '?') : cup();
  }, true);
  try {
    var lang = localStorage.getItem('gameLanguage') || 'ar';
    document.documentElement.lang = lang;
  } catch (x) {}
})();
