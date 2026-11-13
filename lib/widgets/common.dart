import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import 'night_sky.dart';

/// 출생 시간 표기 — 24시간 숫자만 쓰면 오전/오후를 헷갈린다.
/// 사주에서는 오전 3시 30분(인시)과 오후 3시 30분(신시)이 완전히 다르다.
String formatTimeOfDay(TimeOfDay t) {
  final period = t.hour < 12 ? '오전' : '오후';
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$period $hour12시 ${t.minute}분';
}

/// 토스트(스낵바) 쌓임 방지 — 새 토스트를 띄우기 전에 대기 중인 토스트를
/// 모두 비우고 즉시 새 토스트를 띄운다. 보관함 저장/삭제처럼 버튼을 연타하면
/// 오래된 토스트가 한참 뒤까지 줄줄이 뜨는 문제를 막는다.
/// 호출 전에 ScaffoldMessenger를 잡아두면 비동기 간격 뒤에도 안전하다.
void showSingleSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  SnackBarAction? action,
  Duration? duration,
  bool? persist,
}) {
  messenger.clearSnackBars();
  messenger.showSnackBar(SnackBar(
      content: Text(message),
      action: action,
      // 기본 4초가 아니라 명시한 시간 뒤에 사라지게 한다.
      // 보관함 삭제 토스트는 3초로 지정해 둔다.
      duration: duration ?? const Duration(seconds: 4),
      // 주의: 액션이 있으면 SnackBar의 persist 기본값이 true라
      // duration이 있어도 자동으로 안 사라진다. 시간 뒤에
      // 사라지게 하려면 persist: false를 명시해야 한다.
      persist: persist));
}

/// 종합 점수 링
///
/// [darkBackground]가 true면 헤더 카드 위처럼 진한 네이비 배경에 올리는
/// 경우라, 숫자·등급을 흰색 계열로 그리고 링 바탕도 흰색 반투명으로
/// 바꾼다. 기본(카드 위)에서는 숫자 ink·등급 scoreTextColor를 쓴다.
class ScoreRing extends StatelessWidget {
  final double score;
  final double size;
  final double strokeWidth;
  final bool darkBackground;
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 120,
    this.strokeWidth = 12,
    this.darkBackground = false,
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
            painter: _RingPainter(score, strokeWidth,
                darkBackground: darkBackground),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: size * 0.30,
                  fontWeight: FontWeight.w800,
                  // 카드 위에서는 ink(14.71:1), 진한 네이비 배경에서는 흰색(13.95:1).
                  color: darkBackground ? Colors.white : AppTheme.ink,
                ),
              ),
              Text(
                AppTheme.scoreWord(score),
                style: TextStyle(
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.w600,
                  // 진한 배경에서는 등급도 흰색으로 — scoreColor는
                  // 진한 배경 위에서 good·bad가 AA 미달이다.
                  color: darkBackground
                      ? Colors.white
                      : AppTheme.scoreTextColor(score),
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
  final bool darkBackground;
  _RingPainter(this.score, this.strokeWidth, {this.darkBackground = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final bg = Paint()
      ..color = darkBackground
          ? Colors.white.withValues(alpha: 0.25)
          : AppTheme.line
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
      old.score != score || old.darkBackground != darkBackground;
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
    // 막대·점은 그래픽이라 scoreColor를 쓰지만, '82 · 양호' 글자는
    // 카드 위에서 AA를 만족하는 scoreTextColor를 쓴다
    // (금색 구간은 흰 배경 1.58:1로 미달이라 goldDark으로 바뀐다).
    final color = AppTheme.scoreColor(score);
    final textColor = AppTheme.scoreTextColor(score);
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
                      color: textColor),
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
          colors: [AppTheme.deepNavy, AppTheme.deepNavyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.deepBorder),
        boxShadow: AppTheme.softShadow,
      ),
      child: Stack(
        children: [
          Row(
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
                    Semantics(
                      header: true,
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.sub, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          // 우상단 초승달 장식
          const Positioned(
            top: 0,
            right: 0,
            child: CrescentMoon(size: 26),
          ),
        ],
      ),
    );
  }
}

/// 앱 공통 헤더 — 홈·이름 분석·설정 탭 상단에 쓴다. 부제목만 탭마다 다르다 (2026-11-13).
/// 타이틀·이미지 크기를 바꾸면 여기서 한 번만 바꾸면 된다.
StarHero appHeader(String subtitle) => StarHero(
      title: '작명별',
      subtitle: subtitle,
      imageSize: 64,
    );

/// 빈 상태 — 별 친구와 함께 따뜻하게 안내한다
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  // 행동 버튼 아래에 붙는 작은 보조 문구 (예: 보관함 소실 안내).
  final String? footnote;
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.footnote,
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
            if (footnote != null) ...[
              const SizedBox(height: 12),
              Text(footnote!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.sub, height: 1.5)),
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

/// 오행 색상 — 카드 위 14pt 굵은 글자 기준 (굵은 14pt는 large 텍스트라 3:1이면
/// 되지만, 여유 있게 4:1 이상인 값으로 골랐다).
Color elementColor(String e) {
  switch (e) {
    case '목':
      return const Color(0xFF43A06B);
    case '화':
      return const Color(0xFFF07070);
    case '토':
      return const Color(0xFFC98A1B);
    case '금':
      return const Color(0xFF8A93A6);
    case '수':
      return const Color(0xFF5B93C9);
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
    // GestureDetector만 쓰면 스크린리더가 버튼으로 못 읽고 포커스도
    // 안 잡혀서, Semantics로 버튼 역할·선택 상태를 달아준다.
    // 터치 높이는 48dp를 보장한다 (패딩 14*2 + 아이콘 24 = 52).
    // 선택 상태의 아이콘·라벨은 글자라, boy/girl 채움색 대신 카드 위에서
    // AA를 만족하는 밝은 변형(boyDark/girlDark)을 쓴다. 테두리·배경은 원색 유지.
    final textColor = color == AppTheme.boy
        ? AppTheme.boyDark
        : color == AppTheme.girl
            ? AppTheme.girlDark
            : color;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.14)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : AppTheme.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? textColor : AppTheme.sub),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? textColor : AppTheme.sub)),
            ],
          ),
        ),
      ),
    );
  }
}
