import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/purchase_service.dart';

/// 평생 광고 제거 구매 버튼 라벨.
///
/// - 정가(₩4,900)일 때: 기존 문구 그대로
///   ('평생 광고 없이 사용 · ₩4,900').
/// - 스토어 가격이 정가보다 낮을 때(출시 특가 등): 정가에 취소선 두 줄을
///   긋고 화살표 뒤에 할인가를 보여준다.
///   ('평생 광고 없이 사용 · ₩4,900 → ₩1,900').
/// Play 결제창 자체에는 취소선이 안 뜨고(플러그인 한계),
/// 이 표시는 앱 다이얼로그·설정 화면에서만 보인다.
/// 콘솔 가격을 내리지 않으면 할인 표시는 절대 안 뜬다. (2026-11-17)
///
/// Text.rich + WidgetSpan은 쓰지 않는다. 1위 확인 다이얼로그에서
/// WidgetSpan이 들어가면 팝업이 안 뜨고 배경만 딤 처리되는 버그가
/// 실기기에서 재현됐다 (2026-11-17). 대신 Wrap으로 각 부분을
/// 나란히 배치한다.
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
          return Text('$prefix${service.price}');
        }
        // 정가는 살짝 흐리게 + 취소선 두 줄, 화살표 뒤에 할인가.
        // 할인율은 표시하지 않는다. '(기간 할인 중)'은 버튼이
        // 2줄로 줄바꿈돼서 뺐다 (2026-11-17).
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(prefix),
            const DoubleStrikeText(PurchaseService.regularPriceText),
            Text(' → ${service.price}'),
          ],
        );
      },
    );
  }
}

/// 텍스트 위에 취소선 두 줄을 긋는 인라인 위젯.
///
/// Flutter의 TextDecoration.lineThrough은 한 줄뿐이라
/// 두 줄 취소선은 직접 그린다. (2026-11-17)
/// 선 색은 텍스트 색과 동일하게(흐림 포함) 맞춘다 — 빨간 선은
/// 금색 버튼 위에서 안 보이고 어색하다는 실기기 피드백이 있었다.
/// 정가처럼 '할인 전 가격'임을 보여줄 때 쓰며, 글자는
/// 주변 글자보다 살짝 흐리게(75%) 표시한다.
class DoubleStrikeText extends StatelessWidget {
  const DoubleStrikeText(this.text, {super.key});

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
    // 선 색 = 텍스트 색 (흐림 포함). (2026-11-17)
    final muted = baseColor.withValues(alpha: 0.75);
    final lineThickness = math.max(1.0, scaledFontSize * 0.07);
    final lineGap = scaledFontSize * 0.14;
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
              // 줄 높이 정중앙은 숫자(캡 높이) 정중앙보다 살짝 아래라,
              // 글자 정중앙에 오게 위로 살짝 올린다.
              offset: Offset(0, -scaledFontSize * 0.10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: lineThickness, color: muted),
                  SizedBox(height: lineGap),
                  Container(height: lineThickness, color: muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
