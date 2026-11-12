import 'dart:async';

import 'package:flutter/material.dart';
import '../data/pure_korean_names.dart';
import '../engine/generator.dart';
import '../engine/reason_line.dart';
import '../engine/saju.dart';
import '../models.dart';
import '../services/ad_service.dart';
import '../services/adfree_service.dart';
import '../services/purchase_service.dart';
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
  // 이동 중 연타 가드 — 카드를 연타하면 상세 화면이 2장 쌓인다.
  bool _navigating = false;

  /// 보상형 광고를 보고 공개한 1위 이름 (fullName).
  /// 화면 메모리에만 둔다 — 화면을 나가면 다시 가려진다.
  /// 정렬을 바꿔 1위가 달라지면, 공개한 이름이 아닌 카드는 다시 가려진다.
  String? _revealedTopName;

  /// 보상형 광고 표시 중 연타 가드.
  bool _rewardedBusy = false;

  /// 1위 확인 다이얼로그가 열려 있는지 (구매 완료 시 닫기 위해).
  bool _topDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _names = widget.isPureKorean
        ? generatePureKoreanNames(widget.baby, widget.saju)
        : generateNames(widget.baby, widget.saju);
    AdFreeService.instance.isAdFreeNotifier.addListener(_onAdFreeChanged);
    PurchaseService.instance.errorNotifier.addListener(_onPurchaseError);
  }

  @override
  void dispose() {
    AdFreeService.instance.isAdFreeNotifier.removeListener(_onAdFreeChanged);
    PurchaseService.instance.errorNotifier.removeListener(_onPurchaseError);
    super.dispose();
  }

  /// 평생 광고 제거를 구매하면 1위 결과를 가리지 않는다.
  /// 다이얼로그가 열려 있으면 닫고 공개를 알린다.
  void _onAdFreeChanged() {
    if (!mounted || !AdFreeService.instance.isAdFree) return;
    final messenger = ScaffoldMessenger.of(context);
    if (_topDialogOpen) {
      _topDialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
    setState(() {});
    showSingleSnackBar(messenger, '평생 광고 없이 사용 중이에요. 1위 결과를 공개했어요.');
  }

  /// 구매 실패·취소 메시지를 스낵바로 보여준다.
  void _onPurchaseError() {
    final error = PurchaseService.instance.errorNotifier.value;
    if (error == null || !mounted) return;
    PurchaseService.instance.errorNotifier.value = null;
    showSingleSnackBar(ScaffoldMessenger.of(context), error);
  }

  /// 상세 화면으로 이동한다. 이동 중에는 다시 눌러도 무시한다.
  Future<void> _openDetail(NameAnalysis a) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(baby: widget.baby, analysis: a),
      ),
    );
    if (mounted) setState(() => _navigating = false);
  }

  /// 1위 카드가 가려져 있는지 (광고 제거 상태면 절대 가리지 않는다).
  bool _isTopMasked(NameAnalysis a) =>
      _revealedTopName != a.fullName && !AdFreeService.instance.isAdFree;

  /// 1위 확인 다이얼로그를 띄운다. 보상형 광고를 미리 로드해 둔다.
  Future<void> _showTopResultDialog(NameAnalysis top) async {
    _topDialogOpen = true;
    // 다이얼로그를 여는 동안 다음 광고를 미리 받아둔다.
    unawaited(AdService.loadRewardedAd());
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('1위 이름 확인하기'),
        content: const Text(
            '광고를 끝까지 보면 1위 이름을 바로 확인할 수 있어요.\n평생 광고 없이 사용하기를 구매하면 1위 결과가 항상 공개돼요.'),
        actions: [
          TextButton(
            onPressed: () {
              _topDialogOpen = false;
              Navigator.pop(dialogContext);
            },
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () async {
              // 구매 결과는 스트림으로 오고, 완료되면 _onAdFreeChanged가
              // 다이얼로그를 닫는다. 취소·실패는 스낵바로 안내한다.
              await PurchaseService.instance.buyAdFree();
            },
            child: Text(
                '평생 광고 없이 보기 ${PurchaseService.instance.price}'),
          ),
          FilledButton(
            onPressed: _rewardedBusy
                ? null
                : () async {
                    _rewardedBusy = true;
                    final result = await AdService.showRewardedAd();
                    _rewardedBusy = false;
                    if (!mounted || !dialogContext.mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    switch (result) {
                      case RewardedAdResult.earned:
                        setState(() => _revealedTopName = top.fullName);
                        _topDialogOpen = false;
                        Navigator.pop(dialogContext);
                        showSingleSnackBar(messenger, '1위 결과를 공개했어요.');
                      case RewardedAdResult.dismissed:
                        showSingleSnackBar(
                            messenger, '광고를 끝까지 봐야 1위 결과를 볼 수 있어요.');
                      case RewardedAdResult.unavailable:
                        showSingleSnackBar(messenger,
                            '광고를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.');
                    }
                  },
            child: const Text('광고 보고 바로 확인하기'),
          ),
        ],
      ),
    );
    _topDialogOpen = false;
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

    // 성능: 60개 카드를 한 번에 다 만드는 ListView(children:)는 진입·정렬 변경
    // 때마다 60개를 전부 빌드해서 저사양 기기에서 버벅인다.
    // CustomScrollView + SliverList.builder로 화면에 보이는 것만 만든다.
    final showBanner = AdService.bannerEnabledFor(AdPlacement.home);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.baby.surname}○○ · ${widget.baby.gender.label} 이름 추천'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // 사주 요약 — 밤하늘 그라데이션 카드 (흰 글자는 네이비 위 13.95:1)
                  Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.deepNavy, AppTheme.deepNavyDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.deepBorder),
            ),
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
                        fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
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
                          DropdownMenuItem(
                              value: 'suri', child: Text('수리순')),
                          DropdownMenuItem(
                              value: 'resource',
                              child: Text('사주 보완순')),
                          DropdownMenuItem(
                              value: 'sound', child: Text('발음순')),
                        ],
                        onChanged: (v) => setState(() => _sort = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          // 후보 리스트 (현재 전체 무료 공개) — 보이는 것만 만든다.
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final a = sorted[i];
                // 1위(정렬 첫 항목)만 가린다. 공개한 이름·광고 제거 상태는 제외.
                final masked = i == 0 && _isTopMasked(a);
                return _NameCard(
                  rank: i + 1,
                  analysis: a,
                  baby: widget.baby,
                  masked: masked,
                  onTap: masked
                      ? () => _showTopResultDialog(a)
                      : () => _openDetail(a),
                );
              },
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const Text(
                    '점수는 전통 성명학의 간이 계산 결과예요. 마음에 드는 이름을 눌러 상세 풀이를 확인하세요.',
                    style: TextStyle(fontSize: 11, color: AppTheme.sub),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // 하단 배너 광고 (AdService.bannerEnabled 플래그로 제어)
                  if (showBanner)
                    const Center(child: BannerAdWidget()),
                ],
              ),
            ),
          ),
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
              // white60은 primary 위에서 3.45:1로 AA 미달이라 흰색으로 바꿨다.
              style: const TextStyle(
                  fontSize: 11, color: Colors.white)),
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
              // 금색 칩 위 글자는 어두운 색이어야 보인다 (onGold 9.32:1).
              color: highlight ? AppTheme.onGold : Colors.white)),
    );
  }
}

