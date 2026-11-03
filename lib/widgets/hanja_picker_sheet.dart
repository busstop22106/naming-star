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
/// 한자는 17pt 고딕 폴백으로, 뜻·획수는 13pt로 보여준다.
/// 뜻이 없는 한자는 부가 정보를 옅은 회색으로 표시한다.
/// 칩을 탭하면 그 한자의 원래 인덱스를 돌려주며 시트를 닫는다.
class HanjaPickerSheet extends StatefulWidget {
  final String syllable;
  final List<HanjaPick> options;
  final int selectedIndex;
  const HanjaPickerSheet({
    super.key,
    required this.syllable,
    required this.options,
    required this.selectedIndex,
  });

  @override
  State<HanjaPickerSheet> createState() => _HanjaPickerSheetState();
}

class _HanjaPickerSheetState extends State<HanjaPickerSheet> {
  final _queryCtrl = TextEditingController();

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        filterHanjaOptions(widget.options, _queryCtrl.text);
    final query = _queryCtrl.text.trim();
    return Column(
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
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.syllable} 한자 선택 (${widget.options.length}개)',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppTheme.sub),
                tooltip: '닫기',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _queryCtrl,
            onChanged: (_) => setState(() {}),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filtered.map((e) {
                      final sel = widget.selectedIndex == e.key;
                      final hasMeaning = e.value.meaning.isNotEmpty;
                      final subColor = hasMeaning
                          ? (sel ? AppTheme.primaryDark : AppTheme.ink)
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
                                    fontSize: 13, color: subColor),
                              ),
                            ],
                          ),
                        ),
                        selected: sel,
                        onSelected: (_) =>
                            Navigator.of(context).pop(e.key),
                        selectedColor: AppTheme.primarySoft,
                        avatar: ElementChip(e.value.element),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
