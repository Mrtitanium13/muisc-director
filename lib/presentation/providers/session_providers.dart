import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionPrefs {
  SessionPrefs(this._p);

  final SharedPreferences _p;

  static const _onboarding = 'md_onboarding_done';
  static const _guest = 'md_guest_mode';

  bool get onboardingDone => _p.getBool(_onboarding) ?? false;

  Future<void> setOnboardingDone() => _p.setBool(_onboarding, true);

  bool get guestMode => _p.getBool(_guest) ?? false;

  Future<void> setGuestMode(bool v) => _p.setBool(_guest, v);

  Future<void> signOut() => _p.setBool(_guest, false);
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPrefsProvider in main.dart');
});

final sessionPrefsProvider = Provider<SessionPrefs>((ref) {
  return SessionPrefs(ref.watch(sharedPrefsProvider));
});