/// 추천 이름 카드 — 저장은 상세 화면에서만 한다 (카드 북마크는 2026-10-30 제거).
/// [masked]가 true면 1위 이름·점수를 '???'로 가리고 자물쇠를 보여준다.
/// (한자·뜻·근거 문구는 이름을 유추할 수 있어 함께 숨긴다.)
class _NameCard extends StatelessWidget {
  final int rank;
  final NameAnalysis analysis;
  final BabyInfo baby;
  final bool masked;
  final VoidCallback onTap;
  const _NameCard({
    required this.rank,
    required this.analysis,
    required this.baby,
    this.masked = false,
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
                          // 금색 #FFC53D는 흰 배경 1.58:1로 순위 숫자에 쓸 수
                          // 없어 진한 primaryDark로 바꿨다. 금색은 별·아이콘
                          // 같은 큰 그래픽 요소에만 쓴다.
                          color: rank <= 3
                              ? AppTheme.primaryDark
                              : AppTheme.sub)),
                ),
                Expanded(
                  child: masked
                      ? const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('???',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 14, color: AppTheme.sub),
                                SizedBox(width: 4),
                                Text('탭해서 1위 이름 확인하기',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.sub,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        )
                      : Column(
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
                                            fontSize: 13,
                                            color: AppTheme.sub)),
                                  )
                                else
                                  Flexible(
                                    child: Text(a.hanjaName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.sub)),
                                  ),
                                if (a.rankBoy != null ||
                                    a.rankGirl != null) ...[
                                  const SizedBox(width: 6),
                                  const GradeChip('흔한 이름', AppTheme.warn),
                                ],
                              ],
                            ),
                            // 한자 뜻 — 리스트에서 뜻을 모르고 일일이 눌러보지 않게 한다.
                            if (!a.isPureKorean &&
                                a.picks.any(
                                    (p) => p.meaning.isNotEmpty)) ...[
                              const SizedBox(height: 4),
                              Text(
                                a.picks
                                    .map((p) => p.meaning.isNotEmpty
                                        ? '${p.char} ${p.meaning}'
                                        : '${p.char} 뜻없음')
                                    .join(' · '),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.sub,
                                    fontFamilyFallback:
                                        AppTheme.hanjaFontFallback),
                              ),
                            ],
                            // 추천 근거 한 줄 — 점수가 뒷받침하는 이유만 문장으로 쓴다.
                            const SizedBox(height: 4),
                            Text(
                              recommendReason(a),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700),
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
                if (masked)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primarySoft,
                    ),
                    child: const Icon(Icons.lock_outline,
                        size: 28, color: AppTheme.gold),
                  )
                else
                  ScoreRing(score: a.total, size: 64, strokeWidth: 7),
                const Icon(Icons.chevron_right, color: AppTheme.sub),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


