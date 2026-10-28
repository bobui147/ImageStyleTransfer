import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:login_api_bonus/auth_api.dart';

void main() {
  test('Security Mindset sends the page login payload', () async {
    late http.Request sent;
    final api = AuthApi(
      client: MockClient((request) async {
        sent = request;
        return http.Response('{"status":true}', 200);
      }),
    );

    final result = await api.loginSecurityMindset(
      username: 'admin',
      password: 'example',
      captcha: '42',
    );

    expect(result.site, LoginSite.securityMindset);
    expect(
      sent.url.toString(),
      'https://securitymindset.ongbantat.io.vn/api/auth/login',
    );
    expect(sent.method, 'POST');
    expect(jsonDecode(sent.body), {
      'username': 'admin',
      'password': 'example',
      'captcha': '42',
    });
    api.close();
  });

  test('Ong Ban Tat obtains a captcha and sends id|answer', () async {
    final sent = <http.Request>[];
    final api = AuthApi(
      client: MockClient((request) async {
        sent.add(request);
        if (request.url.path.endsWith('create-captcha')) {
          return http.Response('{"id":110925,"data":"<svg></svg>"}', 200);
        }
        return http.Response('{"token":"test-token","user":{}}', 200);
      }),
    );

    final captcha = await api.createOngCaptcha();
    final result = await api.loginOngBanTat(
      account: 'example-user',
      password: 'example',
      captchaId: captcha.id,
      captchaText: '1234',
    );

    expect(result.site, LoginSite.ongBanTat);
    expect(
      sent[0].url.toString(),
      'https://backend.ongbantat.io.vn/api/auth/create-captcha',
    );
    expect(
      sent[1].url.toString(),
      'https://backend.ongbantat.io.vn/api/auth/sign-in/account',
    );
    expect(sent[1].headers['api-version'], 'public');
    expect(sent[1].headers['authorization'], 'customer');
    expect(jsonDecode(sent[1].body)['captcha'], '110925|1234');
    api.close();
  });

  test('Ong Ban Tat displays backend errors', () async {
    final api = AuthApi(
      client: MockClient(
        (_) async => http.Response('{"message":"Invalid captcha!"}', 400),
      ),
    );
    await expectLater(
      api.loginOngBanTat(
        account: 'x',
        password: 'x',
        captchaId: '1',
        captchaText: 'wrong',
      ),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Invalid captcha!',
        ),
      ),
    );
    api.close();
  });
}
