import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/on_device_api_keys.dart';
import 'package:music_director/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ApiPaths match FastAPI routes', () {
    expect(ApiPaths.analyze, '/analyze');
    expect(ApiPaths.generatePrompt, '/generate-prompt');
  });

  test('normalizeApiBaseUrl strips trailing slash', () {
    expect(normalizeApiBaseUrl('http://10.0.2.2:8080/'), 'http://10.0.2.2:8080');
  });

  test('normalizeApiBaseUrl strips pasted endpoint paths', () {
    expect(
      normalizeApiBaseUrl('http://127.0.0.1:8080/generate-prompt'),
      'http://127.0.0.1:8080',
    );
  });

  test('normalizeApiBaseUrl fixes https on LAN to http', () {
    expect(
      normalizeApiBaseUrl('https://192.168.5.42:8080'),
      'http://192.168.5.42:8080',
    );
    expect(
      normalizeApiBaseUrl('https://192.168.1.7:8080'),
      'http://192.168.1.7:8080',
    );
    expect(
      normalizeApiBaseUrl('192.168.1.7:8080'),
      'http://192.168.1.7:8080',
    );
  });

  test('validateMusicDirectorApiBaseUrl warns router .1 address', () {
    expect(
      validateMusicDirectorApiBaseUrl('http://192.168.5.1:8080'),
      contains('router'),
    );
  });

  test('validateMusicDirectorApiBaseUrl rejects LLM provider URLs', () {
    expect(
      validateMusicDirectorApiBaseUrl('https://api.laozhang.ai/v1'),
      isNotNull,
    );
    expect(validateMusicDirectorApiBaseUrl('http://127.0.0.1:8080'), isNull);
  });

  test('createMusicDirectorApiDio sets baseUrl for relative paths', () {
    final dio = createMusicDirectorApiDio('http://127.0.0.1:8080/');
    expect(dio.options.baseUrl, 'http://127.0.0.1:8080');
  });

  test('OnDeviceApiKeys uses selected provider', () async {
    SharedPreferences.setMockInitialValues({
      OnDeviceApiKeys.prefLaozhang: 'lz-key',
      OnDeviceApiKeys.prefOpenRouter: 'sk-or-v1-test',
      OnDeviceApiKeys.prefProvider: 'openrouter',
    });
    final prefs = await SharedPreferences.getInstance();
    final active = OnDeviceApiKeys.resolveActive(prefs);
    expect(active.useOpenRouter, isTrue);
    expect(active.apiKey, 'sk-or-v1-test');
  });
}
