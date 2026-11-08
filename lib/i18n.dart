import 'settings.dart';

/// ترجمة بسيطة: المفتاح هو النص العربي، والقيم [English, Français, Español].
/// الشاشات غير المترجمة تبقى بالعربية.
const _t = <String, List<String>>{
  'الرئيسية': ['Home', 'Accueil', 'Inicio'],
  'الفريق': ['Squad', 'Équipe', 'Plantilla'],
  'الانتقالات': ['Transfers', 'Transferts', 'Fichajes'],
  'المسابقات': ['Competitions', 'Compétitions', 'Competiciones'],
  'النادي': ['Club', 'Club', 'Club'],
  'لعبة جديدة': ['New game', 'Nouvelle partie', 'Nueva partida'],
  'الإعدادات': ['Settings', 'Paramètres', 'Ajustes'],
  'الحساب': ['Account', 'Compte', 'Cuenta'],
  'المباراة': ['Match', 'Match', 'Partido'],
  'العرض': ['Display', 'Affichage', 'Pantalla'],
  'اللعبة': ['Game', 'Jeu', 'Juego'],
  'حول': ['About', 'À propos', 'Acerca de'],
  'المظهر': ['Appearance', 'Apparence', 'Apariencia'],
  'اللغة': ['Language', 'Langue', 'Idioma'],
  'داكن': ['Dark', 'Sombre', 'Oscuro'],
  'فاتح': ['Light', 'Clair', 'Claro'],
  'تلقائي': ['System', 'Système', 'Sistema'],
  'حساب سحابي': ['Cloud account', 'Compte cloud', 'Cuenta en la nube'],
  'حساب محلي على هذا الجهاز': ['Local account on this device', 'Compte local sur cet appareil', 'Cuenta local en este dispositivo'],
  'تسجيل الخروج': ['Sign out', 'Se déconnecter', 'Cerrar sesión'],
  'ستُحفظ مسيرتك ثم تعود لشاشة الدخول.': ['Your career will be saved, then you return to sign-in.', 'Votre carrière sera sauvegardée puis retour à la connexion.', 'Tu carrera se guardará y volverás al inicio de sesión.'],
  'سرعة المباراة الافتراضية': ['Default match speed', 'Vitesse de match par défaut', 'Velocidad de partido por defecto'],
  'عادية': ['Normal', 'Normale', 'Normal'],
  'سريعة': ['Fast', 'Rapide', 'Rápida'],
  'أسرع': ['Faster', 'Plus rapide', 'Más rápida'],
  'لافتة الهدف على الملعب': ['Goal banner on pitch', 'Bannière de but sur le terrain', 'Cartel de gol en el campo'],
  'الاهتزاز عند الأهداف': ['Vibrate on goals', 'Vibrer sur les buts', 'Vibrar en los goles'],
  'حجم الخط': ['Text size', 'Taille du texte', 'Tamaño del texto'],
  'تُحفظ مسيرتك تلقائياً بعد كل مباراة وصفقة.': ['Your career auto-saves after every match and deal.', 'Votre carrière est sauvegardée après chaque match et transfert.', 'Tu carrera se guarda tras cada partido y fichaje.'],
  'حفظ الآن': ['Save now', 'Sauvegarder', 'Guardar ahora'],
  'حفظ وخروج للقائمة': ['Save & exit to menu', 'Sauvegarder et quitter', 'Guardar y salir'],
  'تم الحفظ ✅': ['Saved ✅', 'Sauvegardé ✅', 'Guardado ✅'],
  'استعادة النسخة الاحتياطية': ['Restore backup', 'Restaurer la sauvegarde', 'Restaurar copia'],
  'حذف المسيرة الحالية': ['Delete current career', 'Supprimer la carrière', 'Borrar la carrera'],
  'إلغاء': ['Cancel', 'Annuler', 'Cancelar'],
  'تأكيد': ['Confirm', 'Confirmer', 'Confirmar'],
  'لا توجد نسخة احتياطية بعد': ['No backup yet', 'Aucune sauvegarde', 'Aún no hay copia'],
  'تمت الاستعادة — اختر «متابعة المسيرة»': ['Restored — choose “Continue career”', 'Restauré — choisissez « Continuer »', 'Restaurado — elige «Continuar»'],
  'ستُستبدل مسيرتك الحالية بآخر نسخة احتياطية تلقائية (أقدم بقليل). تُحفظ هذه النسخة كل بضع جولات.': ['Your current career will be replaced by the last automatic backup (slightly older), saved every few rounds.', 'Votre carrière sera remplacée par la dernière sauvegarde automatique (un peu plus ancienne).', 'Tu carrera se reemplazará por la última copia automática (algo más antigua).'],
  'حذف المسيرة': ['Delete career', 'Supprimer la carrière', 'Borrar carrera'],
  'سيُحذف حفظ هذه المسيرة نهائياً ولا يمكن التراجع.': ['This career save will be permanently deleted.', 'Cette sauvegarde sera supprimée définitivement.', 'Esta partida se borrará permanentemente.'],
  'مدرب كرة القدم': ['Football Manager', 'Manager de football', 'Mánager de fútbol'],
  'أسماء الرعاة المعروضة في اللعبة لأغراض المحاكاة فقط ولا تمثّل أي ارتباط تجاري فعلي.': ['Sponsor names are for simulation only and imply no real commercial affiliation.', 'Les noms de sponsors sont fictifs, à des fins de simulation uniquement.', 'Los nombres de patrocinadores son solo de simulación.'],
  'الترجمة الحالية تشمل الإعدادات والتنقل الرئيسي؛ بقية الشاشات تُترجم تدريجياً.': ['Translation currently covers settings and main navigation; other screens are being translated gradually.', 'La traduction couvre pour l’instant les paramètres et la navigation.', 'La traducción cubre por ahora ajustes y navegación.'],
};

String tr(String ar) {
  final l = AppSettings.i.lang;
  if (l == 'ar') return ar;
  final v = _t[ar];
  if (v == null) return ar;
  return v[l == 'en' ? 0 : l == 'fr' ? 1 : 2];
}
