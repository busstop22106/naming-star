import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/theme.dart';
import 'package:jakmyeongbyeol/widgets/common.dart';
import 'package:jakmyeongbyeol/widgets/night_sky.dart';

/// 밤하늘 테마 회귀 테스트 (2026-11-12).
///
/// 텍스트 토큰이 카드 위에서 WCAG AA(4.5:1)를 만족하는지, 별·달 위젯이
/// 깨지지 않고 그려지는지 확인한다. 토큰 값을 바꾸면 이 테스트가 먼저
/// 잡아낸다.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('밤하늘 테마 명암비', () {
    test('배경은 어둡고 글자는 밝다', () {
      expect(AppTheme.bg.computeLuminance(), lessThan(0.05));
      expect(AppTheme.ink.computeLuminance(), greaterThan(0.8));
    });

    test('텍스트 토큰은 카드 위에서 AA(4.5:1)를 만족한다', () {
      const surface = AppTheme.surface;
      for (final c in [
        AppTheme.ink,
        AppTheme.sub,
        AppTheme.hint,
        AppTheme.gold,
        AppTheme.primaryDark,
        AppTheme.boyDark,
        AppTheme.girlDark,
        AppTheme.pinkDark,
        AppTheme.goodDark,
        AppTheme.warnDark,
        AppTheme.danger,
      ]) {
        expect(_contrast(c, surface), greaterThanOrEqualTo(4.5),
            reason: '$c on $surface');
      }
    });

    test('금색 버튼 위 어두운 글자도 AA를 만족한다', () {
      expect(
        _contrast(AppTheme.onGold, AppTheme.primary),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('흰 글자는 네이비 헤더 위에서 AA를 만족한다', () {
      expect(
        _contrast(Colors.white, AppTheme.deepNavy),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(Colors.white, AppTheme.deepNavyDark),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('밤하늘 위젯', () {
    testWidgets('Starfield와 CrescentMoon이 깨지지 않고 그려진다',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Starfield(),
                Center(child: CrescentMoon(size: 30)),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('StarHero에 초승달이 함께 보인다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StarHero(title: '작명별', subtitle: '밤하늘 테스트'),
          ),
        ),
      );
      expect(find.byType(CrescentMoon), findsOneWidget);
      expect(find.text('작명별'), findsOneWidget);
    });
  });
}
