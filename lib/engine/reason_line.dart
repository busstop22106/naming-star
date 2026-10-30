import '../data/suri81.dart';
import '../models.dart';
import 'saju.dart';

/// 추천 카드에 붙는 근거 한 줄 — 'AI가 골랐어요' 같은 막연한 문장 대신
/// 계산 결과가 뒷받침하는 것만 문장으로 쓴다.
/// - 용신 보완: 사주 보완 점수가 70점 이상일 때만 (낮으면 근거가 안 된다)
/// - 수리 길흉: 항상 (81수리 등급은 모든 이름에 있다)
/// - 음양·발음: 80점 이상일 때만
/// 순수 함수 — 화면에서 분리됨.
String recommendReason(NameAnalysis a) {
  final parts = <String>[];
  final yongsin = a.saju.yongsin;
  if (yongsin != null && a.resource.score >= 70) {
    parts.add('용신 ${elementNames[yongsin]} 보완');
  }
  parts.add('수리 ${suriGradeLabel(a.suri.grade)}');
  if (a.yinyang.score >= 80) parts.add('음양 조화');
  if (a.sound.score >= 80) parts.add('발음 좋음');
  return parts.join(' · ');
}
