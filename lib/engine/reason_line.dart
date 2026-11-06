import 'dart:developer';

import '../data/suri81.dart';
import '../models.dart';
import 'saju.dart';

/// 추천 카드에 붙는 근거 한 줄 — 'AI가 골랐어요' 같은 막연한 문장 대신
/// 계산 결과가 뒷받침하는 것만 문장으로 쓴다.
/// - 용신 보완: 사주 보완 점수가 70점 이상일 때만 (낮으면 근거가 안 된다)
/// - 수리 길흉: 항상 (81수리 등급은 모든 이름에 있다)
/// - 음양·발음: 80점 이상일 때만
/// 순수 함수 — 화면에서 분리됨.
/// 수리 종합 등급은 코드로 판정한다. suri.grade.code는
/// 81수리 등급 코드(daegil/gil/mixed/hyung)와 같은 값이라
/// 표시 문구를 다시 라벨로 되돌리는 역매핑이 필요 없다.
String _suriReasonLabel(DimensionGrade grade) {
  switch (grade.code) {
    case 'hyung':
      return '흉';
    case 'mixed':
      return '반길반흉';
    case 'daegil':
      return '대길';
    case 'gil':
      return '길';
    default:
      // scoring.dart가 만드는 코드는 위 4가지뿐이라 도달하지 않는다.
      // 도달하면 디버그에서 바로 잡을 수 있게 assert하고, 릴리스에서는
      // 예전 기본값(suriGradeLabel이 모르는 입력에 돌려주던 '흉')을
      // 그대로 돌려줘 동작이 바뀌지 않는다.
      assert(false, 'unknown suri grade: ${grade.code}');
      log('unknown suri grade: ${grade.code}');
      return suriGradeLabel(grade.code);
  }
}

String recommendReason(NameAnalysis a) {
  final parts = <String>[];
  final yongsin = a.saju.yongsin;
  if (yongsin != null && a.resource.score >= 70) {
    parts.add('용신 ${elementNames[yongsin]} 보완');
  }
  parts.add('수리 ${_suriReasonLabel(a.suri.grade)}');
  if (a.yinyang.score >= 80) parts.add('음양 조화');
  if (a.sound.score >= 80) parts.add('발음 좋음');
  return parts.join(' · ');
}
