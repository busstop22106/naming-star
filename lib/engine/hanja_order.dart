import '../data/hanja.dart';
import '../data/hanja_full.dart';
import '../models.dart';

/// CJK 호환 한자(U+F900–U+FAFF)인지 — 정자의 이체자(호환자)다.
/// 대법원 인명용 한자표 기준 270건이 이 범위에 들어 있고, 그중 268건은
/// 같은 음절에 NFKC 정규화 형태의 정자 쌍둥이가 함께 있다.
/// 호환자는 뜻이 비어 있는 경우도 많고(224건) 같은 한자를 두 번 보여주는
/// 꼴이라 선택 목록에서 제외한다. 이미 저장된 호환자 pick은
/// analyzeName에 직접 넘기면 그대로 재계산되지만, 선택 목록에 없으므로
/// 상세 화면 한자 바꾸기는 현재 pick을 목록에 덧붙여 선택 표시를 띄우고,
/// 이름 분석 탭의 보관함 불러오기는 해당 음절의 첫 번째 한자로
/// 되돌아갈 수 있으니(화면 쪽에서 _hanjaIdx를 못 찾으면 0번을 씀)
/// 호환자 저장 이름은 화면 쪽에서 따로 다뤄야 한다.
bool _isCompatVariant(String char) {
  if (char.isEmpty) return false;
  final code = char.codeUnitAt(0);
  return code >= 0xF900 && code <= 0xFAFF;
}

/// 음절의 전체 한자를 curated 우선으로 정렬
///
/// curated(추천 풀)에 있는 한자를 curated 순서대로 먼저, 나머지는
/// 뜻이 있는 한자를 먼저·획수 오름차순으로, 뜻 없는 한자를 뒤에
/// 획수 오름차순으로 배치한다. 호환 이체자는 목록에서 제외한다.
/// 첫 번째 항목(기본 선택)은 curated 순서라 바뀌지 않는다.
/// 순수 함수 — 화면에서 분리됨.
List<HanjaPick> orderedHanja(String syllable) {
  final full = hanjaFullBySyllable[syllable] ?? [];
  final curatedOrder =
      hanjaBySyllable[syllable]?.map((e) => e.char).toList() ?? [];
  final curatedSet = curatedOrder.toSet();
  final visible = full.where((e) => !_isCompatVariant(e.char)).toList();
  final curated =
      visible.where((e) => curatedSet.contains(e.char)).toList();
  final rest =
      visible.where((e) => !curatedSet.contains(e.char)).toList();
  curated.sort((a, b) => curatedOrder
      .indexOf(a.char)
      .compareTo(curatedOrder.indexOf(b.char)));
  // 뜻 있는 한자를 먼저, 각 그룹 안에서는 획수 오름차순으로 정렬한다.
  // 뜻 없는 한자(정자 515건)가 앞에 오면 무심코 고르기 쉽기 때문이다.
  rest.sort((a, b) {
    final aNoMeaning = a.meaning.isEmpty ? 1 : 0;
    final bNoMeaning = b.meaning.isEmpty ? 1 : 0;
    if (aNoMeaning != bNoMeaning) return aNoMeaning - bNoMeaning;
    return a.strokes.compareTo(b.strokes);
  });
  return [...curated, ...rest];
}

/// 한자 선택 검색 필터 (순수 함수)
/// - 빈 검색어면 전체를 그대로 돌려준다.
/// - 한자·뜻은 부분 일치, 획수는 '10' 또는 '10획' 정확 일치.
/// - 원래 순서 인덱스를 함께 유지해서 선택 상태가 필터링에 흔들리지 않는다.
List<MapEntry<int, HanjaPick>> filterHanjaOptions(
    List<HanjaPick> ordered, String query) {
  final all = ordered.asMap().entries.toList();
  final q = query.trim();
  if (q.isEmpty) return all;
  final digits = q.endsWith('획') ? q.substring(0, q.length - 1) : q;
  return all.where((e) {
    final h = e.value;
    return h.char.contains(q) ||
        h.meaning.contains(q) ||
        h.strokes.toString() == digits;
  }).toList();
}
