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
      prefix: '평생 광고 없이 사용하기 · ',
    );
    expect(find.text('평생 광고 없이 사용하기 · ₩4,900'), findsOneWidget);
    expect(find.textContaining('할인'), findsNothing);
  });

  testWidgets('할인가일 때는 정가 취소선·할인가·할인율이 보인다',
      (tester) async {
    await pumpLabel(
      tester,
      price: '₩2,450',
      prefix: '평생 광고 없이 사용하기 · ',
    );
    expect(find.textContaining('50% 할인'), findsOneWidget);
    // '50% 할인'을 포함한 RichText가 딱 하나이고, 그 두 번째 span이
    // 정가 취소선이다. (Text 위젯도 내부적으로 RichText라 직접 찾는다.)
    final richTexts = tester
        .widgetList<RichText>(find.byType(RichText))
        .where(
          (r) => (r.text as TextSpan).toPlainText().contains('50% 할인'),
        )
        .toList();
    expect(richTexts.length, 1);
    final span = richTexts.first.text as TextSpan;
    // Text.rich는 넘긴 span을 기본 스타일 적용용으로 한 겹 더 감싸서,
    // 실제 3개 span은 children[0] 안에 있다. 그 두 번째 span이 정가 취소선이다.
    final inner = span.children![0] as TextSpan;
    final struck = inner.children![1] as TextSpan;
    expect(struck.text, '₩4,900');
    expect(struck.style?.decoration, TextDecoration.lineThrough);
    expect(span.toPlainText(), '평생 광고 없이 사용하기 · ₩4,900 ₩2,450 · 50% 할인');
  });

  testWidgets('설정 화면에서도 할인가일 때 50% 할인이 보인다',
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

    expect(find.textContaining('50% 할인'), findsOneWidget);
  });
}
