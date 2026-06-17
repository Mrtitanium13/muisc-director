import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/api_connectivity.dart';

void main() {
  // Flutter tests default to Android; loopback guard is for real phones only.
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('runMusicDirectorConnectionTest rejects LaoZhang URL', () async {
    expect(
      () => runMusicDirectorConnectionTest('https://api.laozhang.ai/v1'),
      throwsA(isA<ApiConnectivityException>()),
    );
  });

  test('runMusicDirectorConnectionTest succeeds against mock /health', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    server.listen((request) async {
      final path = request.uri.path;
      if (path == '/health') {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'status': 'ok'}));
      } else if (path == '/generate-prompt' && request.method == 'POST') {
        request.response
          ..statusCode = 503
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'detail': 'OPENAI_API_KEY not configured'}));
      } else {
        request.response
          ..statusCode = 404
          ..write(jsonEncode({'detail': 'Not Found'}));
      }
      await request.response.close();
    });

    final port = server.port;
    final result = await runMusicDirectorConnectionTest(
      'http://127.0.0.1:$port',
    );

    expect(result.healthStatus, 'ok');
    expect(result.resolvedBaseUrl, 'http://127.0.0.1:$port');
    expect(result.generateRouteOk, isFalse);
    expect(result.successMessage, contains('Connected'));
  });

  test('runMusicDirectorConnectionTest fails when /health is 404', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    server.listen((request) async {
      request.response
        ..statusCode = 404
        ..write(jsonEncode({'detail': 'Not Found'}));
      await request.response.close();
    });

    final port = server.port;
    expect(
      () => runMusicDirectorConnectionTest('http://127.0.0.1:$port'),
      throwsA(
        predicate<ApiConnectivityException>(
          (e) => e.message.contains('404') || e.message.contains('Cannot reach'),
        ),
      ),
    );
  });

  test(
    'live server when MD_TEST_SERVER is set (manual: set env to http://127.0.0.1:8080)',
    () async {
      final url = Platform.environment['MD_TEST_SERVER']?.trim();
      if (url == null || url.isEmpty) return;
      final result = await runMusicDirectorConnectionTest(url);
      expect(result.healthStatus, 'ok');
      expect(result.successMessage, contains('Connected'));
    },
    skip: Platform.environment['MD_TEST_SERVER']?.trim().isEmpty ?? true,
  );
}
