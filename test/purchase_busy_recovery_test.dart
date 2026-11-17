import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:jakmyeongbyeol/services/purchase_service.dart';

/// 구매 스트림 합성 이벤트로 busy가 풀리는지 검증한다.
/// 배경: Play가 결제 실패·취소를 알릴 때 구매 목록이 비어 있으면
/// 플러그인(in_app_purchase_android 0.5.5)이 productID ''인 합성
/// 이벤트를 만든다. 예전 코드는 상품 ID가 안 맞는다고 이 이벤트를
/// 걸러버려서 busy가 영원히 안 풀리고 설정 버튼이 무한 뺑뺑이가 됐다
/// (2026-11-17 실기기 재현: 1위 다이얼로그 결제 시도 뒤 Play가
/// '구입하려는 항목을 찾을 수 없습니다'를 띄우고 돌아왔는데도 busy 유지).
void main() {
  tearDown(() {
    PurchaseService.instance.resetForTest();
  });

  /// 플러그인이 만드는 합성 이벤트: 구매 목록이 비어 있을 때
  /// productID ''·status error/canceled인 PurchaseDetails.
  PurchaseDetails synthetic(PurchaseStatus status) {
    return PurchaseDetails(
      purchaseID: '',
      productID: '',
      status: status,
      transactionDate: null,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'google_play',
      ),
    );
  }

  test('합성 오류 이벤트가 오면 busy가 풀리고 실패 메시지가 뜬다', () {
    final service = PurchaseService.instance;
    service.busyNotifier.value = true; // 구매 진행 중
    service.handlePurchaseUpdateForTest([synthetic(PurchaseStatus.error)]);
    expect(service.isBusy, isFalse);
    expect(service.errorNotifier.value, '구매에 실패했어요. 다시 시도해 주세요.');
  });

  test('합성 취소 이벤트가 오면 busy가 풀리고 취소 메시지가 뜬다', () {
    final service = PurchaseService.instance;
    service.busyNotifier.value = true; // 구매 진행 중
    service.handlePurchaseUpdateForTest([synthetic(PurchaseStatus.canceled)]);
    expect(service.isBusy, isFalse);
    expect(service.errorNotifier.value, '구매를 취소했어요.');
  });

  test('구매 중이 아닐 때 합성 오류 이벤트는 무시한다 (뜬금없는 스낵바 방지)', () {
    final service = PurchaseService.instance;
    service.handlePurchaseUpdateForTest([synthetic(PurchaseStatus.error)]);
    expect(service.isBusy, isFalse);
    expect(service.errorNotifier.value, isNull);
  });

  test('합성 완료 이벤트는 busy만 풀고 광고 제거 권한은 켜지 않는다', () {
    final service = PurchaseService.instance;
    service.busyNotifier.value = true; // 구매 진행 중
    service.handlePurchaseUpdateForTest([synthetic(PurchaseStatus.purchased)]);
    // 합성 완료는 실제 구매 객체가 없어 권한을 켤 수 없으니 busy만 푼다.
    expect(service.isBusy, isFalse);
    expect(service.errorNotifier.value, isNull);
  });
}
