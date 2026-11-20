import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/services/favorites.dart';
import 'package:jakmyeongbyeol/screens/reveal_screen.dart';
import 'package:jakmyeongbyeol/services/adfree_service.dart';
import 'package:jakmyeongbyeol/services/purchase_service.dart';
import 'package:jakmyeongbyeol/widgets/adfree_price_label.dart';

import 'favorites_flow_test.dart' show testBaby, testPicks;

/// 2026-11-17 버그 수정 묶음 회귀 테스트.
/// 1) 설정 결제 버튼 무한 뺑뺑이: Play 시트를 닫고 구매를 안 했는데도
///    스트림 이벤트가 안 오면 버튼이 30초 타임아웃까지 돈다.
///    앱이 resumed가 되면 유예 뒤 busy를 푼다.
/// 2) 보관함 손상: 저장값이 깨지면 저장이 영원히 안 되고 불러오기도
///    오류 화면만 뜬다. 원본을 백업하고 새로 시작한다.
/// 3) RevealScreen 탭 스킵: 탭하면 바로 결과로 가던 것을 막고,
///    '탭하면 바로 볼 수 있어요' 문구를 뺀다.
/// 4) 결제 버튼 줄바꿈: '₩1,900'만 2줄로 떨어지던 것을
///    '평생 광고 없이 사용' / '₩4,900 → ₩1,900'으로 나눈다.
void main() {
  tearDown(() {
    PurchaseService.instance.resetForTest();
    AdFreeService.instance.resetForTest();
  });

  PurchaseDetails realPurchase(PurchaseStatus status) {
    return PurchaseDetails(
      purchaseID: 'test-purchase-id',
      productID: PurchaseService.adFreeProductId,
      status: status,
      transactionDate: '1700000000000',
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'google_play',
      ),
    );
  }

  group('결제 시트 닫힘 — 앱 복귀 시 busy 해제', () {
    testWidgets('구매 없이 시트만 닫으면 유예 뒤 busy가 풀린다', (tester) async {
      final service = PurchaseService.instance;
      service.busyNotifier.value = true; // 결제 시트 띄운 상태
      // 앱이 다시 보인다 (시트 닫힘).
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      // 유예(800ms) 전에는 아직 busy.
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.isBusy, isTrue);
      // 유예가 지나면 busy가 풀린다 — 오류 스낵바는 안 뜬다 (취소는 오류 아님).
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.isBusy, isFalse);
      expect(service.errorNotifier.value, isNull);
    });

    testWidgets('구매 이벤트가 오면 유예 타이머가 취소되고 광고 제거가 켜진다',
        (tester) async {
      final service = PurchaseService.instance;
      SharedPreferences.setMockInitialValues({});
      await AdFreeService.instance.ensureLoaded();
      service.busyNotifier.value = true;
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 500));
      // 유예 안에 구매 완료 이벤트가 온다.
      service.handlePurchaseUpdateForTest(
          [realPurchase(PurchaseStatus.purchased)]);
      // setAdFree는 비동기로 저장소에 쓰고 나서 플래그를 켜니
      // 한 프레임 밀어줘야 isAdFree가 true가 된다.
      await tester.pump();
      expect(service.isBusy, isFalse);
      expect(AdFreeService.instance.isAdFree, isTrue);
      // 타이머가 취소됐으니 더 펌프해도 busy가 다시 안 켜진다.
      await tester.pump(const Duration(seconds: 2));
      expect(service.isBusy, isFalse);
    });

    testWidgets('pending 구매 이벤트가 오면 busy가 유지된다 (유예 타이머 취소)',
        (tester) async {
      final service = PurchaseService.instance;
      service.busyNotifier.value = true;
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 500));
      // pending은 아직 진행 중이라 busy를 안 푼다.
      service.handlePurchaseUpdateForTest(
          [realPurchase(PurchaseStatus.pending)]);
      expect(service.isBusy, isTrue);
      // 유예 타이머가 취소됐으니 800ms가 지나도 busy 유지.
      await tester.pump(const Duration(seconds: 2));
      expect(service.isBusy, isTrue);
    });

    test('구매 중이 아니면 앱 복귀가 busy를 건드리지 않는다', () {
      final service = PurchaseService.instance;
      expect(service.isBusy, isFalse);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(service.isBusy, isFalse);
    });
  });

  group('보관함 손상 복구', () {
    test('저장값이 깨져 있어도 저장이 되고 다시 읽힌다', () async {
      // 최상위 JSON이 깨진 상태.
      SharedPreferences.setMockInitialValues({
        'jakmyeongbyeol_favorites': '{깨진 json',
      });
      final item = FavoriteItem(
        baby: testBaby(),
        picks: testPicks(),
        total: 92,
        savedAt: DateTime(2026, 11, 17),
      );
      // 예전에는 corrupt라 false를 돌려줘 저장이 영원히 안 됐다.
      final ok = await saveFavorite(item);
      expect(ok, isTrue);
      final items = await loadFavorites();
      expect(items.length, 1);
      expect(items.first.fullName, '김도윤');
      // 깨진 원본은 백업 키에 남는다.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jakmyeongbyeol_favorites_corrupt_backup'),
          '{깨진 json');
    });

    test('저장값이 깨져 있으면 불러오기는 빈 목록을 돌려준다 (예외 안 던짐)',
        () async {
      SharedPreferences.setMockInitialValues({
        'jakmyeongbyeol_favorites': '{"version": 99, "items": []}',
      });
      // 버전이 안 맞아 corrupt — 예전에는 loadFavorites가 빈 목록을
      // 돌려줬지만, 화면의 타임아웃·예외 경로와 합쳐져 오류 화면이 떴다.
      // 이제는 빈 목록이 와서 빈 화면('이름 지으러 가기')이 뜬다.
      final items = await loadFavorites();
      expect(items, isEmpty);
    });

    test('버전은 맞는데 항목이 깨져 있으면 그 항목만 건너뛰고 저장은 된다',
        () async {
      SharedPreferences.setMockInitialValues({
        'jakmyeongbyeol_favorites':
            '{"version": 1, "items": [{"baby": "깨짐"}]}',
      });
      final item = FavoriteItem(
        baby: testBaby(),
        picks: testPicks(),
        total: 92,
        savedAt: DateTime(2026, 11, 17),
      );
      expect(await saveFavorite(item), isTrue);
      final items = await loadFavorites();
      expect(items.length, 1);
      expect(items.first.fullName, '김도윤');
    });
  });

  group('RevealScreen 탭 차단', () {
    testWidgets('화면을 탭해도 결과로 안 넘어간다', (tester) async {
      var navigated = false;
      await tester.pumpWidget(
        MaterialApp(
          home: RevealScreen(
            nextBuilder: (_) => Builder(
              builder: (context) {
                navigated = true;
                return const Scaffold(body: Text('결과 화면'));
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(RevealScreen), findsOneWidget);
      expect(find.text('결과 화면'), findsNothing);
      // 화면 한가운데를 탭한다 — 예전에는 여기서 바로 결과로 갔다.
      await tester.tap(find.byType(RevealScreen));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(RevealScreen), findsOneWidget);
      expect(find.text('결과 화면'), findsNothing);
      expect(navigated, isFalse);
      // '탭하면 바로 볼 수 있어요' 문구는 삭제됐다.
      expect(find.text('탭하면 바로 볼 수 있어요'), findsNothing);
    });

    testWidgets('애니메이션(2초)이 끝나면 탭 없이도 결과로 간다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RevealScreen(
            nextBuilder: (_) =>
                const Scaffold(body: Text('결과 화면')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RevealScreen), findsNothing);
      expect(find.text('결과 화면'), findsOneWidget);
    });
  });

  group('결제 버튼 줄바꿈 — 가격 덩어리', () {
    testWidgets('할인 시 Wrap 자식은 prefix 텍스트와 가격 Row 2개뿐이다',
        (tester) async {
      PurchaseService.instance.setPriceForTest(
        rawPrice: 1900,
        currencyCode: 'KRW',
        displayPrice: '₩1,900',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdFreePriceLabel(prefix: '평생 광고 없이 사용 '),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      // 자식 2개: [Text(prefix), Row(가격 덩어리)].
      // 예전에는 4개(텍스트·취소선·아이콘·할인가)라 '₩1,900'만
      // 2줄로 떨어졌다.
      expect(wrap.children.length, 2);
      expect(wrap.children.first, isA<Text>());
      expect(wrap.children.last, isA<Row>());
      final row = wrap.children.last as Row;
      // 가격 덩어리 안: 취소선 정가·아이콘 화살표·할인가.
      expect(
        row.children.whereType<DoubleStrikeText>().length,
        1,
      );
      expect(
        row.children.whereType<Icon>().length,
        1,
      );
      expect(
        row.children.whereType<Text>().length,
        1,
      );
      expect(find.text('₩1,900'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });
}
