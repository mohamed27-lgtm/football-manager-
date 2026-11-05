/* نظام التهيئة المركزي (بديل مبسّط): يفتح قاعدة IndexedDB إن وُجدت ويضبط اللغة والاتجاه */
(function () {
  try {
    var lang = localStorage.getItem('gameLanguage') || 'ar';
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
  } catch (e) {}
  try {
    if (typeof DB !== 'undefined' && DB && typeof DB.init === 'function') DB.init().catch(function () {});
  } catch (e) {}
})();
