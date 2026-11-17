import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'adfree_service.dart';

/// 평생 광고 제거(₩4,900) 인앱결제.
/// - 상품: 비소모성 일회성 구매. Play Console에 사용자가 직접 등록해야 한다.
///   (상품 ID adfree_lifetime_4900, ₩4,900 — 결정사주의 decision_report_4900과 같은 방식)
/// - 구매 흐름은 Play Billing이 띄우는 결제 시트에서 진행되고, 결과는
///   purchaseStream으로 돌아온다. 이 클래스는 절대 버튼을 누르기 전에
///   구매를 시작하지 않는다.
/// - 구매 인정은 Play Billing 클라이언트 콜백 기준이다. 서버 검증은
///   나중에 고도화할 때 붙이는 것으로 남겨둔다.
/// - 구매 복원 결과: [RestoreResult]로 성공·없음·실패를 구분한다.
enum RestoreResult { restored, none, failed }

class PurchaseService {
  static final PurchaseService instance = PurchaseService._internal();
  PurchaseService._internal();

  /// Play Console에 등록할 비소모성 상품 ID.
  static const String adFreeProductId = 'adfree_lifetime_4900';

  /// 정가(출시 특가 기준가). 스토어 가격이 이보다 낮으면 할인 표시를 한다.
  /// Play 결제창 자체에는 취소선이 안 뜨고(플러그인 한계),
  /// 앱 다이얼로그·설정 화면에서만 정가 취소선을 보여준다.
  /// 정가 금액·표시 문구·fallback은 이 상수 하나에서 파생한다 (2026-11-16).
  static const int regularPriceAmount = 4900;

  /// 정가 표시 문구.
  static const String regularPriceText = '₩4,900';

  /// 스토어 가격을 못 받았을 때 보여주는 문구 (= 정가 표시).
  static const String fallbackPrice = regularPriceText;

  /// 스토어에서 받은 가격 (못 받으면 fallbackPrice).
  final ValueNotifier<String> priceNotifier =
      ValueNotifier<String>(fallbackPrice);

  /// 구매·복원 진행 중 여부 (버튼 로딩 표시용).
  final ValueNotifier<bool> busyNotifier = ValueNotifier<bool>(false);

  /// 스토어 연결 + 상품 조회 성공 여부.
  final ValueNotifier<bool> productsAvailableNotifier =
      ValueNotifier<bool>(false);

  /// 상품 조회 시도 완료 여부 (실패 힌트는 조회가 끝난 뒤에만 보여준다).
  final ValueNotifier<bool> productsCheckedNotifier =
      ValueNotifier<bool>(false);

  /// 구매·복원 실패/취소 메시지. 화면이 스낵바로 보여주고 비운다.
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  String get price => priceNotifier.value;
  bool get isBusy => busyNotifier.value;
  bool get productsAvailable => productsAvailableNotifier.value;

  /// 스토어에서 받은 가격의 원 단위 금액. 원화(KRW)일 때만 유효하다.
  /// `ProductDetails.rawPrice`(double)와 `currencyCode`를 쓴다.
  /// 가격 문자열을 숫자만 뽑아 파싱하면 `$4.90`이 490으로 읽혀
  /// '90% 할인'으로 오표시된다 (2026-11-16).
  /// 원화가 아니거나 아직 못 받았으면 null (할인 표시 안 함).
  int? get priceAmount {
    final raw = _rawPrice;
    if (raw == null || _currencyCode != 'KRW') return null;
    return raw.round();
  }

  /// 스토어 가격이 정가보다 낮으면 true (출시 특가 등).
  /// 0원 이하는 할인이 아니라 무료·오류로 보고 false.
  bool get isDiscounted {
    final amount = priceAmount;
    return amount != null && amount > 0 && amount < regularPriceAmount;
  }

  /// 할인율(정수 %). 할인 중이 아니면 null.
  /// 금액이 0 이하이면 100% 할인으로 오표시되지 않게 null을 돌려준다.
  int? get discountPercent {
    final amount = priceAmount;
    if (amount == null || amount <= 0 || amount >= regularPriceAmount) {
      return null;
    }
    final percent =
        ((regularPriceAmount - amount) * 100 / regularPriceAmount).round();
    return percent.clamp(1, 99);
  }

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _product;
  double? _rawPrice;
  String? _currencyCode;
  bool _initialized = false;
  bool _productsLoaded = false;

  /// 이번 실행에서 스토어 복원으로 소유한 구매를 본 적이 있는지.
  /// init() 뒤 로컬 광고 제거 플래그와 대조해 환불된 구매를 끄는 데 쓴다.
  bool _ownedPurchaseSeen = false;

