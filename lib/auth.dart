import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class Account {
  final String email, name;
  const Account(this.email, this.name);
}

/// تسجيل الدخول: عبر Supabase إن ضُبط (SUPABASE_URL / SUPABASE_ANON_KEY)،
/// وإلا حسابات محلية على الجهاز.
class AuthService {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anon = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get remote => _url.isNotEmpty && _anon.isNotEmpty;

  static const _kSession = 'auth_session';
  static const _kLocal = 'auth_local_accounts';

  static String slotFor(String email) =>
      '_${sha256.convert(utf8.encode(email.toLowerCase())).toString().substring(0, 12)}';

  static Future<Account?> current() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kSession);
    if (s == null) return null;
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      return Account(j['email'] as String, j['name'] as String);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _store(Account a) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSession, jsonEncode({'email': a.email, 'name': a.name}));
  }

  static Future<void> signOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSession);
  }

  static bool validEmail(String e) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);

  static Future<Account> signUp(String name, String email, String password) async {
    email = email.trim().toLowerCase();
    name = name.trim();
    if (name.length < 2) throw AuthException('اكتب اسمك (حرفان على الأقل)');
    if (!validEmail(email)) throw AuthException('البريد الإلكتروني غير صالح');
    if (password.length < 6) throw AuthException('كلمة المرور 6 أحرف على الأقل');
    final Account acc;
    if (remote) {
      final r = await _post('/auth/v1/signup', {
        'email': email,
        'password': password,
        'data': {'name': name},
      });
      if (r['access_token'] == null) {
        throw AuthException('تم إنشاء الحساب. أكّد بريدك الإلكتروني من الرسالة المرسلة إليك ثم سجّل الدخول.');
      }
      acc = Account(email, name);
    } else {
      final p = await SharedPreferences.getInstance();
      final all = _accounts(p);
      if (all.containsKey(email)) throw AuthException('هذا البريد مسجّل مسبقاً');
      final salt = _salt();
      all[email] = {'name': name, 'salt': salt, 'hash': _hash(password, salt)};
      await p.setString(_kLocal, jsonEncode(all));
      acc = Account(email, name);
    }
    await _store(acc);
    return acc;
  }

  static Future<Account> signIn(String email, String password) async {
    email = email.trim().toLowerCase();
    if (!validEmail(email)) throw AuthException('البريد الإلكتروني غير صالح');
    if (password.isEmpty) throw AuthException('أدخل كلمة المرور');
    final Account acc;
    if (remote) {
      final r = await _post('/auth/v1/token?grant_type=password', {'email': email, 'password': password});
      final meta = (r['user']?['user_metadata'] as Map?) ?? const {};
      acc = Account(email, (meta['name'] as String?) ?? email.split('@').first);
    } else {
      final p = await SharedPreferences.getInstance();
      final a = _accounts(p)[email];
      if (a == null || _hash(password, a['salt'] as String) != a['hash']) {
        throw AuthException('البريد أو كلمة المرور غير صحيحة');
      }
      acc = Account(email, a['name'] as String);
    }
    await _store(acc);
    return acc;
  }

  static Future<String> resetPassword(String email) async {
    email = email.trim().toLowerCase();
    if (!validEmail(email)) throw AuthException('اكتب بريدك الإلكتروني أولاً');
    if (!remote) {
      throw AuthException('استعادة كلمة المرور تتطلب ربط خادم الحسابات. أنشئ حساباً جديداً ببريد آخر.');
    }
    await _post('/auth/v1/recover', {'email': email});
    return 'أرسلنا رابط الاستعادة إلى بريدك';
  }

  // ───────── داخلي ─────────
  static Map<String, dynamic> _accounts(SharedPreferences p) {
    final s = p.getString(_kLocal);
    return s == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(s) as Map);
  }

  static String _salt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(12, (_) => r.nextInt(256)));
  }

  static String _hash(String pw, String salt) => sha256.convert(utf8.encode('$salt:$pw')).toString();

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final http.Response r;
    try {
      r = await http
          .post(Uri.parse('$_url$path'),
              headers: {'apikey': _anon, 'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw AuthException('تعذّر الاتصال بالإنترنت');
    }
    final j = r.body.isEmpty ? <String, dynamic>{} : (jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
    if (r.statusCode >= 400) {
      final m = ((j['msg'] ?? j['error_description'] ?? j['message'] ?? '') as String).toLowerCase();
      if (m.contains('invalid login')) throw AuthException('البريد أو كلمة المرور غير صحيحة');
      if (m.contains('already')) throw AuthException('هذا البريد مسجّل مسبقاً');
      if (m.contains('not confirmed')) throw AuthException('أكّد بريدك الإلكتروني أولاً من الرسالة المرسلة إليك');
      if (m.contains('rate') || r.statusCode == 429) throw AuthException('محاولات كثيرة، انتظر قليلاً');
      throw AuthException('فشل الطلب (${r.statusCode})');
    }
    return j;
  }
}
