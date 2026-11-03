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
/// - 칩을 탭하면 [onSelected]로 바깥에 알리고 시트가 바로 닫힌다.
///   예전에는 닫히지 않고 선택만 바꾸는 방식이었는데, 고르고 나서도
///   시트가 남아 있는 게 불편하다는 지적에 닫히는 방식으로 바꿨다.
/// - 첫 진입 버벅임을 줄이려고 목록은 시트 올라오는 애니메이션이
///   끝난 뒤에 한 번에 그린다. 한 번에 전부 만드는 Wrap이 애니메이션과
///   같은 프레임에 그리면 올라올 때 끊겼는데, 애니메이션이 끝난 뒤에는
///   정지 화면이라 같은 양을 그려도 체감이 안 된다.
///   그래서 '더 보기' 분할은 없애고 처음부터 전체를 스크롤하게 한다.
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
  final _queryCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late int _currentSelected;
  // 시트 진입 애니메이션이 끝날 때까지 목록 그리기를 미룬다.
  bool _ready = false;
  Animation<double>? _routeAnimation;

  @override
  void initState() {
    super.initState();
    _currentSelected = widget.selectedIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation == null) {
      final animation = ModalRoute.of(context)?.animation;
      if (animation == null || animation.isCompleted) {
        // 모달이 아닌 채로 바로 그리는 경우(테스트 등)는 즉시 그린다.
        _ready = true;
      } else {
        _routeAnimation = animation;
        animation.addStatusListener(_onAnimationStatus);
      }
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    _routeAnimation?.removeStatusListener(_onAnimationStatus);
    super.dispose();
  }

  void _onQueryChanged(String _) {
    // 검색어가 바뀌면 맨 위로 올린다.
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterHanjaOptions(widget.options, _queryCtrl.text);
    final query = _queryCtrl.text.trim();
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
            child: !_ready
                ? const Center(child: CircularProgressIndicator())
                : query.isNotEmpty && filtered.isEmpty
                    ? const Center(
                        child: Text(
                          '검색 결과가 없어요. 한자나 뜻을 다르게 입력해 보세요.',
                          style:
                              TextStyle(fontSize: 13, color: AppTheme.sub),
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filtered.map((e) {
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
                                // 고르면 바깥에 알리고 바로 닫는다.
                                // 부모 setState가 일어나는 동안 시트가 위에
                                // 있어도, 시트는 모달 라우트라 부모 리빌드와
                                // 무관하게 그대로 닫힌다.
                                widget.onSelected(e.key);
                                Navigator.pop(context);
                              },
                              selectedColor: AppTheme.primarySoft,
                              avatar: ElementChip(e.value.element),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
