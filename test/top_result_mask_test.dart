import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/engine/generator.dart';
import 'package:jakmyeongbyeol/screens/recommend_screen.dart';
import 'package:jakmyeongbyeol/services/adfree_service.dart';
import 'package:jakmyeongbyeol/services/purchase_service.dart';

import 'favorites_flow_test.dart' show fakeSaju, pumpUntilFound, testBaby;

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
    PurchaseService.instance.resetForTest();
  });

  /// 현재 정렬(기본 종합점수순)의 1·2위 이름.
  (String, String) topTwoNames() {
    final sorted = generateNames(testBaby(), fakeSaju())
      ..sort((a, b) => b.total.compareTo(a.total));
    return (sorted.first.fullName, sorted[1].fullName);
  }

  Future<void> pumpRecommend(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: RecommendScreen(baby: testBaby(), saju: fakeSaju()),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openTopDialog(WidgetTester tester) async {
    await tester.ensureVisible(find.text('???'));
    await tester.tap(find.text('???'));
    await tester.pumpAndSettle();
    expect(find.text('1위 이름 확인하기'), findsOneWidget);
  }

  testWidgets('광고 제거 상태가 아니면 1위 카드만 ???로 가려진다', (tester) async {
    final (top, second) = topTwoNames();
    await pumpRecommend(tester);

    expect(find.text('???'), findsOneWidget);
    expect(find.text(top), findsNothing);
    expect(find.text('탭해서 1위 이름 확인하기'), findsOneWidget);
    // 2위부터는 그대로 보인다.
    expect(find.text(second), findsOneWidget);
  });

  testWidgets('1위 카드를 탭하면 확인 다이얼로그가 뜬다', (tester) async {
    await pumpRecommend(tester);
    await openTopDialog(tester);

    expect(find.text('광고 보고 바로 확인하기'), findsOneWidget);
    expect(find.textContaining('평생 광고 없이 보기'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
  });

  testWidgets('광고가 준비되지 않으면 안내가 뜨고 계속 가려진다', (tester) async {
    await pumpRecommend(tester);
    await openTopDialog(tester);

    await tester.tap(find.text('광고 보고 바로 확인하기'));
    await pumpUntilFound(
        tester, find.text('광고를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.'));

    // 다이얼로그는 그대로 열려 있고, 1위는 계속 가려진다.
    expect(find.text('1위 이름 확인하기'), findsOneWidget);
    expect(find.text('???'), findsOneWidget);
  });

  testWidgets('광고 제거 상태면 1위 카드가 처음부터 공개된다', (tester) async {
    final (top, _) = topTwoNames();
    AdFreeService.instance.setForTest(true);
    await pumpRecommend(tester);

    expect(find.text('???'), findsNothing);
    expect(find.text(top), findsOneWidget);
  });
}
