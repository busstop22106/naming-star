import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine/compat.dart';
import '../engine/saju.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 받침 유무에 따라 '과의/와의' 선택 (예: 형과의, 아빠와의)
String _withParticle(String label) {
  if (label.isEmpty) return label;
  final code = label.codeUnitAt(label.length - 1);
  if (code >= 0xAC00 && code <= 0xD7A3) {
    final hasJong = (code - 0xAC00) % 28 != 0;
    return hasJong ? '$label과의' : '$label와의';
  }
  return '$label와의';
}

/// 가족 이름 궁합 결과 화면
class CompatScreen extends StatelessWidget {
  final String babyFullName; // 성+이름 (한글)
  final String babyHanjaName; // 이름 한자 (순우리말이면 '')
  final bool isPureKorean;
  final FamilyCompatResult result;

  const CompatScreen({
    super.key,
    required this.babyFullName,
    required this.babyHanjaName,
    required this.isPureKorean,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final best = result.best;
    return Scaffold(
      appBar: AppBar(title: const Text('가족 이름 궁합')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          // ── 종합 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    babyHanjaName.isEmpty
                        ? babyFullName
                        : '$babyFullName ($babyHanjaName)',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPureKorean
                        ? '순우리말 이름 · 발음오행 기준'
                        : '이름 오행 ${result.nameElements.join(' · ')}',
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.sub),
                  ),
                  const SizedBox(height: 14),
                  ScoreRing(score: result.total, size: 128),
                  const SizedBox(height: 10),
                  Text(
                    result.grade,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.scoreColor(result.total)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.members.length > 1
                        ? '가장 잘 맞는 구성원 · ${best.label} ${best.total.toStringAsFixed(0)}점'
                        : '${best.label} ${best.total.toStringAsFixed(0)}점',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.sub,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          // ── 가족 궁합 지도 ──
          if (result.members.length > 1) ...[
            const SizedBox(height: 12),
            _FamilyMapCard(result: result),
          ],
          const SizedBox(height: 12),
          // ── 구성원별 상세 ──
          for (var i = 0; i < result.members.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _MemberCard(compat: result.members[i]),
          ],
          const SizedBox(height: 12),
          // ── 가족 오행 균형 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('가족 오행 균형',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('가족 구성원 사주 합산에 아기 이름의 오행을 더한 분포예요.',
                      style: TextStyle(fontSize: 12, color: AppTheme.sub)),
                  const SizedBox(height: 12),
                  for (final e in ['목', '화', '토', '금', '수'])
                    _ElementRow(
                      element: e,
                      before: result.familyCountsBefore[e] ?? 0,
                      after: result.familyCountsAfter[e] ?? 0,
                    ),
                  const SizedBox(height: 10),
                  Text(result.balanceNote,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('다른 이름으로 비교해보기'),
          ),
          const SizedBox(height: 10),
          const Text(
            '구성원 정보는 그대로 유지돼요. 이름만 바꿔서 다시 분석하면 후보끼리 비교할 수 있어요.',
            style: TextStyle(fontSize: 11, color: AppTheme.sub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            '띠 궁합은 출생연도로 정해지는 부분이라 이름으로 바뀌지 않아요. 전체 점수는 간이 만세력으로 계산한 참고용이며, 정확한 감정은 전문가 상담을 권장해요.',
            style: TextStyle(fontSize: 11, color: AppTheme.sub, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// ── 가족 궁합 지도 ──
/// 가운데 아기를 두고 가족 구성원을 주변에 배치해 선으로 연결해요.
/// 가장 잘 맞는 구성원과는 선이 굵어지고, 선 위에서 하트가 두근두근 뛰어요.
class _FamilyMapCard extends StatefulWidget {
  final FamilyCompatResult result;
  const _FamilyMapCard({required this.result});

  @override
  State<_FamilyMapCard> createState() => _FamilyMapCardState();
}

class _FamilyMapCardState extends State<_FamilyMapCard>
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
        return [-145, -35]; // 좌상단 · 우상단
      case 3:
        return [-145, -35, 90]; // 좌상단 · 우상단 · 하단
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
            const SizedBox(height: 2),
            const Text('가장 잘 맞는 구성원과는 하트가 두근두근 뛰어요.',
                style: TextStyle(fontSize: 12, color: AppTheme.sub)),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                const h = 300.0;
                final center = Offset(w / 2, h / 2);
                final rx = w / 2 - 54;
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
                              child: const Icon(
                                Icons.favorite,
                                size: 20,
                                color: Color(0xFFFF5C7A),
                                shadows: [
                                  Shadow(
                                    color: Color(0x55FF5C7A),
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
                          // 가운데 아기
                          Positioned(
                            left: center.dx - 44,
                            top: center.dy - 34,
                            child: const _BabyNode(),
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
            size: 16, color: Color(0xFFFF8FA5)),
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
        paint.color = const Color(0xFFFF5C7A);
        paint.strokeWidth = 4.6 + beat * 1.6;
      } else {
        paint.color = const Color(0xFFDCD4EE);
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
              color: isBest
                  ? const Color(0xFFFFE3E9)
                  : AppTheme.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: isBest
                    ? const Color(0xFFFF5C7A)
                    : AppTheme.primary.withValues(alpha: 0.25),
                width: isBest ? 2.5 : 1.5,
              ),
              boxShadow: isBest
                  ? const [
                      BoxShadow(
                        color: Color(0x40FF5C7A),
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
              if (isBest) ...[
                const SizedBox(width: 2),
                const Icon(Icons.favorite,
                    size: 11, color: Color(0xFFFF5C7A)),
              ],
            ],
          ),
          Text(
            '${member.total.toStringAsFixed(0)}점 · $zodiac',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBest ? FontWeight.w700 : FontWeight.w400,
              color: isBest ? const Color(0xFFFF5C7A) : AppTheme.sub,
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
    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.gold, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30F7B32B),
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
          const SizedBox(height: 3),
          const Text('아기',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// 구성원 한 명의 궁합 카드
class _MemberCard extends StatelessWidget {
  final MemberCompat compat;
  const _MemberCard({required this.compat});

  @override
  Widget build(BuildContext context) {
    final saju = compat.memberSaju;
    final zodiac = zodiacNames[saju.year.branch] ?? '';
    final elem100 = compat.elementScore / 40 * 100;
    final yong100 = compat.yongsinScore / 40 * 100;
    final zod100 = compat.zodiacScoreValue / 20 * 100;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${_withParticle(compat.label)} 궁합',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${compat.total.toStringAsFixed(0)}점',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.scoreColor(compat.total)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$zodiac · 일간 ${saju.dayMaster}(${elementNames[saju.dayElement]})'
              '${saju.yongsin != null ? ' · 용신 ${elementNames[saju.yongsin]}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppTheme.sub),
            ),
            const SizedBox(height: 8),
            DimensionBar(
                title: '오행 보완',
                score: elem100,
                grade: AppTheme.scoreWord(elem100)),
            DimensionBar(
                title: '용신 조화',
                score: yong100,
                grade: AppTheme.scoreWord(yong100)),
            DimensionBar(
                title: '띠 궁합',
                score: zod100,
                grade: AppTheme.scoreWord(zod100)),
            const SizedBox(height: 6),
            for (final d in compat.details)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('· ',
                        style: TextStyle(fontSize: 13, color: AppTheme.sub)),
                    Expanded(
                      child: Text(d,
                          style:
                              const TextStyle(fontSize: 13, height: 1.45)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 오행 분포 한 행 (이름 반영 전 → 후)
class _ElementRow extends StatelessWidget {
  final String element;
  final int before;
  final int after;
  const _ElementRow(
      {required this.element, required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    final added = after > before;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          ElementChip(element),
          const SizedBox(width: 10),
          Text(elementNames[element] ?? element,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$before개',
              style: const TextStyle(fontSize: 13, color: AppTheme.sub)),
          const Icon(Icons.arrow_right, size: 16, color: AppTheme.sub),
          Text(
            '$after개',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: added ? AppTheme.primary : AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
