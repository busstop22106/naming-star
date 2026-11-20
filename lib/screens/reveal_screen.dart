import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/night_sky.dart';

/// 이름 공개 전 기대감 연출 화면 (이름 짓기 → 결과 사이)
///
/// 별 캐릭터가 뾰로롱 튀어 오르고 반짝이가 퍼진 뒤 결과 화면으로 넘어가요.
/// 화면을 탭해도 넘어가지 않는다 — 연출(2초)을 끝까지 봐야 결과로 간다
/// (2026-11-17).
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
  Timer? _timer;
  Timer? _safetyTimer;
  bool _moved = false;
  bool _timerDone = false;
  bool _animDone = false;

  void _checkGo() {
    if (_timerDone && _animDone) _go();
  }

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
      // 시스템에서 애니메이션을 꺼도('애니메이션 제거' 접근성 설정 등)
      // 이 연출은 끝까지 재생한다. 기본 동작(normal)이면 컨트롤러
      // 지속 시간이 0.05배(100ms)로 줄어 별이 정지된 이미지처럼
      // 보이는 문제가 갤럭시 S25+ 실기기에서 재현됐다 (2026-11-20).
      animationBehavior: AnimationBehavior.preserve,
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _animDone = true;
          _checkGo();
        }
      });
    _ctrl.forward();
    // 이동은 Timer(2초)와 애니메이션 완료 중 나중 시점에 한다.
    // 시스템 애니메이션 배율이 줄었거나 꺼져 있으면
    // AnimationController가 일찍 끝나 스플래시가 짧게 보이는 문제가
    // 갤럭시 S25+(OS 15) 실기기에서 재현됐다 (2026-11-20).
    // 반대로 배율이 2배면 애니메이션이 4초가 되므로, Timer만으로
    // 이동하면 연출이 중간에 끊긴다 (오푸스 리뷰, 2026-11-20).
    // 두 조건이 모두 찼을 때 이동하면 양쪽 다 커버된다.
    _timer = Timer(const Duration(milliseconds: 2000), () {
      _timerDone = true;
      _checkGo();
    });
    // 안전 타임아웃: 애니메이션 배율이 5배·10배면 연출이 10~20초까지
    // 늘어나고, 백그라운드 전환 등으로 완료 이벤트가 유실되면
    // 스플래시에 영원히 멈출 수 있다. 최대 4초면 무조건 넘어간다
    // (제미나이 리뷰, 2026-11-20). _go()의 _moved 가드가 중복
    // 이동을 막는다.
    _safetyTimer = Timer(const Duration(milliseconds: 4000), _go);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _safetyTimer?.cancel();
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
      body: Stack(
        children: [
            // 밤하늘 별빛 배경
            const Starfield(),
            Center(
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
        ],
      ),
    );
  }
}
