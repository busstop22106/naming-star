import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/services/ad_service.dart';
import 'package:jakmyeongbyeol/services/interstitial_gate.dart';

void main() {
  setUp(() {
    // 실제 광고 SDK 호출을 테스트용 채널 응답으로 대신한다.
    // (광고 차례에서 AdService가 다음 광고 로드를 fire-and-forget으로 걸 때
    // MissingPluginException이 나지 않게 한다.)
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

  group('InterstitialGate.isAdTurn', () {
    test('4의 배수면 광고 차례', () {
      expect(InterstitialGate.isAdTurn(4), isTrue);
      expect(InterstitialGate.isAdTurn(8), isTrue);
    });

    test('4의 배수가 아니면 애니메이션 차례', () {
      expect(InterstitialGate.isAdTurn(1), isFalse);
      expect(InterstitialGate.isAdTurn(3), isFalse);
      expect(InterstitialGate.isAdTurn(5), isFalse);
    });
  });

  group('InterstitialGate 카운터', () {
    test('recordAttempt를 4번 호출하면 4가 되고 다시 읽어도 4가 유지된다',
        () async {
      SharedPreferences.setMockInitialValues({});
      expect(await InterstitialGate.recordAttempt(), 1);
      expect(await InterstitialGate.recordAttempt(), 2);
      expect(await InterstitialGate.recordAttempt(), 3);
      expect(await InterstitialGate.recordAttempt(), 4);
      expect(await InterstitialGate.readAttemptCount(), 4);
    });

    test('카운터가 3에서 시작하면 다음 recordAttempt는 4를 반환한다', () async {
      SharedPreferences.setMockInitialValues(
          {InterstitialGate.countKey: 3});
      expect(await InterstitialGate.recordAttempt(), 4);
    });
  });

  group('AdService.interstitialAdUnitId', () {
    test('디버그 빌드에서는 Google 공식 테스트 ID를 쓴다', () {
      expect(AdService.interstitialAdUnitId,
          'ca-app-pub-3940256099942544/1033173712');
    });
  });

  group('InterstitialGate.goToResult', () {
    Future<void> pumpGateApp(
        WidgetTester tester, Map<String, Object> mockValues,
        {bool showInterstitial = true}) async {
      SharedPreferences.setMockInitialValues(mockValues);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => InterstitialGate.goToResult(
                context,
                showInterstitial: showInterstitial,
                resultBuilder: (_) => const Text('결과'),
                revealBuilder: (_) => const Text('애니메이션'),
              ),
              child: const Text('결과 보기'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('카운터가 3이면(다음 시도가 4번째) 광고 차례라 결과로 바로 간다',
        (tester) async {
      await pumpGateApp(tester, {InterstitialGate.countKey: 3});
      await tester.tap(find.text('결과 보기'));
      await tester.pumpAndSettle();

      // 광고가 로드돼 있지 않아 showInterstitialAd()가 false를 반환해도
      // 결과로 바로 가고, 애니메이션은 보이지 않는다.
      expect(find.text('결과'), findsOneWidget);
      expect(find.text('애니메이션'), findsNothing);
    });

    testWidgets('카운터가 0이면 애니메이션 경로로 간다', (tester) async {
      await pumpGateApp(tester, {});
      await tester.tap(find.text('결과 보기'));
      await tester.pumpAndSettle();

      expect(find.text('애니메이션'), findsOneWidget);
      expect(find.text('결과'), findsNothing);
    });

    testWidgets('showInterstitial이 false면 광고 차례에도 애니메이션 경로로 가고 카운터가 안 오른다',
        (tester) async {
      await pumpGateApp(tester, {InterstitialGate.countKey: 3},
          showInterstitial: false);
      await tester.tap(find.text('결과 보기'));
      await tester.pumpAndSettle();

      expect(find.text('애니메이션'), findsOneWidget);
      expect(find.text('결과'), findsNothing);
      // 이름 짓기 시도는 카운터를 갉아먹지 않는다.
      expect(await InterstitialGate.readAttemptCount(), 3);
    });

    testWidgets('showInterstitial이 false면 비광고 차례에도 애니메이션 경로로 가고 카운터가 안 오른다',
        (tester) async {
      await pumpGateApp(tester, {InterstitialGate.countKey: 1},
          showInterstitial: false);
      await tester.tap(find.text('결과 보기'));
      await tester.pumpAndSettle();

      expect(find.text('애니메이션'), findsOneWidget);
      expect(find.text('결과'), findsNothing);
      expect(await InterstitialGate.readAttemptCount(), 1);
    });
  });
}
