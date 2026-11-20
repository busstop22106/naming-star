import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  testWidgets('시스템 애니메이션 끔 상태에서도 별 연출이 끝까지 재생된다 (회귀)',
      (tester) async {
    // 기기에서 '애니메이션 제거'가 켜져 있으면 AnimationController가
    // 기본 동작(normal)으로는 0.05배속(100ms)으로 끝나 별이 정지된
    // 이미지처럼 보인다 (갤럭시 S25+ 실기기 재현, 2026-11-20).
    // RevealScreen은 preserve로 시스템 설정을 무시하고 2초 연출을
    // 끝까지 재생해야 한다.
    final originalDisableAnimations = debugSemanticsDisableAnimations;
    debugSemanticsDisableAnimations = true;
    addTearDown(
      () => debugSemanticsDisableAnimations = originalDisableAnimations,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RevealScreen(
          nextBuilder: (_) => const Scaffold(body: Text('결과 화면')),
        ),
      ),
    );
    // 500ms: 아직 문구 페이드인 구간(0.35~0.65) 전이라 문구는 안 보인다.
    // (기본 동작이었으면 100ms 만에 끝나 문구가 다 보였을 것이다.)
    await tester.pump(const Duration(milliseconds: 500));
    final textOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('작명별이 이름을 고르고 있어요'),
        matching: find.byType(Opacity),
      ),
    );
    expect(textOpacity.opacity, 0.0);
    expect(find.byType(RevealScreen), findsOneWidget);
    expect(find.text('결과 화면'), findsNothing);

    // 1000ms: 페이드인 중간 — 문구가 실제로 나타나고 있어야 한다.
    // 500ms 검사만으로는 애니메이션이 0.0에 멈춰 있어도 통과하므로,
    // opacity가 커졌는지(재생 중인지)까지 확인한다 (제미나이 리뷰).
    await tester.pump(const Duration(milliseconds: 500));
    final midOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('작명별이 이름을 고르고 있어요'),
        matching: find.byType(Opacity),
      ),
    );
    expect(midOpacity.opacity, greaterThan(0.0));

    // 2100ms: 2초 연출이 끝나 결과 화면으로 넘어간다.
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(find.byType(RevealScreen), findsNothing);
    expect(find.text('결과 화면'), findsOneWidget);
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

    // 구성원 생일이 기본값이면 확인 다이얼로그가 먼저 뜬다.
    // '그대로 보기'를 눌러 궁합을 진행한다.
    final proceed = find.text('그대로 보기');
    if (proceed.evaluate().isNotEmpty) {
      await tester.tap(proceed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

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
