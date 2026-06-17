import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/api_base_url_resolver.dart';

void main() {
  test('resolveDeviceApiBaseUrl does not rewrite loopback on Android by default', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(
      resolveDeviceApiBaseUrl('http://127.0.0.1:8080'),
      'http://127.0.0.1:8080',
    );
  });

  test('resolveDeviceApiBaseUrl rewrites loopback on Android when MD_ANDROID_EMULATOR=true', () async {
    await dotenv.load(fileName: '.env', mergeWith: {'MD_ANDROID_EMULATOR': 'true'});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(
      resolveDeviceApiBaseUrl('http://127.0.0.1:8080'),
      'http://10.0.2.2:8080',
    );
  });

  test('resolveDeviceApiBaseUrl leaves Railway URLs unchanged', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    const url = 'https://my-app.up.railway.app';
    expect(resolveDeviceApiBaseUrl(url), url);
  });

  test('resolveDeviceApiBaseUrl leaves loopback on desktop', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    const url = 'http://127.0.0.1:8080';
    expect(resolveDeviceApiBaseUrl(url), url);
  });
}
