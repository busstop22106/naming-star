import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/screens/ranking_screen.dart';
import 'package:jakmyeongbyeol/services/ad_service.dart';
import 'package:jakmyeongbyeol/theme.dart';

void main() {
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

  Future<void> pumpRanking(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: const RankingScreen(),
    ));
    await tester.pumpAndSettle();
  }

  /// 보이는 리스트를 끝까지 스크롤한다. SliverList는 화면 밖 자식을
  /// lazy하게 빌드하므로, 끝의 배너는 스크롤한 뒤에야 트리에 나타난다.
  Future<void> scrollToEnd(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      if (find.byType(BannerAdWidget).evaluate().isNotEmpty) break;
      await tester.fling(
          find.byType(RankingScreen), const Offset(0, -500), 1000);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('랭킹 배너는 리스트 안에 있고 화면에 1개만 있다',
      (tester) async {
    await pumpRanking(tester);
    await scrollToEnd(tester);
    expect(find.byType(BannerAdWidget), findsOneWidget);
    // 고정 하단이 아니라 스크롤 리스트의 자손이다.
    expect(
      find.ancestor(
          of: find.byType(BannerAdWidget), matching: find.byType(CustomScrollView)),
      findsOneWidget,
    );
  });

  testWidgets('랭킹 배너는 진입 직후에는 없고 최하단까지 스크롤해야 나타난다',
      (tester) async {
    await pumpRanking(tester);
    // 진입 직후 배너는 화면에 고정되어 있지 않다 (리스트 끝에 있다).
    expect(find.byType(BannerAdWidget), findsNothing);
    await scrollToEnd(tester);
    expect(find.byType(BannerAdWidget), findsOneWidget);
    final screenHeight = tester.view.physicalSize.height;
    expect(tester.getTopLeft(find.byType(BannerAdWidget)).dy,
        lessThan(screenHeight));
  });

  testWidgets('탭을 바꿔도 배너는 1개, 리스트 안에 있다', (tester) async {
    await pumpRanking(tester);
    await tester.tap(find.text('여아 TOP 20'));
    await tester.pumpAndSettle();
    await scrollToEnd(tester);
    expect(find.byType(BannerAdWidget), findsOneWidget);
    expect(
      find.ancestor(
          of: find.byType(BannerAdWidget), matching: find.byType(CustomScrollView)),
      findsOneWidget,
    );
  });
}
