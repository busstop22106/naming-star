import 'package:flutter/material.dart';
import '../data/surnames.dart';
import '../models.dart';
import '../theme.dart';

/// 많이 쓰는 성씨 — DB 첫 항목이 통용 한자(김金·이李·박朴…)라 바로 선택한다.
const _quickSurnames = [
  '김', '이', '박', '최', '정', '강', '조', '윤', '장', '임', '한', '오', '서', '신',
];

/// 성씨 선택 바텀시트 열기
Future<SurnamePick?> showSurnamePicker(
    BuildContext context, SurnamePick? current) {
  return showModalBottomSheet<SurnamePick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      // 키보드가 올라오면 시트 하단을 키보드 위로 밀어 리스트가 가려지지 않게 한다.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _SurnameSheet(current: current),
    ),
  );
}

class _SurnameSheet extends StatefulWidget {
  final SurnamePick? current;
  const _SurnameSheet({required this.current});

  @override
  State<_SurnameSheet> createState() => _SurnameSheetState();
}

class _SurnameSheetState extends State<_SurnameSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _expanded; // 펼쳐진 성씨명

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = searchSurnameNames(_query);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),
          const Text('성씨 선택',
              style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: '성씨 또는 한자 검색 (예: 김, 金)',
                prefixIcon: Icon(Icons.search),
                counterText: '',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // 많이 쓰는 성씨 퀵 선택 — 세로 3줄 대신 가로 한 줄로 옆으로 밀어 본다.
          // 검색 중에는 숨겨서 성씨 목록이 넓어지게 한다.
          // 다른 한자를 원하면 아래 목록에서 해당 성씨를 펼치면 된다.
          if (_query.isEmpty) ...[
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('많이 쓰는 성씨',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.sub)),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _quickSurnames.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final name = _quickSurnames[i];
                  final first = surnamesByName[name]!.first;
                  final sel = widget.current?.name == name &&
                      widget.current?.hanja == first.hanja;
                  return ChoiceChip(
                    label: Text(name,
                        style: TextStyle(
                            fontSize: 14,
                            color: sel
                                ? AppTheme.primaryDark
                                : AppTheme.ink,
                            fontWeight: FontWeight.w700)),
                    selected: sel,
                    onSelected: (_) => Navigator.pop(
                        context,
                        SurnamePick(
                            name: first.name,
                            hanja: first.hanja,
                            strokes: first.strokes)),
                    selectedColor: AppTheme.primarySoft,
                    showCheckmark: false,
                    side: BorderSide(
                      color: sel
                          ? AppTheme.primary
                          : AppTheme.chipBorder,
                      width: sel ? 1.5 : 1,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: names.isEmpty
                ? const Center(
                    child: Text('검색 결과가 없어요.\n아래에서 직접 입력해주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.sub)))
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    itemCount: names.length,
                    itemBuilder: (_, i) => _surnameRow(
                        names[i], names.length <= 3),
                  ),
          ),
          const Divider(height: 1),
          // 시트 배경(DecoratedBox)과 ListTile 사이에 Material이 없으면
          // 잉크 효과가 가려진다는 디버그 경고가 뜬다 — 같은 배경색 Material로 감싼다.
          Material(
            color: AppTheme.bg,
            child: ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AppTheme.primary),
              title: const Text('목록에 없는 성씨 직접 입력',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: () async {
                final manual = await _showManualDialog(context);
                if (manual != null && context.mounted) {
                  Navigator.pop(context, manual);
                }
              },
            ),
          ),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _surnameRow(String name, bool autoOpen) {
    final options = surnamesByName[name]!;
    // 검색 결과가 3개 이하이면 아코디언을 자동으로 펼쳐 한자를 바로 고른다.
    // (전체 목록일 때는 200개가 넘으므로 자동 펼침을 하지 않는다.)
    final isOpen = _expanded == name || autoOpen;

    // 성능: 시트에서 빠르게 스크롤하면 행마다 그림자(Card elevation)를
    // 새로 그려야 해서 저사양 기기에서 버벅인다. 조밀한 목록 행은
    // 그림자 없는 테두리 박스로 바꿔 래스터 비용을 줄인다.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (options.length == 1) {
                // 한자가 하나면 바로 선택
                final o = options.first;
                Navigator.pop(
                    context,
                    SurnamePick(
                        name: o.name,
                        hanja: o.hanja,
                        strokes: o.strokes));
              } else {
                setState(() =>
                    _expanded = isOpen ? null : name);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Text(options.first.hanja,
                      style: const TextStyle(
                          fontSize: 15, color: AppTheme.sub)),
                  if (options.length > 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${options.length}개 한자',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ),
                  ],
                  const Spacer(),
                  if (options.length == 1)
                    Text('${options.first.strokes}획',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.sub,
                            fontWeight: FontWeight.w600))
                  else
                    Icon(
                        isOpen
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppTheme.sub),
                ],
              ),
            ),
          ),
          if (isOpen)
            ...options.map((o) => InkWell(
                  onTap: () => Navigator.pop(
                      context,
                      SurnamePick(
                          name: o.name,
                          hanja: o.hanja,
                          strokes: o.strokes)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: AppTheme.line)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(o.hanja,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary)),
                        ),
                        const SizedBox(width: 12),
                        Text('${o.name}(${o.hanja})',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('${o.strokes}획',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.sub)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppTheme.sub),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  /// 직접 입력 다이얼로그
  Future<SurnamePick?> _showManualDialog(
      BuildContext context) {
    final nameCtrl = TextEditingController();
    final hanjaCtrl = TextEditingController();
    final strokesCtrl = TextEditingController();
    return showDialog<SurnamePick>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('성씨 직접 입력',
            style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              maxLength: 2,
              decoration: const InputDecoration(
                  labelText: '성씨', hintText: '예: 김', counterText: ''),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: hanjaCtrl,
              maxLength: 2,
              decoration: const InputDecoration(
                  labelText: '한자 (선택)',
                  hintText: '예: 金',
                  counterText: ''),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: strokesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: '획수', suffixText: '획 (강희자전 원획)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final strokes =
                  int.tryParse(strokesCtrl.text.trim());
              if (name.isEmpty ||
                  strokes == null ||
                  strokes <= 0 ||
                  strokes >= 40) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('성씨와 올바른 획수를 입력해주세요.')),
                );
                return;
              }
              Navigator.pop(
                  ctx,
                  SurnamePick(
                      name: name,
                      hanja: hanjaCtrl.text.trim(),
                      strokes: strokes,
                      manual: true));
            },
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(90, 44)),
            child: const Text('입력'),
          ),
        ],
      ),
    );
  }
}
