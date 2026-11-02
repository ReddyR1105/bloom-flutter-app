import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:bloom/data/settings_store.dart';
import 'package:bloom/integration/bloom_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingPreferences extends InMemorySharedPreferencesStore {
  FailingPreferences() : super.withData({});
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('valid defaults and persisted settings reload', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SettingsStore(prefs);
    expect(store.load().defaultTarget, 20);
    expect(store.load().weekStartsMonday, true);
    expect(store.load().reducedMotion, false);
    await store.save(
      const SettingsView(
        defaultTarget: 42,
        weekStartsMonday: false,
        reducedMotion: true,
      ),
    );
    await prefs.reload();
    final restored = SettingsStore(prefs).load();
    expect(restored.defaultTarget, 42);
    expect(restored.weekStartsMonday, false);
    expect(restored.reducedMotion, true);
    for (final value in [0, -1, 100001]) {
      await expectLater(
        store.save(SettingsView(defaultTarget: value)),
        throwsArgumentError,
      );
    }
    expect(store.load().defaultTarget, 42);
  });
  test('failed platform write is reported and cached value restored', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = FailingPreferences();
    final prefs = await SharedPreferences.getInstance();
    final store = SettingsStore(prefs);
    await expectLater(
      store.save(const SettingsView(defaultTarget: 40)),
      throwsStateError,
    );
    expect(store.load().defaultTarget, 20);
  });
  test('corrupt settings reported, explicit valid save repairs them', () async {
    for (final value in [
      123,
      'not json',
      '{}',
      '{"defaultTarget":0,"weekStartsMonday":true,"reducedMotion":false}',
    ]) {
      SharedPreferences.setMockInitialValues({SettingsStore.key: value});
      final store = SettingsStore(await SharedPreferences.getInstance());
      expect(store.load, throwsStateError);
      await store.save(const SettingsView());
      expect(store.load().defaultTarget, 20);
    }
  });
}
