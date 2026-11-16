import 'package:flutter/material.dart';

import '../services/purchase_service.dart';

/// 평생 광고 제거 구매 버튼 라벨.
///
/// - 정가(₩4,900)일 때: 기존 문구 그대로
///   ('평생 광고 없이 사용하기 · ₩4,900').
/// - 스토어 가격이 정가보다 낮을 때(출시 특가 등): 정가에 취소선을 긋고
///   할인가와 할인율을 함께 보여준다.
///   ('평생 광고 없이 사용하기 ₩4,900 ₩2,450 · 50% 할인').
/// Play 결제창 자체에는 취소선이 안 뜨고(플러그인 한계),
/// 이 표시는 앱 다이얼로그·설정 화면에서만 보인다.
/// 콘솔 가격을 내리지 않으면 할인 표시는 절대 안 뜬다.
class AdFreePriceLabel extends StatelessWidget {
  const AdFreePriceLabel({super.key, required this.prefix});

  /// 버튼 문구 앞부분. 1위 확인 다이얼로그는 '평생 광고 없이 보기 ',
  /// 설정 화면은 '평생 광고 없이 사용하기 · '를 넘긴다.
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final service = PurchaseService.instance;
    // 가격을 구독한다 — 상품 정보가 늦게 도착해도 라벨이 다시 그려진다.
    // (할인 여부는 rawPrice 기준으로 보되, priceNotifier가 같은 시점에
    // 갱신되므로 이 구독만으로 충분하다.) (2026-11-16)
    return ValueListenableBuilder<String>(
      valueListenable: service.priceNotifier,
      builder: (_, __, ___) {
        if (!service.isDiscounted) {
          return Text('$prefix${service.price}');
        }
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: prefix),
              const TextSpan(
                text: PurchaseService.regularPriceText,
                style: TextStyle(decoration: TextDecoration.lineThrough),
              ),
              TextSpan(
                text:
                    ' ${service.price} · ${service.discountPercent}% 할인',
              ),
            ],
          ),
        );
      },
    );
  }
}
