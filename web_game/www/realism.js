/* realism.js — محرّك الواقعية المشترك:
   - تقييمات FC26 الحقيقية للاعبين (fc_ratings.json)
   - قوة الأندية من أفضل 14 لاعباً (club_strength.json)
   - نتائج مباريات الأندية الأخرى بنموذج بواسون حتمي (نفس النتيجة دائماً لنفس المباراة)
   - هدافو وصنّاع أهداف حقيقيون من تشكيلات الأندية (club_players.json) */
(function () {
  function loadJSON(u) {
    try { var x = new XMLHttpRequest(); x.open('GET', u, false); x.send(); if (x.status === 200 || x.status === 0) return JSON.parse(x.responseText); } catch (e) {}
    return {};
  }
  var cache = {};
  function lazy(name, file) { if (!cache[name]) cache[name] = loadJSON(file); return cache[name]; }
  function hash(s) { var h = 2166136261 >>> 0; s = String(s); for (var i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0; } return h >>> 0; }
  function rng(seed) { var a = seed >>> 0; return function () { a = (a + 0x6D2B79F5) >>> 0; var t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  function poisson(lambda, r) { var L = Math.exp(-lambda), k = 0, p = 1; do { k++; p *= r(); } while (p > L && k < 12); return k - 1; }
  function seasonKey() {
    var m = parseInt(localStorage.getItem('game_month')) || 9, y = parseInt(localStorage.getItem('game_year')) || 2026;
    return (m >= 8 ? y : y - 1);
  }
  var AVG = 60;
  var R = {
    ratings: function () { return lazy('fc', 'fc_ratings.json'); },
    strengths: function () { return lazy('st', 'club_strength.json'); },
    clubPlayers: function () { return lazy('cp', 'club_players.json'); },
    /* تقييم لاعب: FC26 إن وُجد وإلا تقدير من القيمة السوقية */
    rating: function (tmid, marketValue) {
      var r = R.ratings()[String(tmid)];
      if (r) return r[0];
      return Math.min(99, Math.max(45, Math.round(50 + Math.log10(Math.max(marketValue || 0, 50000) / 50000) * 11)));
    },
    potential: function (tmid) { var r = R.ratings()[String(tmid)]; return r ? r[1] : null; },
    strength: function (club) {
      var s = R.strengths()[club];
      if (s) return s;
      // أندية بلا بيانات لاعبين: متوسط الدوري تقريباً
      return AVG + (hash(club) % 9) - 4;
    },
    /* نتيجة حتمية واقعية لمباراة بين فريقين خارج مسيرتك */
    sim: function (round, home, away) {
      var r = rng(hash(seasonKey() + '|' + round + '|' + home + '|' + away));
      var d = (R.strength(home) - R.strength(away)) + 2.2;   // أفضلية الملعب
      var lh = Math.max(0.25, Math.min(3.6, 1.38 * Math.exp(0.05 * d)));
      var la = Math.max(0.2, Math.min(3.2, 1.12 * Math.exp(-0.05 * d)));
      return [poisson(lh, r), poisson(la, r)];
    },
    /* فترات الانتقالات: الصيفية 1 يوليو – 1 سبتمبر، الشتوية يناير */
    windowInfo: function () {
      var m = parseInt(localStorage.getItem('game_month')) || 9, d = parseInt(localStorage.getItem('game_day')) || 1;
      if (m === 7 || m === 8 || (m === 9 && d <= 1)) return { open: true, label: 'الفترة الصيفية مفتوحة حتى 1 سبتمبر' };
      if (m === 1) return { open: true, label: 'الفترة الشتوية مفتوحة طوال يناير' };
      var next = (m >= 2 && m <= 6) ? 'الفترة الصيفية تبدأ 1 يوليو' : 'الفترة الشتوية تبدأ 1 يناير';
      return { open: false, label: 'سوق الانتقالات مغلق — ' + next };
    },
    windowOpen: function () { return R.windowInfo().open; },
    /* مشترٍ حقيقي: ناد يحتاج لاعباً بهذا المستوى (قوة النادي قريبة من تقييم اللاعب) */
    pickBuyer: function (rating, seedStr, exclude) {
      var st = R.strengths(), names = Object.keys(st), c = [];
      for (var i = 0; i < names.length; i++) {
        var s = st[names[i]];
        if (names[i] !== exclude && s >= rating - 9 && s <= rating + 1) c.push(names[i]);
      }
      if (!c.length) for (var j = 0; j < names.length; j++) if (names[j] !== exclude && st[names[j]] <= rating + 4) c.push(names[j]);
      if (!c.length) return 'نادٍ أجنبي';
      c.sort();
      return c[hash(seedStr) % c.length];
    },
    /* توزيع أهداف الفريق/تمريراته على لاعبيه الحقيقيين */
    playerStats: function (club, teamGoals, kind) {
      var list = R.clubPlayers()[club];
      if (!list || !list.length) return [];
      var W = kind === 'A'
        ? { ST: 1.0, CF: 1.0, SS: 1.2, LW: 1.7, RW: 1.7, CAM: 2.0, AM: 2.0, LM: 1.4, RM: 1.4, CM: 1.2, DM: .6, CDM: .6, LB: .7, RB: .7, CB: .2, GK: .02 }
        : { ST: 6, CF: 6, SS: 5, LW: 3.6, RW: 3.6, CAM: 3, AM: 3, LM: 1.8, RM: 1.8, CM: 1.2, DM: .5, CDM: .5, LB: .6, RB: .6, CB: .5, GK: .01 };
      var total = (kind === 'A' ? 0.72 : 1) * teamGoals;
      var ws = list.map(function (p) {
        var rr = rng(hash(club + p[0] + kind));
        return Math.pow(Math.max(p[2] - 48, 1), 2) * (W[p[1]] !== undefined ? W[p[1]] : 1) * (0.6 + rr() * 0.8);
      });
      var sum = ws.reduce(function (a, b) { return a + b; }, 0) || 1;
      return list.map(function (p, i) { return { name: p[0], team: club, value: Math.round(total * ws[i] / sum) }; });
    }
  };
  window.RLM = R;
})();
