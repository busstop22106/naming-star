import 'package:flutter/material.dart';
import '../engine/hanja_order.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

/// 음절 하나에 쓸 한자를 고르는 모달 시트.
///
/// 이름 분석 화면에서 음절마다 인라인으로 길게 늘어놓던 한자 목록을
/// 모달로 옮긴 것이다. 인라인 목록은 각자 안쪽 스크롤 영역을 가져서
/// 화면 전체 스크롤을 가로채는 문제가 있었다. 시트 안에서는 목록만
/// 스크롤되고, 닫으면 화면은 다시 하나의 스크롤로 동작한다.
///
/// - 한자는 17pt 고딕 폴백으로, 뜻·획수는 13pt로 보여준다.
/// - 뜻이 없는 한자는 부가 정보를 옅은 회색으로 표시한다.
/// - 선택 표시는 체크가 아니라 보라색 테두리(선택 1.5 / 미선택 1)이다.
/// - 칩을 탭해도 시트가 바로 닫히지 않는다. 선택 상태만 바뀌고,
///   [onSelected]로 바깥에 즉시 알린다. 시트를 스와이프로 내리거나
///   바깥을 터치해 닫으면 그 선택이 그대로 남는다.
/// - 첫 진입 버벅임을 줄이려고 목록은 40개씩 끊어 보여주고,
///   '더 보기'를 누르면 다음 40개를 붙인다. 한 번에 전부 만드는
///   Wrap이 시트 올라오는 애니메이션을 잡아먹던 것이 원인이다.
/// - 하단 시스템 내비게이션 바에 마지막 한자가 가려지지 않게
///   SafeArea(하단)로 감싼다. 닫기 버튼은 두지 않는다 — 스와이프나
///   바깥 터치로 닫는 것이 모달의 기본 동작이다.
class HanjaPickerSheet extends StatefulWidget {
  final String syllable;
  final List<HanjaPick> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const HanjaPickerSheet({
    super.key,
    required this.syllable,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<HanjaPickerSheet> createState() => _HanjaPickerSheetState();
}

class _HanjaPickerSheetState extends State<HanjaPickerSheet> {
  static const _pageSize = 40;

  final _queryCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late int _currentSelected;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _currentSelected = widget.selectedIndex;
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    // 검색어가 바뀌면 처음부터 다시 보여주고 맨 위로 올린다.
    setState(() => _visibleCount = _pageSize);
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterHanjaOptions(widget.options, _queryCtrl.text);
    final query = _queryCtrl.text.trim();
    final visible = filtered.take(_visibleCount).toList();
    final hasMore = filtered.length > _visibleCount;
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.chipBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              '${widget.syllable} 한자 선택 (${widget.options.length}개)',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _queryCtrl,
              onChanged: _onQueryChanged,
              decoration: const InputDecoration(
                hintText: '한자나 뜻으로 검색 (예: 빛, 尹, 10획)',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: query.isNotEmpty && filtered.isEmpty
                ? const Center(
                    child: Text(
                      '검색 결과가 없어요. 한자나 뜻을 다르게 입력해 보세요.',
                      style: TextStyle(fontSize: 13, color: AppTheme.sub),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: visible.map((e) {
                            final sel = _currentSelected == e.key;
                            final hasMeaning =
                                e.value.meaning.isNotEmpty;
                            final subColor = hasMeaning
                                ? (sel
                                    ? AppTheme.primaryDark
                                    : AppTheme.ink)
                                : (sel
                                    ? AppTheme.primaryDark
                                        .withValues(alpha: 0.55)
                                    : AppTheme.hint);
                            return ChoiceChip(
                              label: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      color: sel
                                          ? AppTheme.primaryDark
                                          : AppTheme.ink,
                                      fontWeight: FontWeight.w700),
                                  children: [
                                    TextSpan(
                                      text: e.value.char,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontFamilyFallback:
                                            AppTheme.hanjaFontFallback,
                                      ),
                                    ),
                                    TextSpan(
                                      text: hasMeaning
                                          ? ' ${e.value.meaning} ${e.value.strokes}획'
                                          : ' 뜻없음 ${e.value.strokes}획',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: subColor),
                                    ),
                                  ],
                                ),
                              ),
                              selected: sel,
                              showCheckmark: false,
                              side: BorderSide(
                                color: sel
                                    ? AppTheme.primary
                                    : AppTheme.chipBorder,
                                width: sel ? 1.5 : 1,
                              ),
                              onSelected: (_) {
                                setState(
                                    () => _currentSelected = e.key);
                                widget.onSelected(e.key);
                              },
                              selectedColor: AppTheme.primarySoft,
                              avatar: ElementChip(e.value.element),
                            );
                          }).toList(),
                        ),
                        if (hasMore) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() =>
                                  _visibleCount += _pageSize),
                              child: Text(
                                  '더 보기 (${filtered.length - _visibleCount}개 더)'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
