import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// 출생 시간 표기 — 24시간 숫자만 쓰면 오전/오후를 헷갈린다.
/// 사주에서는 오전 3시 30분(인시)과 오후 3시 30분(신시)이 완전히 다르다.
String formatTimeOfDay(TimeOfDay t) {
  final period = t.hour < 12 ? '오전' : '오후';
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$period $hour12시 ${t.minute}분';
}

/// 종합 점수 링
class ScoreRing extends StatelessWidget {
  final double score;
  final double size;
  final double strokeWidth;
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 120,
    this.strokeWidth = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(score, strokeWidth),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: size * 0.30,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              Text(
                AppTheme.scoreWord(score),
                style: TextStyle(
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.scoreColor(score),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double score;
  final double strokeWidth;
  _RingPainter(this.score, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final bg = Paint()
      ..color = AppTheme.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final color = AppTheme.scoreColor(score);
    final fg = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.65), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (score / 100),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.score != score;
}

/// 차원별 점수 바
class DimensionBar extends StatelessWidget {
  final String title;
  final double score;
  final String grade;
  const DimensionBar({
    super.key,
    required this.title,
    required this.score,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.scoreColor(score);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 74,
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 9,
                    backgroundColor: AppTheme.line,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 76,
                child: Text(
                  '${score.toStringAsFixed(0)} · $grade',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 섹션 카드 — 아이콘은 둥근 칩 안에 넣어 귀엽게
class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // 스크롤 버벅임 방지: 섹션별 래스터 캐시를 만들어 스크롤 중 재그리기를 막는다.
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppTheme.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.sub)),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// 별 친구 히어로 — 홈 상단 등에서 별 이미지와 함께 환영 문구를 보여준다
class StarHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final double imageSize;
  const StarHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageSize = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3D6), Color(0xFFEDE8FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/icon/splash-star.png',
            width: imageSize,
            height: imageSize,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.star, size: 64, color: AppTheme.gold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.sub, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 빈 상태 — 별 친구와 함께 따뜻하게 안내한다
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/splash-star.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.star, size: 72, color: AppTheme.gold),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.sub, height: 1.5)),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 등급 뱃지
class GradeChip extends StatelessWidget {
  final String label;
  final Color color;
  const GradeChip(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// 오행 색상
Color elementColor(String e) {
  switch (e) {
    case '목':
      return const Color(0xFF43A06B);
    case '화':
      return const Color(0xFFE05D5D);
    case '토':
      return const Color(0xFFC98A1B);
    case '금':
      return const Color(0xFF8A93A6);
    case '수':
      return const Color(0xFF4A7FB5);
    default:
      return AppTheme.sub;
  }
}

/// 오행 칩
class ElementChip extends StatelessWidget {
  final String element;
  const ElementChip(this.element, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = elementColor(element);
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(element,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: c)),
    );
  }
}

/// 성별 선택 버튼 (이름 짓기·이름 분석 공용)
class GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const GenderButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : AppTheme.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : AppTheme.sub),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? color : AppTheme.sub)),
          ],
        ),
      ),
    );
  }
}
