import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/screens/settings_screen.dart';

/// 설정 > 앱 버전 10회 연속 탭 이스터에그 검증.
/// 1~5회 탭은 조용히, 6회부터 카운트다운 토스트(5→1번 남음),
/// 10회 탭 뒤 편지 팝업이 뜬다 (2026-11-17).
void main() {
  setUp(() {
    // 테스트에서는 런타임 폰트 다운로드를 끈다 — 시스템 폰트로 그려진다.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> tapVersion(WidgetTester tester) async {
    await tester.tap(find.text('앱 버전'));
    await tester.pump();
  }

  testWidgets('앱 버전 타일에는 chevron이 없다 (라벨처럼 보인다)', (tester) async {
    await pumpSettings(tester);
    final versionTile = find.ancestor(
      of: find.text('앱 버전'),
      matching: find.byType(ListTile),
    );
    expect(versionTile, findsOneWidget);
    expect(
      find.descendant(
        of: versionTile,
        matching: find.byIcon(Icons.chevron_right),
      ),
      findsNothing,
    );
  });

  testWidgets('앱 버전 5회 탭까지는 토스트가 안 뜬다', (tester) async {
    await pumpSettings(tester);
    for (var i = 0; i < 5; i++) {
      await tapVersion(tester);
    }
    expect(find.textContaining('번 남았습니다'), findsNothing);
  });

  testWidgets('6회 탭부터 카운트다운 토스트가 뜬다', (tester) async {
    await pumpSettings(tester);
    for (var i = 0; i < 5; i++) {
      await tapVersion(tester);
    }
    await tapVersion(tester); // 6회
    expect(find.text('5번 남았습니다'), findsOneWidget);
    await tapVersion(tester); // 7회
    expect(find.text('4번 남았습니다'), findsOneWidget);
    await tapVersion(tester); // 8회
    expect(find.text('3번 남았습니다'), findsOneWidget);
    await tapVersion(tester); // 9회
    expect(find.text('2번 남았습니다'), findsOneWidget);
  });

  testWidgets('10회 탭하면 편지 팝업이 뜬다', (tester) async {
    await pumpSettings(tester);
    for (var i = 0; i < 9; i++) {
      await tapVersion(tester);
    }
    await tapVersion(tester); // 10회
    expect(find.text('1번 남았습니다'), findsOneWidget);
    // 800ms 뒤 편지 팝업이 뜬다. 폰트 대기(최대 2초)까지 고려해
    // 3초를 흘려보낸 뒤 확인한다.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.textContaining('나에게 우주를 보여준 한우주야'),
        findsOneWidget);
    expect(find.textContaining('2026.11.17 우주 아빠가'), findsOneWidget);
    expect(find.textContaining('사랑하는 윤경아'), findsOneWidget);
    // 상단에는 별 3개 대신 '숨겨둔 편지' 제목이 있다.
    expect(find.text('숨겨둔 편지'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
    // 편지 접기 버튼으로 팝업을 닫는다.
    await tester.tap(find.text('편지를 접어요'));
    await tester.pumpAndSettle();
    expect(find.textContaining('나에게 우주를 보여준 한우주야'), findsNothing);
  });
}
