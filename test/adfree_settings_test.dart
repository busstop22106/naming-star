import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/screens/settings_screen.dart';
import 'package:jakmyeongbyeol/services/adfree_service.dart';
import 'package:jakmyeongbyeol/services/purchase_service.dart';

void main() {
  tearDown(() {
    AdFreeService.instance.resetForTest();
    PurchaseService.instance.resetForTest();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('구매 전에는 광고 제거 섹션에 구매·구매 복원하기 버튼이 보인다', (tester) async {
    await pumpSettings(tester);

    expect(find.text('광고 없이 사용하기'), findsOneWidget);
    expect(find.textContaining('평생 광고 없이 사용하기'), findsWidgets);
    expect(find.text('이미 구입하셨나요? 구매 복원하기'), findsOneWidget);
    expect(find.text('평생 유료 멤버쉽 적용됐어요'), findsNothing);
  });

  testWidgets('구매 후에는 "평생 유료 멤버쉽 적용됐어요"가 보이고 버튼이 사라진다',
      (tester) async {
    AdFreeService.instance.setForTest(true);
    await pumpSettings(tester);

    expect(find.text('평생 유료 멤버쉽 적용됐어요'), findsOneWidget);
    expect(find.text('이미 구입하셨나요? 구매 복원하기'), findsNothing);
  });
}
