import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/services/adfree_service.dart';
import 'package:jakmyeongbyeol/services/interstitial_gate.dart';

void main() {
  setUp(() {
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
    AdFreeService.instance.resetForTest();
  });

  Future<void> pumpGateApp(
      WidgetTester tester, Map<String, Object> mockValues) async {
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

  testWidgets('광고 제거 상태면 카운터가 3이어도 광고 없이 애니메이션 경로로 간다',
      (tester) async {
    AdFreeService.instance.setForTest(true);
    await pumpGateApp(tester, {InterstitialGate.countKey: 3});
    await tester.tap(find.text('결과 보기'));
    await tester.pumpAndSettle();

    expect(find.text('애니메이션'), findsOneWidget);
    expect(find.text('결과'), findsNothing);
    // 광고 제거 상태에서는 카운터도 올리지 않는다.
    expect(await InterstitialGate.readAttemptCount(), 3);
  });
}
