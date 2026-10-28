import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'auth_api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.api});

  final AuthApi? api;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _captcha = TextEditingController();
  final _random = Random();
  late final AuthApi _api = widget.api ?? AuthApi();

  LoginSite _site = LoginSite.securityMindset;
  CaptchaChallenge? _ongCaptcha;
  LoginResult? _result;
  String? _error;
  String _mathQuestion = '';
  int _mathAnswer = 0;
  int _captchaRequest = 0;
  bool _loadingCaptcha = false;
  bool _submitting = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _newMathCaptcha();
  }

  @override
  void dispose() {
    _captchaRequest++;
    _username.dispose();
    _password.dispose();
    _captcha.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }

  void _newMathCaptcha() {
    final a = 10 + _random.nextInt(90);
    final b = 1 + _random.nextInt(9);
    final add = _random.nextBool();
    _mathAnswer = add ? a + b : a - b;
    _mathQuestion = '$a ${add ? '+' : '-'} $b = ?';
    _captcha.clear();
  }

  void _selectSite(LoginSite site) {
    if (_site == site || _submitting) return;
    _captchaRequest++;
    setState(() {
      _site = site;
      _error = null;
      _result = null;
      _ongCaptcha = null;
      _loadingCaptcha = false;
      _username.clear();
      _password.clear();
      _captcha.clear();
      if (site == LoginSite.securityMindset) _newMathCaptcha();
    });
    _formKey.currentState?.reset();
    if (site == LoginSite.ongBanTat) _loadOngCaptcha();
  }

  Future<void> _loadOngCaptcha({bool preserveError = false}) async {
    final request = ++_captchaRequest;
    setState(() {
      _loadingCaptcha = true;
      _ongCaptcha = null;
      _captcha.clear();
      if (!preserveError) _error = null;
    });
    try {
      final challenge = await _api.createOngCaptcha();
      if (!mounted || request != _captchaRequest) return;
      setState(() => _ongCaptcha = challenge);
    } on AuthException catch (e) {
      if (!mounted || request != _captchaRequest) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted && request == _captchaRequest) {
        setState(() => _loadingCaptcha = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_site == LoginSite.securityMindset &&
        _captcha.text.trim() != _mathAnswer.toString()) {
      setState(() {
        _error = 'Captcha không đúng. Hãy nhập kết quả mới.';
        _newMathCaptcha();
      });
      return;
    }
    if (_site == LoginSite.ongBanTat && _ongCaptcha == null) {
      setState(() => _error = 'Vui lòng tải captcha trước khi đăng nhập.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = _site == LoginSite.securityMindset
          ? await _api.loginSecurityMindset(
              username: _username.text.trim(),
              password: _password.text,
              captcha: _captcha.text.trim(),
            )
          : await _api.loginOngBanTat(
              account: _username.text.trim(),
              password: _password.text,
              captchaId: _ongCaptcha!.id,
              captchaText: _captcha.text.trim(),
            );
      if (!mounted) return;
      setState(() {
        _result = result;
        _password.clear();
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        if (_site == LoginSite.securityMindset) _newMathCaptcha();
      });
      if (_site == LoginSite.ongBanTat) {
        await _loadOngCaptcha(preserveError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOng = _site == LoginSite.ongBanTat;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 3,
                shadowColor: Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 44,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Đăng nhập',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chọn hệ thống cần kiểm tra',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Bonus 3.1 · Security Mindset'),
                            selected: !isOng,
                            onSelected: (_) =>
                                _selectSite(LoginSite.securityMindset),
                          ),
                          ChoiceChip(
                            label: const Text('Bonus 3.2 · Ông Bán Tất'),
                            selected: isOng,
                            onSelected: (_) => _selectSite(LoginSite.ongBanTat),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isOng
                            ? 'ongbantat.io.vn'
                            : 'securitymindset.ongbantat.io.vn',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      if (_result != null)
                        _successCard(context)
                      else
                        _loginForm(context, isOng),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _successCard(BuildContext context) => Column(
    children: [
      const Icon(Icons.check_circle, size: 64, color: Colors.green),
      const SizedBox(height: 12),
      Text(
        'Đăng nhập thành công',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      Text('Tài khoản: ${_result!.username}'),
      const SizedBox(height: 20),
      OutlinedButton(
        onPressed: () {
          setState(() {
            _result = null;
            _error = null;
            _captcha.clear();
            if (_site == LoginSite.securityMindset) _newMathCaptcha();
          });
          if (_site == LoginSite.ongBanTat) _loadOngCaptcha();
        },
        child: const Text('Đăng nhập lại'),
      ),
    ],
  );

  Widget _loginForm(BuildContext context, bool isOng) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _username,
          decoration: const InputDecoration(
            labelText: 'Tên đăng nhập',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Nhập tên đăng nhập'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _password,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.password],
          validator: (value) =>
              value == null || value.isEmpty ? 'Nhập mật khẩu' : null,
        ),
        const SizedBox(height: 22),
        Text('Captcha', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isOng
                    ? _loadingCaptcha
                          ? const CircularProgressIndicator()
                          : _ongCaptcha == null
                          ? const Text('Chưa tải captcha')
                          : SvgPicture.string(
                              _ongCaptcha!.svg,
                              width: 180,
                              height: 60,
                            )
                    : Text(
                        _mathQuestion,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
              ),
            ),
            IconButton(
              tooltip: 'Đổi captcha',
              onPressed: _submitting || _loadingCaptcha
                  ? null
                  : isOng
                  ? _loadOngCaptcha
                  : () => setState(() => _newMathCaptcha()),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _captcha,
          decoration: InputDecoration(
            labelText: isOng
                ? 'Nhập ký tự trong ảnh'
                : 'Nhập kết quả phép tính',
            prefixIcon: const Icon(Icons.verified_user_outlined),
          ),
          textInputAction: TextInputAction.done,
          keyboardType: isOng ? TextInputType.text : TextInputType.number,
          onFieldSubmitted: (_) => _submit(),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Nhập captcha' : null,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _submitting || _loadingCaptcha ? null : _submit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Đăng nhập'),
          ),
        ),
      ],
    ),
  );
}