  /// 앱 시작 시 1회: 권한 저장값을 읽고, 스토어 구매 내역을 복원한다.
  /// 스토어에 닿지 못해도 앱 진입을 막지 않는다 (예외는 삼킨다).
  /// 구매 스트림 리스너는 스토어 연결 여부와 무관하게 가장 먼저 단다.
  /// isAvailable()이 느리거나 실패하면 리스너가 안 달려 구매 업데이트를
  /// 놓치는 문제가 있었다 (2026-11-15 테스트 결제 미반영 원인).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await AdFreeService.instance.ensureLoaded();
      _subscription ??= InAppPurchase.instance.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (Object e) =>
            debugPrint('구매 스트림 오류: $e'),
      );
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) return;
      await refreshProducts();
      // 재설치·기기 변경 후에도 스토어 계정 기준으로 권한을 되살린다.
      await InAppPurchase.instance.restorePurchases();
      // 복원 결과가 스트림으로 오는 시간을 주고, 구매 내역이 없는데
      // 로컬 플래그만 켜져 있으면(환불·취소 등) 끈다. 시작을 막지 않게
      // 백그라운드로 돌린다 (2026-11-16).
      unawaited(_reconcileAdFreeFlag());
    } catch (e) {
      // 스토어 연결 실패는 광고 제거 없이 계속 가는 것으로 처리한다.
      debugPrint('구매 서비스 초기화 실패 — 광고 제거 없이 계속: $e');
    }
  }

  /// 복원 뒤 로컬 광고 제거 플래그를 스토어 구매 내역과 대조한다.
  /// 스토어에 닿아 복원을 마쳤는데 구매 내역이 없으면 환불·취소된
  /// 것이므로 로컬 플래그를 끈다. 스토어에 닿지 못한 경우는 건드리지
  /// 않는다 (이 메서드는 복원이 끝난 뒤에만 부른다).
  Future<void> _reconcileAdFreeFlag() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!AdFreeService.instance.isAdFree) return;
    if (_ownedPurchaseSeen) return;
    debugPrint('구매 내역이 없어 로컬 광고 제거 플래그를 끈다.');
    await AdFreeService.instance.setAdFree(false);
  }

  /// 상품 정보를 (다시) 조회한다. 스토어 가격을 받아오면 price에 반영한다.
  /// [force]가 true면 캐시를 무시하고 다시 조회한다 — 구매 직전 가격을
  /// 새로고침해 특가 종료 등이 바로 반영되게 한다 (2026-11-16).
  Future<void> refreshProducts({bool force = false}) async {
    if (_productsLoaded && !force) return;
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        productsAvailableNotifier.value = false;
        return;
      }
      final response = await InAppPurchase.instance.queryProductDetails(
        {adFreeProductId},
      );
      if (response.error != null || response.productDetails.isEmpty) {
        // 상품이 아직 콘솔에 없거나 조회 실패 — fallback 가격으로 둔다.
        productsAvailableNotifier.value = false;
        return;
      }
      _product = response.productDetails.first;
      // 원화 금액·통화코드를 먼저 저장한 뒤 표시 가격을 바꿔야
      // isDiscounted가 일관되게 읽힌다.
      _rawPrice = _product!.rawPrice;
      _currencyCode = _product!.currencyCode;
      priceNotifier.value = _product!.price;
      productsAvailableNotifier.value = true;
      _productsLoaded = true;
    } catch (e) {
      debugPrint('상품 정보 조회 실패: $e');
      productsAvailableNotifier.value = false;
    } finally {
      productsCheckedNotifier.value = true;
    }
  }

  /// 평생 광고 제거를 구매한다. 버튼을 눌렀을 때만 호출할 것.
  /// 결제 시트 실행 여부를 반환한다 (실제 구매 완료는 purchaseStream으로 온다).
  /// busy는 결제 시트가 뜬 뒤에는 스트림 콜백(완료·취소·오류)에서 푼다.
  /// 시트 직후에 풀면 재탭이 가능해 '결제를 시작하지 못했어요' 오류가
  /// 뜰 수 있다 (2026-11-16).
  Future<bool> buyAdFree() async {
    if (isBusy) return false;
    busyNotifier.value = true;
    // 결제 시트가 뜬 뒤 스트림 이벤트가 아예 안 오면 busy가 영원히
    // 안 풀린다. 30초 안에 응답이 없으면 busy를 강제로 푼다.
    // (오푸스 리뷰, 2026-11-17)
    _cancelBuyTimeout();
    _buyTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (isBusy) {
        errorNotifier.value = '응답이 없어요. 잠시 후 다시 시도해 주세요.';
        busyNotifier.value = false;
      }
    });
    try {
      await refreshProducts(force: true);
      final product = _product;
      if (product == null) {
        errorNotifier.value = '상품 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
        _cancelBuyTimeout();
        busyNotifier.value = false;
        return false;
      }
      final launched = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!launched) {
        errorNotifier.value = '결제를 시작하지 못했어요. 잠시 후 다시 시도해 주세요.';
        _cancelBuyTimeout();
        busyNotifier.value = false;
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('결제 시작 실패: $e');
      errorNotifier.value = '결제를 시작하지 못했어요. 잠시 후 다시 시도해 주세요.';
      _cancelBuyTimeout();
      busyNotifier.value = false;
      return false;
    }
  }

  /// 스토어 구매 내역을 복원한다.
  /// - [RestoreResult.restored]: 구매를 찾아 권한을 켰다.
  /// - [RestoreResult.none]: 구매 내역이 없다.
  /// - [RestoreResult.failed]: 스토어 연결·타임아웃 등 복원 자체가 실패했다.
  /// 복원할 구매가 없을 때와 실패했을 때를 구분해 화면 문구를 나눈다
  /// (2026-11-16). 타임아웃(10초) 안에 스트림 응답이 없으면 실패로 본다.
  Future<RestoreResult> restore() async {
    if (AdFreeService.instance.isAdFree) return RestoreResult.restored;
    if (isBusy) return RestoreResult.failed;
    busyNotifier.value = true;
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        errorNotifier.value = '스토어에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.';
        return RestoreResult.failed;
      }
      final completer = Completer<bool>();
      _restoreCompleter = completer;
      await InAppPurchase.instance.restorePurchases();
      final restored = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // 타임아웃 후 뒤늦게 오는 스트림 이벤트가 죽은 completer를
          // 건드리지 않게 참조를 끊는다 (2026-11-16).
          _restoreCompleter = null;
          return false;
        },
      );
      _restoreCompleter = null;
      // 타임아웃 직후 늦게 도착한 복원 이벤트가 이미 권한을 켰으면 성공으로 본다.
      if (!restored && AdFreeService.instance.isAdFree) {
        return RestoreResult.restored;
      }
      return restored ? RestoreResult.restored : RestoreResult.none;
    } catch (e) {
      debugPrint('구매 복원 실패: $e');
      errorNotifier.value = '복원하지 못했어요. 잠시 후 다시 시도해 주세요.';
      return RestoreResult.failed;
    } finally {
      busyNotifier.value = false;
    }
  }

  Completer<bool>? _restoreCompleter;

  /// 구매 시트 대기 타임아웃. buyNonConsumable이 true를 반환한 뒤
  /// 스트림 이벤트가 아예 안 오면(Play 크래시·네트워크 단절 등)
  /// busy가 영원히 안 풀린다. 30초 안에 응답이 없으면 busy를
  /// 강제로 푼다 (오푸스 리뷰, 2026-11-17).
  Timer? _buyTimeoutTimer;

  void _cancelBuyTimeout() {
    _buyTimeoutTimer?.cancel();
    _buyTimeoutTimer = null;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      // Play가 결제 실패·취소를 알릴 때 구매 목록이 비어 있으면 플러그인이
      // productID ''인 합성 이벤트를 만든다
      // (in_app_purchase_android 0.5.5 _getPurchaseDetailsFromResult).
      // 상품 ID가 안 맞는다고 걸러버리면 busy가 영원히 안 풀려
      // 설정 버튼이 무한 뺑뺑이가 된다 (2026-11-17 실기기 재현:
      // 1위 다이얼로그에서 결제 시도 뒤 Play가 '구입하려는 항목을
      // 찾을 수 없습니다'를 띄우고 돌아왔는데도 busy가 그대로였다).
      // 구매 중(busy)인 합성 이벤트는 우리 구매 시도로 보고 busy를 푼다.
      // 단, 합성 이벤트로는 광고 제거 권한을 켜지 않는다
      // (실제 구매 객체가 없어서 검증이 안 된다).
      if (purchase.productID.isEmpty) {
        if (!isBusy) continue;
        // pending은 아직 진행 중이라 busy를 풀지 않는다 — 최종 결과가
        // 뒤이어 스트림으로 온다. (플러그인은 합성 pending을 만들지
        // 않지만 방어적으로 둔다. 오푸스 리뷰, 2026-11-17)
        if (purchase.status == PurchaseStatus.pending) continue;
        // 복원 중이면 복원 맥락의 문구를, 구매 중이면 구매 문구를 쓴다.
        // (복원 중에 '구매에 실패했어요'가 뜨면 헷갈린다. 오푸스 리뷰, 2026-11-17)
        final isRestoring = _restoreCompleter != null;
        if (purchase.status == PurchaseStatus.error) {
          errorNotifier.value = isRestoring
              ? '복원에 실패했어요. 다시 시도해 주세요.'
              : '구매에 실패했어요. 다시 시도해 주세요.';
        } else if (purchase.status == PurchaseStatus.canceled) {
          errorNotifier.value =
              isRestoring ? '복원을 취소했어요.' : '구매를 취소했어요.';
        } else if (purchase.status == PurchaseStatus.purchased &&
            !isRestoring) {
          // 구매 중인데 구매 객체 없이 완료만 왔다 — 돈은 빠졌을 수 있으나
          // 확인할 수 없으니 앱 재시작 시 복원으로 반영되게 안내한다.
          // (복원 중에는 구매 내역이 없는 정상 경우라 메시지를 안 띄운다.
          // 오푸스 리뷰, 2026-11-17)
          errorNotifier.value = '처리 중 문제가 생겼어요. 앱을 다시 시작해 주세요.';
        }
        _completeRestore(false);
        _cancelBuyTimeout();
        busyNotifier.value = false;
        continue;
      }
      if (purchase.productID != adFreeProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // 이전 오류 메시지가 남아 있으면 지운다 — 합성 오류 뒤에
          // 실제 구매 완료가 오면 성공인데도 에러 스낵바가 뜬다.
          // (오푸스 리뷰, 2026-11-17)
          errorNotifier.value = null;
          _ownedPurchaseSeen = true;
          unawaited(AdFreeService.instance.setAdFree(true));
          if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
            _restoreCompleter!.complete(true);
          }
          // 구매가 끝났으니 버튼 busy를 푼다.
          _cancelBuyTimeout();
          busyNotifier.value = false;
          break;
        case PurchaseStatus.pending:
          // 결제 대기 중 — 스토어에서 결과가 오면 다시 온다.
          break;
        case PurchaseStatus.canceled:
          errorNotifier.value = '구매를 취소했어요.';
          _completeRestore(false);
          _cancelBuyTimeout();
          busyNotifier.value = false;
          break;
        case PurchaseStatus.error:
          // 스토어 원문(영문·코드)을 그대로 보여주지 않고 고정 문구로 안내한다.
          errorNotifier.value = '구매에 실패했어요. 다시 시도해 주세요.';
          _completeRestore(false);
          _cancelBuyTimeout();
          busyNotifier.value = false;
          break;
      }
      if (purchase.pendingCompletePurchase) {
        // 구매 확인(acknowledge). 실패하면 재시도하고, 그래도 안 되면
        // 다음 앱 시작 때 복원으로 다시 확인한다 (2026-11-16).
        unawaited(_completePurchase(purchase));
      }
    }
  }

  /// 복원 대기 중이면 실패로 완료한다. 취소·오류 분기에서 쓴다.
  void _completeRestore(bool value) {
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete(value);
    }
  }

  /// 구매 확인을 최대 2번 시도한다. 실패해도 예외를 던지지 않는다 —
  /// 미확인 구매는 다음 앱 시작 때 restorePurchases()로 다시 흘러온다.
  Future<void> _completePurchase(PurchaseDetails purchase) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await InAppPurchase.instance.completePurchase(purchase);
        return;
      } catch (e) {
        debugPrint('구매 확인 실패 (시도 ${attempt + 1}/2): $e');
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    debugPrint('구매 확인 최종 실패 — 다음 앱 시작 시 복원으로 재시도: '
        '${purchase.productID}');
  }

  /// 테스트용 — 구매 스트림 이벤트를 직접 주입한다.
  /// (실기기에서는 purchaseStream 리스너가 _onPurchaseUpdate를 부른다.)
  @visibleForTesting
  void handlePurchaseUpdateForTest(List<PurchaseDetails> purchases) {
    _onPurchaseUpdate(purchases);
  }

  @visibleForTesting
  void resetForTest() {
    _subscription?.cancel();
    _subscription = null;
    _cancelBuyTimeout();
    _product = null;
    _rawPrice = null;
    _currencyCode = null;
    _initialized = false;
    _productsLoaded = false;
    _restoreCompleter = null;
    _ownedPurchaseSeen = false;
    priceNotifier.value = fallbackPrice;
    busyNotifier.value = false;
    productsAvailableNotifier.value = false;
    productsCheckedNotifier.value = false;
    errorNotifier.value = null;
  }

  /// 테스트용 가격 주입 — 스토어 상품 정보 대신 원화 금액·통화·표시가를 둔다.
  @visibleForTesting
  void setPriceForTest({
    required double rawPrice,
    required String currencyCode,
    required String displayPrice,
  }) {
    _rawPrice = rawPrice;
    _currencyCode = currencyCode;
    priceNotifier.value = displayPrice;
  }
}
