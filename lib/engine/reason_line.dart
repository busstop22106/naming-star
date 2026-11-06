import '../data/suri81.dart';
import '../models.dart';
import 'saju.dart';

/// 추천 카드에 붙는 근거 한 줄 — 'AI가 골랐어요' 같은 막연한 문장 대신
/// 계산 결과가 뒷받침하는 것만 문장으로 쓴다.
/// - 용신 보완: 사주 보완 점수가 70점 이상일 때만 (낮으면 근거가 안 된다)
/// - 수리 길흉: 항상 (81수리 등급은 모든 이름에 있다)
/// - 음양·발음: 80점 이상일 때만
/// 순수 함수 — 화면에서 분리됨.
/// 수리 종합 등급 문구('사격 대길'·'흉수 포함' 등)를 근거 한 줄용 라벨로 바꾼다.
/// suriGradeLabel은 등급 코드(daegil/gil/mixed/hyung)를 받는데,
/// analyzeName이 만드는 suri.grade는 사람이 읽는 종합 문구라
/// 그대로 넘기면 모르는 입력으로 취급돼 전부 '흉'이 됐다.
/// 등급 코드는 suriGradeLabel에 그대로 위임한다.
String _suriReasonLabel(String grade) {
  switch (grade) {
    case '흉수 포함':
      return '흉';
    case '반길반흉 포함':
      return '반길반흉';
    case '사격 대길':
      return '대길';
    case '사격 길':
      return '길';
    default:
      return suriGradeLabel(grade);
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
