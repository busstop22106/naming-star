import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/main.dart';

void main() {
  testWidgets('보관함 빈 화면에서 이름 지으러 가기를 누르면 이름 짓기 탭으로 간다',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // 긴 화면으로 펌프하면 스크롤 없이 홈 버튼까지 보인다.
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MainNav()));
    await tester.pumpAndSettle();

    // 설정 탭 → 보관함.
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('보관함'));
    // 저장소 로딩이 끝나 빈 화면 버튼이 보일 때까지 기다린다.
    for (var i = 0;
        i < 20 && find.text('이름 지으러 가기').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('아직 저장한 이름이 없어요.'), findsOneWidget);

    await tester.tap(find.text('이름 지으러 가기'));
    await tester.pumpAndSettle();

    // 보관함 화면은 닫히고 이름 짓기 탭(홈 고유 버튼)이 보인다.
    // IndexedStack의 다른 탭은 offstage라 기본 finder에 안 잡힌다.
    expect(find.text('아직 저장한 이름이 없어요.'), findsNothing);
    expect(find.text('아기에게 좋은 이름 지어보기'), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
  });
}
