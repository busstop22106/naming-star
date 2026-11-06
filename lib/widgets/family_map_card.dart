import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine/compat.dart';
import '../theme.dart';

/// ── 가족 궁합 지도 ──
/// 가운데 아기를 두고 가족 구성원을 주변에 배치해 선으로 연결해요.
/// 가장 잘 맞는 구성원과는 선이 굵어지고, 선 위에서 하트가 두근두근 뛰어요.
///
/// 원래 compat_screen.dart 안에 있던 _FamilyMapCard(약 190줄)를
/// 150줄 분리 규칙에 따라 위젯으로 분리한 것이다.
/// 궁합 핑크·성별 기호색은 AppTheme 토큰으로 통일한다
/// (작은 글자에는 pinkDark·boyDark·girlDark 같은 진한 변형 사용).
class FamilyMapCard extends StatefulWidget {
  final FamilyCompatResult result;
  const FamilyMapCard({super.key, required this.result});

  @override
  State<FamilyMapCard> createState() => _FamilyMapCardState();
}

class _FamilyMapCardState extends State<FamilyMapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// 구성원 수별 배치 각도 (도, 0=오른쪽, 시계 방향, -90=위)
  List<double> _angles(int n) {
    switch (n) {
      case 1:
        return [-90];
      case 2:
        return [-135, -45]; // 좌상단 · 우상단
      case 3:
        return [-135, -45, 90]; // 좌상단 · 우상단 · 하단
      case 4:
        return [-135, -45, 45, 135]; // 네 모서리
      default:
        return List.generate(n, (i) => -150 + i * 360 / n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final members = result.members;
    final bestLabel = result.best.label;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('누구와 가장 잘 맞을까?',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                // 지도 상단 빈 공간이 커 보여서 높이를 줄였다.
                // (300 → 260, 아래쪽 노드가 박스 안에 들어가는 범위에서)
                const h = 260.0;
                final center = Offset(w / 2, h / 2);
                // 노드를 카드 가장자리에서 조금 띄우되, 점수 글자가
                // 가운데 별 원에 닿지 않게 가로 반경은 여유 있게 둔다.
                final rx = w / 2 - 46;
                const ry = h / 2 - 62;
                final angles = _angles(members.length);
                final points = <Offset>[
                  for (var i = 0; i < members.length; i++)
                    Offset(
                      center.dx +
                          rx * math.cos(angles[i] * math.pi / 180),
                      center.dy +
                          ry * math.sin(angles[i] * math.pi / 180),
                    ),
                ];
                final bestIdx =
                    members.indexWhere((m) => m.label == bestLabel);
                return SizedBox(
                  width: w,
                  height: h,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      // 두근두근: 한 주기에 두 번 뛰는 심장 박동 곡선
                      final v = _pulse.value;
                      final s = math.sin(v * math.pi * 4);
                      final beat = s > 0 ? math.pow(s, 3).toDouble() : 0.0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 연결선
                          CustomPaint(
                            size: Size(w, h),
                            painter: _MapLinesPainter(
                              center: center,
                              points: points,
                              scores: members
                                  .map((m) => m.total)
                                  .toList(),
                              bestIndex: bestIdx,
                              beat: beat,
                            ),
                          ),
                          // 가운데 아기는 선 다음, 하트·구성원보다 먼저 그린다.
                          // 맨 나중에 그리면 아기 원이 엄마 점수 글자 왼쪽 끝과
                          // 최고 궁합 하트 일부를 덮어 가려 보였다.
                          Positioned(
                            left: center.dx - 26,
                            top: center.dy - 26,
                            child: const _BabyNode(),
                          ),
                          // 최고 궁합 선을 따라 흐르는 작은 하트
                          for (final phase in [0.0, 0.5])
                            _flowingHeart(points[bestIdx], center,
                                (v + phase) % 1.0),
                          // 최고 궁합 선 중간의 뛰는 하트
                          Positioned(
                            left: (points[bestIdx].dx + center.dx) / 2 -
                                10,
                            top: (points[bestIdx].dy + center.dy) / 2 -
                                10,
                            child: Transform.scale(
                              scale: 1 + 0.25 * beat,
                              child: Icon(
                                Icons.favorite,
                                size: 20,
                                color: AppTheme.pink,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.pink
                                        .withValues(alpha: 0.33),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 구성원 노드
                          for (var i = 0; i < members.length; i++)
                            Positioned(
                              left: points[i].dx - 40,
                              top: points[i].dy - 26,
                              child: _MemberNode(
                                member: members[i],
                                isBest: i == bestIdx,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '이 이름은 ${result.best.label}와 가장 잘 맞아요',
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 최고 궁합 선 위를 아기 쪽으로 흘러가는 작은 하트
  Widget _flowingHeart(Offset from, Offset to, double phase) {
    final pos = Offset(
      from.dx + (to.dx - from.dx) * phase,
      from.dy + (to.dy - from.dy) * phase,
    );
    final opacity = math.sin(phase * math.pi).clamp(0.0, 1.0) * 0.9;
    return Positioned(
      left: pos.dx - 8,
      top: pos.dy - 8,
      child: Opacity(
        opacity: opacity,
        child: const Icon(Icons.favorite,
            size: 16, color: AppTheme.pinkLight),
      ),
    );
  }
}

/// 연결선 페인터 — 최고 궁합 선은 굵고 진하게, 박동에 맞춰 살짝 굵어져요
class _MapLinesPainter extends CustomPainter {
  final Offset center;
  final List<Offset> points;
  final List<double> scores;
  final int bestIndex;
  final double beat;

  _MapLinesPainter({
    required this.center,
    required this.points,
    required this.scores,
    required this.bestIndex,
    required this.beat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length; i++) {
      final isBest = i == bestIndex;
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (isBest) {
        paint.color = AppTheme.pink;
        paint.strokeWidth = 4.6 + beat * 1.6;
      } else {
        paint.color = AppTheme.mapLine;
        paint.strokeWidth = 1.6 + (scores[i] / 100) * 1.8;
      }
      canvas.drawLine(center, points[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapLinesPainter old) =>
      old.beat != beat ||
      old.bestIndex != bestIndex ||
      old.points != points;
}

/// 구성원 노드 (원 안에 띠 동물, 아래에 이름·점수)
class _MemberNode extends StatelessWidget {
  final MemberCompat member;
  final bool isBest;
  const _MemberNode({required this.member, required this.isBest});

  @override
  Widget build(BuildContext context) {
    final branch = member.memberSaju.year.branch;
    final emoji = zodiacEmojis[branch] ?? '⭐';
    final zodiac = zodiacNames[branch] ?? '';
    final symbol = genderSymbolForRole(member.label);
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isBest ? AppTheme.pinkSoft : AppTheme.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: isBest
                    ? AppTheme.pink
                    : AppTheme.primary.withValues(alpha: 0.25),
                width: isBest ? 2.5 : 1.5,
              ),
              boxShadow: isBest
                  ? [
                      BoxShadow(
                        color: AppTheme.pink.withValues(alpha: 0.25),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 25),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  member.label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 역할 이름 옆 성별 기호 (동생은 알 수 없어 표시 안 함)
              // 예전에는 테마 boy/girl과 다른 파랑·분홍(#3B82C4/#E85D75)을
              // 직접 썼는데, 테마의 진한 변형(boyDark/girlDark)으로 통일했다.
              if (symbol.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: symbol == '♂'
                        ? AppTheme.boyDark
                        : AppTheme.girlDark,
                  ),
                ),
              ],
              if (isBest) ...[
                const SizedBox(width: 2),
                const Icon(Icons.favorite,
                    size: 11, color: AppTheme.pink),
              ],
            ],
          ),
          Text(
            '${member.total.toStringAsFixed(0)}점 · $zodiac',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBest ? FontWeight.w700 : FontWeight.w400,
              // 최고 궁합 점수 핑크 #FF5C7A는 흰 배경 2.97:1로 AA 미달이라
              // 진한 pinkDark(4.62:1)로 바꿨다.
              color: isBest ? AppTheme.pinkDark : AppTheme.sub,
            ),
          ),
        ],
      ),
    );
  }
}

/// 가운데 아기 노드
class _BabyNode extends StatelessWidget {
  const _BabyNode();

  @override
  Widget build(BuildContext context) {
    // 별 원은 구성원 원(52)과 같은 크기로 맞춘다. 예전 68짜리는
    // 옆 구성원의 점수 글자 왼쪽을 덮어 가려 보였다.
    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.gold, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.19),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/splash-star.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.star_rounded,
                  size: 30,
                  color: AppTheme.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
