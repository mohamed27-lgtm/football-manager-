import 'package:flutter/material.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B2A1A), kBg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kCard,
                      border: Border.all(color: kAccent, width: 2),
                    ),
                    child: const Center(child: Text('⚽', style: TextStyle(fontSize: 42))),
                  ),
                  const SizedBox(height: 14),
                  const Text('مدرب كرة القدم', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(signup ? 'أنشئ حسابك وابدأ مسيرتك' : 'أهلاً بعودتك أيها المدرب',
                      style: const TextStyle(color: kMuted)),
                  const SizedBox(height: 24),
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
                      decoration: const InputDecoration(
                          labelText: 'اسم المدرب', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.mail_outline), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: hide,
                    textDirection: TextDirection.ltr,
                    onSubmitted: (_) => busy ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
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
      ),
    );
  }
}
