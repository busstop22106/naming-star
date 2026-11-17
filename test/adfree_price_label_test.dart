import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/screens/settings_screen.dart';
import 'package:jakmyeongbyeol/services/adfree_service.dart';
import 'package:jakmyeongbyeol/services/purchase_service.dart';
import 'package:jakmyeongbyeol/widgets/adfree_price_label.dart';

void main() {
  tearDown(() {
    AdFreeService.instance.resetForTest();
    PurchaseService.instance.resetForTest();
  });

  group('할인 판별', () {
    test('₩2,450이면 할인 중이고 할인율은 50%', () {
      PurchaseService.instance.setPriceForTest(
        rawPrice: 2450,
        currencyCode: 'KRW',
        displayPrice: '₩2,450',
      );
      expect(PurchaseService.instance.isDiscounted, isTrue);
      expect(PurchaseService.instance.discountPercent, 50);
    });

    test('정가 ₩4,900이면 할인 아님', () {
      PurchaseService.instance.setPriceForTest(
        rawPrice: 4900,
        currencyCode: 'KRW',
        displayPrice: '₩4,900',
      );
      expect(PurchaseService.instance.isDiscounted, isFalse);
      expect(PurchaseService.instance.discountPercent, isNull);
    });

    test('가격을 못 읽으면 할인 아님', () {
      // 원화 금액이 없으면 표시 문구와 무관하게 할인 아님.
      PurchaseService.instance.priceNotifier.value = '가격 확인 중';
      expect(PurchaseService.instance.priceAmount, isNull);
      expect(PurchaseService.instance.isDiscounted, isFalse);
    });

    test('달러 가격(\$4.90)은 원화로 오인하지 않아 할인 아님', () {
      PurchaseService.instance.setPriceForTest(
        rawPrice: 4.90,
        currencyCode: 'USD',
        displayPrice: '\$4.90',
      );
      expect(PurchaseService.instance.priceAmount, isNull);
      expect(PurchaseService.instance.isDiscounted, isFalse);
    });

    test('₩0이면 100% 할인로 오표시하지 않는다', () {
      PurchaseService.instance.setPriceForTest(
        rawPrice: 0,
        currencyCode: 'KRW',
        displayPrice: '₩0',
      );
      expect(PurchaseService.instance.discountPercent, isNull);
      expect(PurchaseService.instance.isDiscounted, isFalse);
    });
  });

  Future<void> pumpLabel(
    WidgetTester tester, {
    required String price,
    required String prefix,
  }) async {
    // 표시가와 원화 금액을 함께 둔다 (가격 문자열만으로는 할인 판별 안 함).
    final amount = int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    PurchaseService.instance.setPriceForTest(
      rawPrice: amount.toDouble(),
      currencyCode: 'KRW',
      displayPrice: price,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdFreePriceLabel(prefix: prefix),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('정가일 때는 기존 문구 그대로 보인다', (tester) async {
    await pumpLabel(
      tester,
      price: '₩4,900',
      prefix: '평생 광고 없이 사용 · ',
    );
    expect(find.text('평생 광고 없이 사용 · ₩4,900'), findsOneWidget);
    expect(find.textContaining('할인'), findsNothing);
  });

  testWidgets('할인가일 때는 정가 두 줄 취소선·화살표·할인가가 보인다',
      (tester) async {
    await pumpLabel(
      tester,
      price: '₩2,450',
      prefix: '평생 광고 없이 사용 · ',
    );
    expect(find.text('평생 광고 없이 사용 · '), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('₩2,450'), findsOneWidget);
    expect(find.textContaining('기간 할인 중'), findsNothing);
    expect(find.textContaining('% 할인'), findsNothing);
    // WidgetSpan을 쓰지 않는다 — Wrap 안에 독립 위젯으로 둔다.
    expect(find.byType(Wrap), findsOneWidget);
    expect(find.byType(DoubleStrikeText), findsOneWidget);
    final strike =
        tester.widget<DoubleStrikeText>(find.byType(DoubleStrikeText));
    expect(strike.text, '₩4,900');
    // 두 줄 취소선: 1px 높이 Container가 2개이고, 선 색은
    // ₩4,900 텍스트 색(흐림 포함)과 동일하다.
    final lines = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(DoubleStrikeText),
        matching: find.byType(Container),
      ),
    ).toList();
    expect(lines.length, 2);
    for (final line in lines) {
      expect(line.constraints?.maxHeight, 1);
    }
    final priceText = tester.widget<Text>(
      find.descendant(
        of: find.byType(DoubleStrikeText),
        matching: find.byType(Text),
      ),
    );
    expect(lines.first.color, priceText.style?.color);
    expect(lines.last.color, priceText.style?.color);
  });

  testWidgets('두 취소선은 텍스트 정중앙을 기준으로 상하 대칭이다', (tester) async {
    await pumpLabel(
      tester,
      price: '₩2,450',
      prefix: '평생 광고 없이 사용 · ',
    );
    // 텍스트(₩4,900) 정중앙.
    final textCenter = tester.getCenter(
      find.descendant(
        of: find.byType(DoubleStrikeText),
        matching: find.byType(Text),
      ),
    );
    // 두 취소선의 정중앙 (dy 순으로 정렬).
    final lineFinder = find.descendant(
      of: find.byType(DoubleStrikeText),
      matching: find.byType(Container),
    );
    expect(lineFinder, findsNWidgets(2));
    final centers = [
      tester.getCenter(lineFinder.at(0)),
      tester.getCenter(lineFinder.at(1)),
    ]..sort((a, b) => a.dy.compareTo(b.dy));
    final above = textCenter.dy - centers.first.dy;
    final below = centers.last.dy - textCenter.dy;
    // 윗줄은 정중앙보다 위, 아랫줄은 정중앙보다 아래, 같은 거리.
    // (예전에는 Column 전체를 위로 올려서 아랫줄이 정중앙에 걸리고
    // 윗줄만 너무 위에 가는 대칭 깨짐이 있었다. 2026-11-17 실기기 피드백.)
    expect(above, greaterThan(0));
    expect(below, greaterThan(0));
    expect(above, moreOrLessEquals(below, epsilon: 1.0));
  });

  testWidgets('할인가일 때는 화살표가 Icon이고 할인가 텍스트가 따로 있다',
      (tester) async {
    await pumpLabel(
      tester,
      price: '₩2,450',
      prefix: '평생 광고 없이 사용 · ',
    );
    // 화살표는 텍스트 '→'가 아니라 Icon이다 — 텍스트 '→'는
    // 폴백 폰트 탓에 줄 상자가 커져서 아래로 처졌다.
    // (2026-11-17 실기기 피드백.)
    // Icon은 고정 크기라 Wrap 정중앙 정렬이 맞는다.
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('₩2,450'), findsOneWidget);
    expect(find.textContaining('→'), findsNothing);
    expect(find.byType(DoubleStrikeText), findsOneWidget);
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('설정 화면에서도 할인가일 때 두 줄 취소선·화살표가 보인다',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    PurchaseService.instance.setPriceForTest(
      rawPrice: 2450,
      currencyCode: 'KRW',
      displayPrice: '₩2,450',
    );
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('₩2,450'), findsOneWidget);
    expect(find.textContaining('기간 할인 중'), findsNothing);
    expect(find.textContaining('% 할인'), findsNothing);
    expect(find.byType(DoubleStrikeText), findsOneWidget);
  });
}
