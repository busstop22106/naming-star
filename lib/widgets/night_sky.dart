import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// 밤하늘 별자리 배경 — 홈·공개 연출 화면 뒤에 깔리는 고정 별빛.
///
/// 별의 위치·크기·밝기는 고정 시드로 정해서 리빌드 때마다 바뀌지 않는다.
/// 스크롤해도 배경은 그대로 있고 내용만 움직인다.
class Starfield extends StatelessWidget {
  const Starfield({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _StarfieldPainter()),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(7);
    for (var i = 0; i < 42; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final r = 0.8 + rand.nextDouble() * 1.1;
      final goldStar = rand.nextDouble() < 0.18;
      final alpha = 0.25 + rand.nextDouble() * 0.55;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = (goldStar ? AppTheme.gold : Colors.white)
              .withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 초승달 — 히어로 카드 우상단 장식.
///
/// 가리는 원은 BlendMode.dstOut으로 뚫어서, 뒤의 그라데이션 배경이
/// 그대로 비치게 한다 (단색으로 덮으면 그라데이션 경계가 보인다).
class CrescentMoon extends StatelessWidget {
  final double size;
  const CrescentMoon({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _CrescentMoonPainter()),
    );
  }
}

class _CrescentMoonPainter extends CustomPainter {
  const _CrescentMoonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
    // 달 본체 — 옅은 금빛
    canvas.drawCircle(
      center,
      r,
      Paint()..color = const Color(0xFFF2E3B3),
    );
    // 오른쪽 위를 뚫어 초승달로 만든다
    canvas.drawCircle(
      Offset(r + r * 0.55, r - r * 0.25),
      r * 0.92,
      Paint()..blendMode = BlendMode.dstOut,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
