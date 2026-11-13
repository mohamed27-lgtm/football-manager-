import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'auth.dart';
import 'widgets.dart';

/// شاشة الدخول الإلزامية: تسجيل دخول / إنشاء حساب
class AuthScreen extends StatefulWidget {
  final void Function(Account) onAuthed;
  const AuthScreen({super.key, required this.onAuthed});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool signup = false;
  bool busy = false;
  bool hide = true;
  String? error, info;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
      info = null;
    });
    try {
      final a = signup
          ? await AuthService.signUp(_name.text, _email.text, _pass.text)
          : await AuthService.signIn(_email.text, _pass.text);
      if (mounted) widget.onAuthed(a);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = 'حدث خطأ غير متوقع');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _forgot() async {
    setState(() {
      error = null;
      info = null;
    });
    try {
      final m = await AuthService.resetPassword(_email.text);
      if (mounted) setState(() => info = m);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Unfilter(
        child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/brand/coach_scene.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1B1F3B))),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x33000000), Color(0xF20E1624)], stops: [0.2, 0.62]),
            ),
          ),
          SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 40),
                  const Text('مدرب كرة القدم', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 12, color: Colors.black54)])),
                  Text(signup ? 'أنشئ حسابك وابدأ مسيرتك' : 'أهلاً بعودتك أيها المدرب', style: const TextStyle(color: Color(0xFFFFD9A8), fontSize: 14)),
                  const SizedBox(height: 190),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('تسجيل الدخول')),
                      ButtonSegment(value: true, label: Text('حساب جديد')),
                    ],
                    selected: {signup},
                    onSelectionChanged: busy
                        ? null
                        : (s) => setState(() {
                              signup = s.first;
                              error = null;
                              info = null;
                            }),
                  ),
                  const SizedBox(height: 18),
                  if (signup) ...[
                    TextField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                          labelText: tr('اسم المدرب'), prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        labelText: tr('البريد الإلكتروني'), prefixIcon: Icon(Icons.mail_outline), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: hide,
                    textDirection: TextDirection.ltr,
                    onSubmitted: (_) => busy ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: tr('كلمة المرور'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => hide = !hide),
                      ),
                    ),
                  ),
                  if (!signup)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(onPressed: busy ? null : _forgot, child: const Text('نسيت كلمة المرور؟')),
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF8A65))),
                    ),
                  if (info != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(info!, textAlign: TextAlign.center, style: const TextStyle(color: kAccent)),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Text(signup ? 'إنشاء الحساب' : 'دخول', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!AuthService.remote)
                    const Text(
                      'الحسابات محفوظة على هذا الجهاز فقط (لم يُربط خادم الحسابات بعد).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kMuted, fontSize: 11),
                    ),
                ]),
              ),
            ),
          ),
        ),
        ]),
      ),
    );
  }
}
