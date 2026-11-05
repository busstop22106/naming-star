import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// 이름 공개 전 기대감 연출 화면 (이름 짓기 → 결과 사이)
///
/// 별 캐릭터가 뾰로롱 튀어 오르고 반짝이가 퍼진 뒤 결과 화면으로 넘어가요.
/// 화면을 탭하면 바로 결과로 이동합니다.
///
/// ※ 출시 후 전면 광고를 넣을 자리가 바로 이곳이에요.
///   광고를 붙일 때는 이 화면에서 광고를 표시한 뒤 _go()를 호출하도록
///   교체하면 됩니다.
class RevealScreen extends StatefulWidget {
  final WidgetBuilder nextBuilder;

  /// 별 아래에 뜨는 문구. 기본값은 이름 짓기용.
  /// 이름 분석·가족 궁합에서는 각 흐름에 맞는 문구를 넘긴다.
  final String message;

  /// 문구 아래에 뜨는 작은 부제. 기본값은 이름 짓기용.
  final String subMessage;

  const RevealScreen({
    super.key,
    required this.nextBuilder,
    this.message = '작명별이 이름을 고르고 있어요',
    this.subMessage = '두근두근, 어떤 이름이 나올까요?',
  });

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _moved = false;

  // 반짝이 파티클 배치 (각도·거리·크기 고정값)
  static const _particles = <(double angle, double dist, double size)>[
    (0.1, 120, 20),
    (0.9, 150, 15),
    (1.7, 110, 24),
    (2.5, 145, 14),
    (3.3, 125, 21),
    (4.1, 155, 16),
    (4.9, 115, 19),
    (5.7, 140, 15),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _go();
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go() {
    if (_moved || !mounted) return;
    _moved = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: widget.nextBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _go,
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _ctrl.value;
              // 별: elastic으로 통통 튀며 등장
              final popT = const Interval(0.0, 0.6,
                      curve: Curves.elasticOut)
                  .transform(t.clamp(0.0, 1.0));
              final scale = popT <= 0 ? 0.001 : popT;
              // 뾰로롱 흔들림 (점점 잦아듦)
              final wobble =
                  math.sin(t * math.pi * 5) * 0.14 * (1 - t);
              final rise = (1 - popT) * 46;
              // 문구 페이드인
              final textT = const Interval(0.35, 0.65,
                      curve: Curves.easeOut)
                  .transform(t.clamp(0.0, 1.0));
              // 파티클: 중간 구간에 퍼지며 사라짐
              final pT = t <= 0.3
                  ? 0.0
                  : ((t - 0.3) / 0.55).clamp(0.0, 1.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 340,
                    height: 340,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (final (angle, dist, size) in _particles)
                          Transform.translate(
                            offset: Offset(
                              math.cos(angle) * dist * pT,
                              math.sin(angle) * dist * pT,
                            ),
                            child: Opacity(
                              opacity: (1 - pT) * (pT > 0 ? 1 : 0),
                              child: Icon(
                                Icons.star_rounded,
                                size: size,
                                color: AppTheme.gold
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        Transform.translate(
                          offset: Offset(0, rise),
                          child: Transform.rotate(
                            angle: wobble,
                            child: Transform.scale(
                              scale: scale,
                              child: Image.asset(
                                'assets/icon/splash-star.png',
                                width: 190,
                                height: 190,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.star_rounded,
                                  size: 150,
                                  color: AppTheme.gold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: textT,
                    child: Column(
                      children: [
                        Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subMessage,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.sub),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
