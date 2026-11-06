import 'package:flutter/material.dart';
import '../engine/compat.dart';
import '../engine/saju.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/family_map_card.dart';

/// 받침 유무에 따라 '과의/와의' 선택 (예: 형과의, 아빠와의)
String _withParticle(String label) {
  if (label.isEmpty) return label;
  final code = label.codeUnitAt(label.length - 1);
  if (code >= 0xAC00 && code <= 0xD7A3) {
    final hasJong = (code - 0xAC00) % 28 != 0;
    return hasJong ? '$label과의' : '$label와의';
  }
  return '$label와의';
}

/// 가족 이름 궁합 결과 화면
class CompatScreen extends StatelessWidget {
  final String babyFullName; // 성+이름 (한글)
  final String babyHanjaName; // 이름 한자 (순우리말이면 '')
  final bool isPureKorean;
  final FamilyCompatResult result;

  const CompatScreen({
    super.key,
    required this.babyFullName,
    required this.babyHanjaName,
    required this.isPureKorean,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final best = result.best;
    return Scaffold(
      appBar: AppBar(title: const Text('가족 이름 궁합')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          // ── 종합 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    babyHanjaName.isEmpty
                        ? babyFullName
                        : '$babyFullName ($babyHanjaName)',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPureKorean
                        ? '순우리말 이름 · 발음오행 기준'
                        : '이름 오행 ${result.nameElements.join(' · ')}',
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.sub),
                  ),
                  const SizedBox(height: 14),
                  ScoreRing(score: result.total, size: 128),
                  const SizedBox(height: 10),
                  // 낮은 점수에는 평가 문구를 두지 않는다 (grade가 빈 문자열).
                  if (result.grade.isNotEmpty) ...[
                    Text(
                      result.grade,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.scoreTextColor(result.total)),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    result.members.length > 1
                        ? '가장 잘 맞는 구성원 · ${best.label} ${best.total.toStringAsFixed(0)}점'
                        : '${best.label} ${best.total.toStringAsFixed(0)}점',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.sub,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          // ── 가족 궁합 지도 ──
          if (result.members.length > 1) ...[
            const SizedBox(height: 12),
            FamilyMapCard(result: result),
          ],
          const SizedBox(height: 12),
          // ── 구성원별 상세 ──
          for (var i = 0; i < result.members.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _MemberCard(compat: result.members[i]),
          ],
          const SizedBox(height: 12),
          // ── 가족 오행 균형 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('가족 오행 균형',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('가족 구성원 사주 합산에 아기 이름의 오행을 더한 분포예요.',
                      style: TextStyle(fontSize: 12, color: AppTheme.sub)),
                  const SizedBox(height: 12),
                  for (final e in ['목', '화', '토', '금', '수'])
                    _ElementRow(
                      element: e,
                      before: result.familyCountsBefore[e] ?? 0,
                      after: result.familyCountsAfter[e] ?? 0,
                    ),
                  const SizedBox(height: 10),
                  Text(result.balanceNote,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('다른 이름으로 비교해보기'),
          ),
          const SizedBox(height: 10),
          const Text(
            '구성원 정보는 그대로 유지돼요. 이름만 바꿔서 다시 분석하면 후보끼리 비교할 수 있어요.',
            style: TextStyle(fontSize: 11, color: AppTheme.sub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            '띠 궁합은 출생연도로 정해지는 부분이라 이름으로 바뀌지 않아요. 전체 점수는 간이 만세력으로 계산해요.',
            style: TextStyle(fontSize: 11, color: AppTheme.sub, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 구성원 한 명의 궁합 카드
class _MemberCard extends StatelessWidget {
  final MemberCompat compat;
  const _MemberCard({required this.compat});

  @override
  Widget build(BuildContext context) {
    final saju = compat.memberSaju;
    final zodiac = zodiacNames[saju.year.branch] ?? '';
    final elem100 = compat.elementScore / 40 * 100;
    final yong100 = compat.yongsinScore / 40 * 100;
    final zod100 = compat.zodiacScoreValue / 20 * 100;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${_withParticle(compat.label)} 궁합',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${compat.total.toStringAsFixed(0)}점',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.scoreTextColor(compat.total)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$zodiac · 일간 ${saju.dayMaster}(${elementNames[saju.dayElement]})'
              '${saju.yongsin != null ? ' · 용신 ${elementNames[saju.yongsin]}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppTheme.sub),
            ),
            const SizedBox(height: 8),
            DimensionBar(
                title: '오행 보완',
                score: elem100,
                grade: AppTheme.scoreWord(elem100)),
            DimensionBar(
                title: '용신 조화',
                score: yong100,
                grade: AppTheme.scoreWord(yong100)),
            DimensionBar(
                title: '띠 궁합',
                score: zod100,
                grade: AppTheme.scoreWord(zod100)),
            const SizedBox(height: 6),
            for (final d in compat.details)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('· ',
                        style: TextStyle(fontSize: 13, color: AppTheme.sub)),
                    Expanded(
                      child: Text(d,
                          style:
                              const TextStyle(fontSize: 13, height: 1.45)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 오행 분포 한 행 (이름 반영 전 → 후)
class _ElementRow extends StatelessWidget {
  final String element;
  final int before;
  final int after;
  const _ElementRow(
      {required this.element, required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    final added = after > before;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          ElementChip(element),
          const SizedBox(width: 10),
          Text(elementNames[element] ?? element,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$before개',
              style: const TextStyle(fontSize: 13, color: AppTheme.sub)),
          const Icon(Icons.arrow_right, size: 16, color: AppTheme.sub),
          Text(
            '$after개',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: added ? AppTheme.primary : AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
