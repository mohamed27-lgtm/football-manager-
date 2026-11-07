/* core.js — حفظ احتياطي، تطور قوة الأندية بين المواسم، وتقرير افتتاحي مع مستوى الصعوبة */
(function () {
  var LS = window.localStorage;
  function get(k, d) { try { var v = LS.getItem(k); return v === null ? d : v; } catch (e) { return d; } }
  function set(k, v) { try { LS.setItem(k, v); } catch (e) {} }

  /* 1) نسخة احتياطية: تُستعاد تلقائياً إن ضاع المفتاح الأساسي */
  var BK = 'fcp_backup_v1';
  function snapshot() {
    try {
      if (!get('presidentialClub')) return;
      var o = {};
      for (var i = 0; i < LS.length; i++) { var k = LS.key(i); if (k !== BK && k.indexOf('fcp_tmp') !== 0) o[k] = LS.getItem(k); }
      var s = JSON.stringify({ v: 1, t: Date.now(), d: o });
      if (s.length < 4500000) LS.setItem(BK, s);
    } catch (e) {}
  }
  try {
    if (!get('presidentialClub') && get(BK)) {
      var b = JSON.parse(get(BK));
      if (b && b.d && b.d.presidentialClub) for (var k in b.d) set(k, b.d[k]);
    }
  } catch (e) {}
  setInterval(snapshot, 15000);
  window.addEventListener('pagehide', snapshot);

  /* 2) تطور قوة الأندية: انحراف صغير حتمي لكل موسم مع عودة للمتوسط */
  function hash(s) { var h = 2166136261 >>> 0; s = String(s); for (var i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0; } return h >>> 0; }
  function idx() {
    var m = parseInt(get('game_month')) || 9, y = parseInt(get('game_year')) || 2026;
    var sk = m >= 8 ? y : y - 1;
    var st = parseInt(get('fcp_start_season'));
    if (!st) { st = sk; set('fcp_start_season', String(st)); }
    return Math.max(0, sk - st);
  }
  function drift(club, n) {
    var d = 0;
    for (var i = 1; i <= n && i <= 12; i++) {
      var r = (hash(club + '|' + i) % 1000) / 1000 - 0.5;   // -0.5..0.5
      d = d * 0.8 + r * 3.2;                                // عودة للمتوسط
    }
    return d;
  }
  function patch() {
    if (!window.RLM || RLM.__driftPatched) return;
    var base = RLM.strength;
    RLM.strength = function (club) { return base(club) + drift(club, idx()); };
    RLM.__driftPatched = true;
  }
  patch(); document.addEventListener('DOMContentLoaded', patch);

  /* 3) تقرير افتتاحي + الصعوبة (في الصفحة الرئيسية فقط) */
  if (!/game_main\.html/.test(location.pathname)) return;
  document.addEventListener('DOMContentLoaded', function () {
    if (get('fcp_intro') || !get('presidentialClub')) return;
    var club = get('presidentialClub'), budget = parseFloat(get('clubBudget')) || 0;
    var d = 1, names = ['سهل', 'عادي', 'صعب'], mult = [1.3, 1, 0.7], desc = ['ميزانية أكبر بـ30٪', 'ميزانية قياسية', 'ميزانية أقل بـ30٪'];
    var ov = document.createElement('div');
    ov.style.cssText = 'position:fixed;inset:0;z-index:99999;background:rgba(0,0,0,.85);display:flex;align-items:center;justify-content:center;padding:16px;direction:rtl;font-family:inherit';
    function render() {
      ov.innerHTML = '<div style="background:#0f1620;color:#fff;border-radius:20px;padding:22px;max-width:420px;width:100%;border:1px solid #223">' +
        '<h2 style="margin:0 0 6px;text-align:center">📋 تقرير الإدارة — ' + club + '</h2>' +
        '<p style="color:#8593a6;text-align:center;margin:0 0 14px">وضعك قبل بداية المسيرة</p>' +
        '<div style="display:flex;justify-content:space-between;padding:6px 0"><span style="color:#8593a6">الميزانية</span><b style="color:#00e676">' + (budget * mult[d]).toFixed(1) + ' M€</b></div>' +
        '<div style="display:flex;justify-content:space-between;padding:6px 0"><span style="color:#8593a6">ثقة الإدارة</span><b>' + [75, 60, 45][d] + '٪</b></div>' +
        '<div style="margin:14px 0 6px;font-weight:700">مستوى الصعوبة</div><div style="display:flex;gap:8px">' +
        names.map(function (n, i) { return '<button data-d="' + i + '" style="flex:1;padding:10px;border-radius:12px;border:1px solid ' + (i === d ? '#00e676' : '#334') + ';background:' + (i === d ? '#00e67622' : 'transparent') + ';color:#fff;font:inherit">' + n + '</button>'; }).join('') +
        '</div><p style="color:#8593a6;font-size:12px">' + desc[d] + '</p>' +
        '<button id="fcpGo" style="width:100%;padding:14px;border-radius:14px;border:0;background:#00e676;color:#000;font:inherit;font-weight:800">ادخل إدارة النادي</button></div>';
      ov.querySelectorAll('button[data-d]').forEach(function (b) { b.onclick = function () { d = +b.dataset.d; render(); }; });
      ov.querySelector('#fcpGo').onclick = function () {
        set('clubBudget', String(budget * mult[d]));
        set('fcp_difficulty', String(d)); set('fcp_confidence', String([75, 60, 45][d]));
        set('fcp_intro', '1'); ov.remove(); location.reload();
      };
    }
    render(); document.body.appendChild(ov);
  });
})();
