import 'package:flutter/material.dart';
import '../data/pure_korean_names.dart';
import '../engine/generator.dart';
import '../engine/saju.dart';
import '../models.dart';
import '../services/ad_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

/// 이름 추천 결과
class RecommendScreen extends StatefulWidget {
  final BabyInfo baby;
  final SajuResult saju;
  final bool isPureKorean;
  const RecommendScreen(
      {super.key,
      required this.baby,
      required this.saju,
      this.isPureKorean = false});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  late final List<NameAnalysis> _names;
  String _sort = 'total';

  @override
  void initState() {
    super.initState();
    _names = widget.isPureKorean
        ? generatePureKoreanNames(widget.baby, widget.saju)
        : generateNames(widget.baby, widget.saju);
  }

  List<NameAnalysis> get _sorted {
    final list = List<NameAnalysis>.of(_names);
    switch (_sort) {
      case 'suri':
        list.sort((a, b) => b.suri.score.compareTo(a.suri.score));
        break;
      case 'resource':
        list.sort((a, b) => b.resource.score.compareTo(a.resource.score));
        break;
      case 'sound':
        list.sort((a, b) => b.sound.score.compareTo(a.sound.score));
        break;
      default:
        list.sort((a, b) => b.total.compareTo(a.total));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final saju = widget.saju;
    final sorted = _sorted;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.baby.surname}○○ · ${widget.baby.gender.label} 이름 추천'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          // 사주 요약
          Card(
            color: AppTheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PillarBox(p: saju.year, label: '년주'),
                      _PillarBox(p: saju.month, label: '월주'),
                      _PillarBox(p: saju.day, label: '일주'),
                      if (saju.hour != null)
                        _PillarBox(p: saju.hour!, label: '시주'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                          '일간 ${saju.dayMaster}(${elementNames[saju.dayElement]})'),
                      _InfoChip(saju.strongBody ? '신강' : '신약'),
                      if (saju.yongsin != null)
                        _InfoChip(
                            '용신 ${elementNames[saju.yongsin]}', highlight: true),
                      if (saju.huishin != null)
                        _InfoChip('희신 ${elementNames[saju.huishin]}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    saju.yongsin != null
                        ? (widget.isPureKorean
                            ? '사주에 ${elementNames[saju.yongsin]} 기운이 필요해 초성의 발음오행이 맞는 이름 위주로 골랐어요.'
                            : '사주에 ${elementNames[saju.yongsin]} 기운이 필요해 이 기운을 담은 한자 위주로 골랐어요.')
                        : '사주를 바탕으로 이름 후보를 점수화했어요.',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 정렬
          Row(
            children: [
              Text('총 ${sorted.length}개 후보',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.sub,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              DropdownButton<String>(
                value: _sort,
                underline: const SizedBox(),
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(
                      value: 'total', child: Text('종합점수순')),
                  DropdownMenuItem(value: 'suri', child: Text('수리순')),
                  DropdownMenuItem(
                      value: 'resource', child: Text('사주 보완순')),
                  DropdownMenuItem(value: 'sound', child: Text('발음순')),
                ],
                onChanged: (v) => setState(() => _sort = v!),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 후보 리스트 (현재 전체 무료 공개)
          ...sorted.asMap().entries.map((e) {
            final i = e.key;
            final a = e.value;
            return _NameCard(
              rank: i + 1,
              analysis: a,
              baby: widget.baby,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(
                        baby: widget.baby, analysis: a),
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 8),
          const Text(
            '점수는 전통 성명학의 간이 계산 결과예요. 마음에 드는 이름을 눌러 상세 풀이를 확인하세요.',
            style: TextStyle(fontSize: 11, color: AppTheme.sub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // 하단 배너 광고 (AdService.bannerEnabled 플래그로 제어)
          if (AdService.bannerEnabledFor(AdPlacement.home))
            const Center(child: BannerAdWidget()),
        ],
      ),
    );
  }
}

class _PillarBox extends StatelessWidget {
  final SajuPillar p;
  final String label;
  const _PillarBox({required this.p, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.white60)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(p.stem,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text(p.branch,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final bool highlight;
  const _InfoChip(this.label, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.gold
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? AppTheme.ink : Colors.white)),
    );
  }
}

class _NameCard extends StatelessWidget {
  final int rank;
  final NameAnalysis analysis;
  final BabyInfo baby;
  final VoidCallback onTap;
  const _NameCard({
    required this.rank,
    required this.analysis,
    required this.baby,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    // 스크롤 버벅임 방지: 카드별 래스터 캐시를 만들어 스크롤 중 재그리기를 막는다.
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('$rank',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: rank <= 3
                              ? AppTheme.gold
                              : AppTheme.sub)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(a.fullName,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          if (a.isPureKorean)
                            Flexible(
                              child: Text(
                                  pureKoreanMeaning(a.givenName) ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppTheme.sub)),
                            )
                          else
                            Flexible(
                              child: Text(a.hanjaName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14, color: AppTheme.sub)),
                            ),
                          if (a.rankBoy != null || a.rankGirl != null) ...[
                            const SizedBox(width: 6),
                            const GradeChip('흔한 이름', AppTheme.warn),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: a.dimensions.map((d) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.scoreColor(d.score),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(d.title,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.sub)),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                ScoreRing(score: a.total, size: 64, strokeWidth: 7),
                const Icon(Icons.chevron_right,
                    color: AppTheme.sub),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


