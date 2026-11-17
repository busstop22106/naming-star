import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/purchase_service.dart';

/// 평생 광고 제거 구매 버튼 라벨.
///
/// - 정가(₩4,900)일 때: prefix + 스토어 가격 그대로.
///   (설정: '평생 광고 없이 사용 · ₩4,900', 1위 다이얼로그: '평생 광고 없이 사용 ₩4,900')
/// - 스토어 가격이 정가보다 낮을 때(출시 특가 등): 정가에 취소선 두 줄을
///   긋고 화살표 뒤에 할인가를 보여준다.
///   ('평생 광고 없이 사용 · ₩4,900 → ₩1,900').
/// Play 결제창 자체에는 취소선이 안 뜨고(플러그인 한계),
/// 이 표시는 앱 다이얼로그·설정 화면에서만 보인다.
/// 콘솔 가격을 내리지 않으면 할인 표시는 절대 안 뜬다. (2026-11-17)
///
/// Text.rich + WidgetSpan은 쓰지 않는다. 1위 확인 다이얼로그에서
/// WidgetSpan이 들어가면 팝업이 안 뜨고 배경만 딤 처리되는 버그가
/// 실기기에서 재현됐다 (2026-11-17). 유력한 원인은 AlertDialog가
/// 내부에서 IntrinsicWidth를 쓰는데 WidgetSpan이 들어가면
/// RenderParagraph의 intrinsic 크기 계산이 실패해 다이얼로그가
/// 크기 0으로 레이아웃되는 것(알려진 Flutter 이슈 계열)이다.
/// 대신 Wrap으로 각 부분을 나란히 배치한다.
class AdFreePriceLabel extends StatelessWidget {
  const AdFreePriceLabel({super.key, required this.prefix});

  /// 버튼 문구 앞부분. 1위 확인 다이얼로그·설정 화면 모두
  /// '평생 광고 없이 사용'을 넘긴다 (문구 통일, 2026-11-17).
  /// 설정은 뒤에 ' · '를, 다이얼로그는 뒤에 ' '를 붙인다.
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
        // 비할인·할인 모두 Wrap을 반환한다 — 위젯 타입이 바뀌면
        // 상품 정보 도착 시 버튼 크기가 점프할 수 있다 (오푸스 리뷰, 2026-11-17).
        if (!service.isDiscounted) {
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [Text('$prefix${service.price}')],
          );
        }
        // 정가는 살짝 흐리게 + 취소선 두 줄, 화살표 뒤에 할인가.
        // 할인율은 표시하지 않는다. '(기간 할인 중)'은 버튼이
        // 2줄로 줄바꿈돼서 뺐다 (2026-11-17).
        // 스크린 리더에는 '→'를 풀어서 한 문장으로 읽어준다.
        return Semantics(
          label:
              '평생 광고 없이 사용, 정가 ${PurchaseService.regularPriceText}에서 ${service.price}로 할인',
          excludeSemantics: true,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            // 줄바꿈 시 줄이 붙지 않게, 자식 사이 간격도 둔다.
            spacing: 4.0,
            runSpacing: 4.0,
            children: [
              Text(prefix),
              const DoubleStrikeText(PurchaseService.regularPriceText),
              // 선행 공백을 두면 줄바꿈 시 둘째 줄 머리에 공백이 보인다.
              // 간격은 Wrap.spacing으로 준다. (오푸스 리뷰, 2026-11-17)
              Text('→ ${service.price}'),
            ],
          ),
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
    // 선 색 = 텍스트 색 (흐림 포함). baseColor가 이미 반투명이면
    // alpha를 곱해서 더 흐리게 한다 (교체가 아니라 곱셈).
    final muted = baseColor.withValues(alpha: baseColor.a * 0.75);
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
          // 두 줄은 텍스트 정중앙을 기준으로 상하 대칭으로 긋는다.
          // Column을 Stack 정중앙에 두면 윗줄은 정중앙보다 살짝 위,
          // 아랫줄은 정중앙보다 살짝 아래에 온다.
          // (주의: Column 전체를 위로 올리면 안 된다 — 예전에는
          // 한 줄 취소선을 글자 정중앙에 맞추려고 -0.10만큼 올렸는데,
          // 두 줄에서는 아랫줄이 정중앙에 걸리고 윗줄만 너무 위로
          // 가서 대칭이 깨졌다. 2026-11-17 실기기 피드백.)
          Positioned(
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: lineThickness, color: muted),
                SizedBox(height: lineGap),
                Container(height: lineThickness, color: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
