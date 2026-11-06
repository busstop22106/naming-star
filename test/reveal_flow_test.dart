import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/screens/analyze_screen.dart';
import 'package:jakmyeongbyeol/screens/compat_screen.dart';
import 'package:jakmyeongbyeol/screens/detail_screen.dart';
import 'package:jakmyeongbyeol/screens/home_screen.dart';
import 'package:jakmyeongbyeol/screens/recommend_screen.dart';
import 'package:jakmyeongbyeol/screens/reveal_screen.dart';

/// RevealScreen 경유 흐름:
/// 홈→추천, 이름 분석→상세, 가족 궁합→궁합 화면 모두 버튼 탭 뒤에
/// 2초짜리 별 애니메이션(RevealScreen)이 보이고, 애니메이션이 끝나면
/// 결과 화면으로 넘어가는지 확인한다.
/// (탭 이벤트는 한 프레임 뒤에 처리되므로 탭 뒤에 pump()를 넣는다.)

void main() {
  testWidgets('홈에서 이름 짓기를 누르면 RevealScreen을 거쳐 추천 화면으로 간다',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    final button = find.text('아기에게 좋은 이름 지어보기');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 별 애니메이션 화면이 이름 짓기용 문구와 함께 보인다.
    expect(find.byType(RevealScreen), findsOneWidget);
    expect(find.text('작명별이 이름을 고르고 있어요'), findsOneWidget);
    expect(find.byType(RecommendScreen), findsNothing);

    // 애니메이션(2초)이 끝나면 추천 화면으로 넘어간다.
    await tester.pumpAndSettle();
    expect(find.byType(RevealScreen), findsNothing);
    expect(find.byType(RecommendScreen), findsOneWidget);
  });

  testWidgets('이름 분석을 누르면 RevealScreen을 거쳐 상세 화면으로 간다',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: AnalyzeScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '준서');
    await tester.pumpAndSettle();
    final button = find.text('이 이름으로 분석하기');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(RevealScreen), findsOneWidget);
    expect(find.text('작명별이 이름을 분석하고 있어요'), findsOneWidget);
    expect(find.byType(DetailScreen), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(RevealScreen), findsNothing);
    expect(find.byType(DetailScreen), findsOneWidget);
  });

  testWidgets('가족 궁합 보기를 누르면 RevealScreen을 거쳐 궁합 화면으로 간다',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: AnalyzeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('가족 궁합'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '준서');
    await tester.pumpAndSettle();
    final button = find.text('가족 궁합 보기');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(RevealScreen), findsOneWidget);
    expect(find.text('가족 구성원 간 궁합을 알아보고 있어요'), findsOneWidget);
    expect(find.byType(CompatScreen), findsNothing);

    // 애니메이션(2초)이 끝나면 궁합 화면으로 넘어간다.
    // CompatScreen에는 하트가 계속 뛰는 반복 애니메이션이 있어
    // pumpAndSettle이 끝나지 않으므로, 궁합 화면이 뜰 때까지
    // 짧게 나눠서 펌프한다. (한 번에 3초를 밀면 애니메이션이
    // 끝나지 않고 RevealScreen에 머무는 경우가 있다.)
    for (var i = 0;
        i < 20 && find.byType(CompatScreen).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(CompatScreen), findsOneWidget);
    // 화면 전환 애니메이션(300ms)이 끝날 때까지 한 번 더 밀어야
    // RevealScreen이 트리에서 완전히 사라진다.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(RevealScreen), findsNothing);
  });
}
