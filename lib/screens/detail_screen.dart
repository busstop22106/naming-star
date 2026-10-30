import 'package:flutter/material.dart';
import '../engine/hanja_order.dart';
import '../engine/life_story.dart';
import '../engine/saju.dart';
import '../engine/scoring.dart';
import '../favorites.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 이름 상세 분석
class DetailScreen extends StatefulWidget {
  final BabyInfo baby;
  final NameAnalysis analysis;
  const DetailScreen(
      {super.key, required this.baby, required this.analysis});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late List<HanjaPick> _picks;
  late NameAnalysis _analysis;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _picks = List.of(widget.analysis.picks);
    _analysis = widget.analysis;
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final s = await isFavorite(
        widget.analysis.fullName, widget.analysis.hanjaName);
    if (mounted) setState(() => _saved = s);
  }

  void _rescore() {
    setState(() {
      _analysis = analyzeName(
        surname: widget.baby.surname,
        surnameStrokes: widget.baby.surnameStrokes,
        picks: _picks,
        saju: widget.analysis.saju,
        gender: widget.baby.gender,
      );
    });
    _checkSaved();
  }

  Future<void> _toggleSave() async {
    final item = FavoriteItem(
      baby: widget.baby,
      picks: _picks,
      total: _analysis.total,
      savedAt: DateTime.now(),
    );
    if (_saved) {
      await removeFavorite(item);
      setState(() => _saved = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보관함에서 삭제했어요.')),
        );
      }
    } else {
      await saveFavorite(item);
      setState(() => _saved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보관함에 저장했어요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _analysis;
    final saju = a.saju;

    return Scaffold(
      appBar: AppBar(
        title: const Text('이름 상세 분석'),
        actions: [
          IconButton(
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_border,
              color: _saved ? AppTheme.gold : AppTheme.ink,
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, 24 + MediaQuery.of(context).padding.bottom),
        children: [
          // 이름 헤더
          Card(
            color: AppTheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.fullName,
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                            a.isPureKorean
                                ? '순우리말 이름'
                                : a.hanjaName,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: a.picks.map((p) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: 0.14),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                  a.isPureKorean
                                      ? '${p.syllable} (발음오행 ${elementNames[p.element]})'
                                      : '${p.char} ${p.meaning}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  ScoreRing(score: a.total, size: 110),
                ],
              ),
            ),
          ),

          // 경고
          if (a.warnings.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...a.warnings.map((w) => Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppTheme.warn.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 20, color: AppTheme.warn),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(w,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
          ],

          // 5개 차원
          SectionCard(
            title: '종합 평가',
            icon: Icons.auto_awesome,
            subtitle: '수리 35% · 사주 보완 25% · 발음 20% · 음양 10% · 사용성 10%',
            child: Column(
              children: a.dimensions
                  .map((d) => _ExpandableDimension(d: d))
                  .toList(),
            ),
          ),

          // 한자 바꾸기 (순우리말 이름은 숨김)
          if (!a.isPureKorean)
            SectionCard(
              title: '한자 바꾸기',
              icon: Icons.edit,
              subtitle: '같은 발음의 다른 한자를 고르면 점수가 다시 계산돼요',
              child: Column(
                children: [
                  // 실시간 점수 — 한자를 바꿀 때마다 맨 위로 스크롤하지
                  // 않아도 지금 조합의 점수를 바로 확인할 수 있다.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '지금 조합: ${a.fullName}(${a.hanjaName})',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${a.total.toStringAsFixed(0)}점 · ${AppTheme.scoreWord(a.total)}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.scoreColor(a.total)),
                        ),
                      ],
                    ),
                  ),
                  // 원래 추천 한자와 달라졌을 때만 되돌리기 버튼을 보인다.
                  if (_picks.map((p) => p.char).join() !=
                      widget.analysis.picks
                          .map((p) => p.char)
                          .join()) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _picks =
                                List.of(widget.analysis.picks);
                          });
                          _rescore();
                        },
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('추천 한자로 되돌리기'),
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _HanjaPicker(
                    index: 0,
                    picks: _picks,
                    onChanged: (p) {
                      _picks[0] = p;
                      _rescore();
                    },
                  ),
                  const SizedBox(height: 10),
                  _HanjaPicker(
                    index: 1,
                    picks: _picks,
                    onChanged: (p) {
                      _picks[1] = p;
                      _rescore();
                    },
                  ),
                ],
              ),
            ),

          // 사주 분석
          SectionCard(
            title: '사주 분석',
            icon: Icons.spa,
            subtitle: '간이 만세력 · 참고용',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniPillar('년주', saju.year),
                    _MiniPillar('월주', saju.month),
                    _MiniPillar('일주', saju.day),
                    if (saju.hour != null)
                      _MiniPillar('시주', saju.hour!),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('사주 오행 분포',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: ['목', '화', '토', '금', '수'].map((e) {
                    final c = saju.elementCounts[e] ?? 0;
                    final total = saju.elementCounts.values
                        .fold<int>(0, (p, v) => p + v);
                    return Expanded(
                      child: Column(
                        children: [
                          ElementChip(e),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 60,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 22,
                                height: total == 0
                                    ? 4
                                    : 8 + 52 * (c / total),
                                decoration: BoxDecoration(
                                  color: elementColor(e)
                                      .withValues(alpha: 0.75),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          Text('$c',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _SajuRow('일간',
                    '${saju.dayMaster}(${elementNames[saju.dayElement]})'),
                _SajuRow('신강/신약',
                    saju.strongBody ? '신강(기운이 넘침)' : '신약(기운이 부족)'),
                if (saju.yongsin != null)
                  _SajuRow('용신', elementNames[saju.yongsin]!,
                      highlight: true),
                if (saju.huishin != null)
                  _SajuRow('희신', elementNames[saju.huishin]!),
                const SizedBox(height: 8),
                ...saju.notes.map((n) => Padding(
                      padding:
                          const EdgeInsets.only(top: 6),
                      child: Text('· $n',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.sub)),
                    )),
              ],
            ),
          ),

          // 수리 상세
          SectionCard(
            title: '수리 상세',
            icon: Icons.calculate,
            subtitle: '한자 획수(원획) → 사격 → 81수리',
            child: Column(
              children: a.suri.details
                  .map((d) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(d,
                                    style: const TextStyle(
                                        fontSize: 13))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          // 이 이름의 일대기 (나이대별 흐름)
          SectionCard(
            title: '이 이름의 일대기',
            icon: Icons.timeline,
            subtitle: '나이대별 흐름 · 재미로 보는 참고용 해석이에요',
            child: Column(
              children: [
                for (final stage in buildLifeStory(a)) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                            '${stage.title} · ${stage.ageRange}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary)),
                      ),
                      const Spacer(),
                      Text(
                          '${stage.score.toStringAsFixed(0)}점 · ${stage.grade}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(stage.headline,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text(stage.body,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.sub)),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _toggleSave,
            icon: Icon(_saved
                ? Icons.bookmark
                : Icons.bookmark_border),
            label: Text(_saved ? '보관함에 저장됨' : '보관함에 저장하기'),
          ),
        ],
      ),
    );
  }
}

class _ExpandableDimension extends StatefulWidget {
  final DimensionScore d;
  const _ExpandableDimension({required this.d});

  @override
  State<_ExpandableDimension> createState() =>
      _ExpandableDimensionState();
}

class _ExpandableDimensionState extends State<_ExpandableDimension> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DimensionBar(
                    title: d.title,
                    score: d.score,
                    grade: d.grade),
                Row(
                  children: [
                    Expanded(
                      child: Text(d.summary,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.sub)),
                    ),
                    Icon(
                        _open
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: AppTheme.sub),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: d.details
                  .map((t) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 2),
                        child: Text('· $t',
                            style:
                                const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _HanjaPicker extends StatelessWidget {
  final int index;
  final List<HanjaPick> picks;
  final ValueChanged<HanjaPick> onChanged;
  const _HanjaPicker({
    required this.index,
    required this.picks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cur = picks[index];
    final opts = orderedHanja(cur.syllable);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이름 ${index + 1}자 · ${cur.syllable} (${opts.length}개)',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: opts.map((o) {
                final sel = o.char == cur.char;
                final sub = o.meaning.isNotEmpty
                    ? '${o.meaning} · ${o.strokes}획'
                    : '${o.strokes}획';
                return GestureDetector(
                  onTap: () => onChanged(o),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? AppTheme.primary
                            : AppTheme.line,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(o.char,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : AppTheme.ink)),
                        const SizedBox(width: 6),
                        Text(sub,
                            style: TextStyle(
                                fontSize: 11,
                                color: sel
                                    ? Colors.white70
                                    : AppTheme.sub)),
                        const SizedBox(width: 4),
                        ElementChip(o.element),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniPillar extends StatelessWidget {
  final String label;
  final SajuPillar p;
  const _MiniPillar(this.label, this.p);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.sub)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(p.label,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary)),
        ),
      ],
    );
  }
}

class _SajuRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SajuRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.sub)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? AppTheme.primary
                      : AppTheme.ink)),
        ],
      ),
    );
  }
}
