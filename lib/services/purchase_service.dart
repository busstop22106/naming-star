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
class PurchaseService {
  static final PurchaseService instance = PurchaseService._internal();
  PurchaseService._internal();

  /// Play Console에 등록할 비소모성 상품 ID.
  static const String adFreeProductId = 'adfree_lifetime_4900';

  /// 스토어 가격을 못 받았을 때 보여주는 문구.
  static const String fallbackPrice = '₩4,900';

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

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _product;
  bool _initialized = false;
  bool _productsLoaded = false;

  /// 앱 시작 시 1회: 권한 저장값을 읽고, 스토어 구매 내역을 복원한다.
  /// 스토어에 닿지 못해도 앱 진입을 막지 않는다 (예외는 삼킨다).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await AdFreeService.instance.ensureLoaded();
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) return;
      _subscription = InAppPurchase.instance.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (_) {},
      );
      await refreshProducts();
      // 재설치·기기 변경 후에도 스토어 계정 기준으로 권한을 되살린다.
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      // 스토어 연결 실패는 광고 제거 없이 계속 가는 것으로 처리한다.
    }
  }

  /// 상품 정보를 (다시) 조회한다. 스토어 가격을 받아오면 price에 반영한다.
  Future<void> refreshProducts() async {
    if (_productsLoaded) return;
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
      priceNotifier.value = _product!.price;
      productsAvailableNotifier.value = true;
      _productsLoaded = true;
    } catch (_) {
      productsAvailableNotifier.value = false;
    } finally {
      productsCheckedNotifier.value = true;
    }
  }

  /// 평생 광고 제거를 구매한다. 버튼을 눌렀을 때만 호출할 것.
  /// 결제 시트 실행 여부를 반환한다 (실제 구매 완료는 purchaseStream으로 온다).
  Future<bool> buyAdFree() async {
    if (isBusy) return false;
    busyNotifier.value = true;
    try {
      await refreshProducts();
      final product = _product;
      if (product == null) {
        errorNotifier.value = '상품 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
        return false;
      }
      final launched = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!launched) {
        errorNotifier.value = '결제를 시작하지 못했어요. 잠시 후 다시 시도해 주세요.';
        return false;
      }
      return true;
    } catch (_) {
      errorNotifier.value = '결제를 시작하지 못했어요. 잠시 후 다시 시도해 주세요.';
      return false;
    } finally {
      busyNotifier.value = false;
    }
  }

  /// 스토어 구매 내역을 복원한다. 복원된 구매가 있으면 true.
  /// 복원할 구매가 없으면 false (10초 안에 스트림 응답이 없으면 타임아웃).
  Future<bool> restore() async {
    if (AdFreeService.instance.isAdFree) return true;
    if (isBusy) return false;
    busyNotifier.value = true;
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        errorNotifier.value = '스토어에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.';
        return false;
      }
      final completer = Completer<bool>();
      _restoreCompleter = completer;
      await InAppPurchase.instance.restorePurchases();
      final restored = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      _restoreCompleter = null;
      return restored;
    } catch (_) {
      errorNotifier.value = '복원하지 못했어요. 잠시 후 다시 시도해 주세요.';
      return false;
    } finally {
      busyNotifier.value = false;
    }
  }

  Completer<bool>? _restoreCompleter;

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != adFreeProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          unawaited(AdFreeService.instance.setAdFree(true));
          if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
            _restoreCompleter!.complete(true);
          }
          break;
        case PurchaseStatus.pending:
          // 결제 대기 중 — 스토어에서 결과가 오면 다시 온다.
          break;
        case PurchaseStatus.canceled:
          errorNotifier.value = '구매를 취소했어요.';
          break;
        case PurchaseStatus.error:
          errorNotifier.value =
              purchase.error?.message ?? '구매에 실패했어요. 다시 시도해 주세요.';
          break;
      }
      if (purchase.pendingCompletePurchase) {
        unawaited(InAppPurchase.instance.completePurchase(purchase));
      }
    }
  }

  @visibleForTesting
  void resetForTest() {
    _subscription?.cancel();
    _subscription = null;
    _product = null;
    _initialized = false;
    _productsLoaded = false;
    _restoreCompleter = null;
    priceNotifier.value = fallbackPrice;
    busyNotifier.value = false;
    productsAvailableNotifier.value = false;
    productsCheckedNotifier.value = false;
    errorNotifier.value = null;
  }
}
