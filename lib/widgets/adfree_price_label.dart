import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/purchase_service.dart';

/// 평생 광고 제거 구매 버튼 라벨.
///
/// - 정가(₩4,900)일 때: 기존 문구 그대로
///   ('평생 광고 없이 사용 · ₩4,900').
/// - 스토어 가격이 정가보다 낮을 때(출시 특가 등): 정가에 빨간 취소선 한 줄을
///   긋고 화살표 뒤에 할인가와 '(기간 할인 중)'을 보여준다.
///   ('평생 광고 없이 사용 · ₩4,900 → ₩1,900 (기간 할인 중)').
/// Play 결제창 자체에는 취소선이 안 뜨고(플러그인 한계),
/// 이 표시는 앱 다이얼로그·설정 화면에서만 보인다.
/// 콘솔 가격을 내리지 않으면 할인 표시는 절대 안 뜬다. (2026-11-17)
class AdFreePriceLabel extends StatelessWidget {
  const AdFreePriceLabel({super.key, required this.prefix});

  /// 버튼 문구 앞부분. 1위 확인 다이얼로그·설정 화면 모두
  /// '평생 광고 없이 사용'을 넘긴다 (문구 통일, 2026-11-17).
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
          return Text(
            '$prefix${service.price}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }
        // 정가는 살짝 흐리게 + 빨간 취소선 한 줄, 화살표 뒤에
        // 할인가와 '(기간 할인 중)'. 할인율은 표시하지 않는다 (2026-11-17).
        // 라벨이 길어 좁은 화면·큰 글씨에서 3줄로 늘어나는 것을 막는다.
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: prefix),
              const WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: RedStrikeText(PurchaseService.regularPriceText),
              ),
              TextSpan(text: ' → ${service.price} (기간 할인 중)'),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// 텍스트 위에 빨간 취소선 한 줄을 긋는 인라인 위젯.
///
/// Flutter의 TextDecoration.lineThrough은 폰트 기준이라 숫자의
/// 정중앙보다 살짝 아래에 그려지고 색상도 글자색을 따라가서,
/// 글자 정중앙에 빨간 선을 직접 그린다. (2026-11-17)
/// 정가처럼 '할인 전 가격'임을 보여줄 때 쓰며, 글자는
/// 주변 글자보다 살짝 흐리게(75%) 표시한다.
/// 빨간 선은 진한 빨강(#D32F2F)으로, 금색 버튼·어두운 다이얼로그
/// 둘 다에서 보이게 한다. 밝은 빨강(#FF5252)은 금색 위에서
/// 거의 안 보인다 (오푸스 리뷰, 2026-11-17).
class RedStrikeText extends StatelessWidget {
  const RedStrikeText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final fontSize = style.fontSize ?? 14.0;
    // 큰 글씨 접근성 설정에서도 취소선 위치·두께가 따라가게
    // 텍스트 스케일을 반영한다. (오푸스 리뷰, 2026-11-17)
    final scaledFontSize = MediaQuery.textScalerOf(context).scale(fontSize);
    final baseColor =
        style.color ?? Theme.of(context).colorScheme.onSurface;
    final muted = baseColor.withValues(alpha: 0.75);
    // 줄 높이 정중앙은 숫자(캡 높이) 정중앙보다 살짝 아래라,
    // 글자 정중앙에 오게 위로 살짝 올린다. '₩4,900'은 숫자와
    // ₩ 기호라 로보토 기준 0.10이 적절하다 (오푸스 리뷰, 2026-11-17).
    const red = Color(0xFFD32F2F);
    final lineThickness = math.max(2.0, scaledFontSize * 0.14);
    return Semantics(
      // 스크린 리더에 취소된 가격임을 전달한다. (오푸스 리뷰, 2026-11-17)
      label: '정가 $text, 할인 전 가격',
      excludeSemantics: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(text, style: TextStyle(color: muted)),
          Positioned(
            left: 0,
            right: 0,
            child: Transform.translate(
              offset: Offset(0, -scaledFontSize * 0.10),
              child: Container(height: lineThickness, color: red),
            ),
          ),
        ],
      ),
    );
  }
}
