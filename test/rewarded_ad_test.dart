import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/services/ad_service.dart';

void main() {
  // 순수 test()만 있는 파일은 바인딩이 자동으로 안 켜져서 직접 켠다.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 실제 광고 SDK 호출을 테스트용 채널 응답으로 대신한다.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/google_mobile_ads'),
      (call) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/google_mobile_ads'),
      null,
    );
  });

  test('디버그 빌드에서는 보상형 광고 Google 공식 테스트 ID를 쓴다', () {
    expect(AdService.rewardedAdUnitId,
        'ca-app-pub-3940256099942544/5224354917');
  });

  test('로드된 광고가 없으면 showRewardedAd는 unavailable을 반환한다', () async {
    expect(await AdService.showRewardedAd(), RewardedAdResult.unavailable);
  });
}
