import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/services/adfree_service.dart';

void main() {
  tearDown(() {
    AdFreeService.instance.resetForTest();
  });

  test('기본값은 광고 제거 아님', () async {
    SharedPreferences.setMockInitialValues({});
    await AdFreeService.instance.ensureLoaded();
    expect(AdFreeService.instance.isAdFree, isFalse);
  });

  test('플래그가 저장돼 있으면 읽어서 true가 된다', () async {
    SharedPreferences.setMockInitialValues({AdFreeService.prefsKey: true});
    await AdFreeService.instance.ensureLoaded();
    expect(AdFreeService.instance.isAdFree, isTrue);
  });

  test('setAdFree(true)를 하면 플래그가 저장되고 notifier가 알린다', () async {
    SharedPreferences.setMockInitialValues({});
    await AdFreeService.instance.ensureLoaded();
    var notified = false;
    void listener() {
      notified = true;
    }

    AdFreeService.instance.isAdFreeNotifier.addListener(listener);
    await AdFreeService.instance.setAdFree(true);
    AdFreeService.instance.isAdFreeNotifier.removeListener(listener);

    expect(AdFreeService.instance.isAdFree, isTrue);
    expect(notified, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AdFreeService.prefsKey), isTrue);
  });
}
