import 'dart:convert';

import 'package:http/http.dart' as http;

enum LoginSite { securityMindset, ongBanTat }

class CaptchaChallenge {
  const CaptchaChallenge({required this.id, required this.svg});

  final String id;
  final String svg;
}

class LoginResult {
  const LoginResult({required this.username, required this.site});

  final String username;
  final LoginSite site;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Calls the same endpoints and sends the same JSON fields as the two web pages.
class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 20);
  static final _securityBase = Uri.parse(
    'https://securitymindset.ongbantat.io.vn',
  );
  static final _ongBase = Uri.parse('https://backend.ongbantat.io.vn');

  void close() => _client.close();

  Future<LoginResult> loginSecurityMindset({
    required String username,
    required String password,
    required String captcha,
  }) async {
    final response = await _post(
      _securityBase.resolve('/api/auth/login'),
      {'username': username, 'password': password, 'captcha': captcha},
      const {'Content-Type': 'application/json'},
    );
    final json = _decode(response);
    if (response.statusCode == 200 && json['status'] == true) {
      return LoginResult(username: username, site: LoginSite.securityMindset);
    }
    throw AuthException(_message(json, 'Đăng nhập thất bại.'));
  }

  Future<CaptchaChallenge> createOngCaptcha() async {
    final response = await _post(
      _ongBase.resolve('/api/auth/create-captcha'),
      const {},
      _ongHeaders,
    );
    final json = _decode(response);
    if (response.statusCode != 200 ||
        json['id'] == null ||
        json['data'] is! String) {
      throw AuthException(_message(json, 'Không tải được captcha.'));
    }
    return CaptchaChallenge(
      id: json['id'].toString(),
      svg: json['data'] as String,
    );
  }

  Future<LoginResult> loginOngBanTat({
    required String account,
    required String password,
    required String captchaId,
    required String captchaText,
  }) async {
    final response = await _post(
      _ongBase.resolve('/api/auth/sign-in/account'),
      {
        'account': account,
        'password': password,
        'captcha': '$captchaId|$captchaText',
      },
      _ongHeaders,
    );
    final json = _decode(response);
    if (response.statusCode == 200 &&
        json['token'] is String &&
        (json['token'] as String).isNotEmpty) {
      // This assignment only needs sign-in; keep the returned token out of storage.
      return LoginResult(username: account, site: LoginSite.ongBanTat);
    }
    throw AuthException(_message(json, 'Đăng nhập thất bại.'));
  }

  static const _ongHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
    'api-version': 'public',
    'Authorization': 'customer',
  };

  Future<http.Response> _post(
    Uri url,
    Map<String, Object> data,
    Map<String, String> headers,
  ) async {
    try {
      return await _client
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(_timeout);
    } on Exception {
      throw const AuthException(
        'Không kết nối được máy chủ. Vui lòng thử lại.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // The backend can return an HTML error page; keep it out of the UI.
    }
    throw AuthException(
      'Máy chủ trả dữ liệu không hợp lệ (HTTP ${response.statusCode}).',
    );
  }

  String _message(Map<String, dynamic> json, String fallback) {
    final value = json['message'] ?? json['error'];
    return value is String && value.trim().isNotEmpty ? value : fallback;
  }
}
