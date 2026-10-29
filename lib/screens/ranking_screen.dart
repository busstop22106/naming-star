import 'package:flutter/material.dart';
import '../data/rankings.dart';
import '../services/ad_service.dart';
import '../theme.dart';

/// 아기 이름 랭킹
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _year = latestRankingYear;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tab.indexIsChanging && _tab.index != _tabIndex) {
      setState(() => _tabIndex = _tab.index);
    }
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아기 이름 랭킹'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.sub,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: '남아 TOP 20'),
            Tab(text: '여아 TOP 20'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 연도 선택
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                const Text('연도별 순위',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.sub,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                DropdownButton<int>(
                  value: _year,
                  underline: const SizedBox(),
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w700),
                  items: rankingYears
                      .map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y년')))
                      .toList(),
                  onChanged: (v) => setState(() => _year = v!),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _RankList(
                    entries: rankingsByYear[_year]!.boy,
                    isBoy: true,
                    year: _year,
                    showAd: _tabIndex == 0),
                _RankList(
                    entries: rankingsByYear[_year]!.girl,
                    isBoy: false,
                    year: _year,
                    showAd: _tabIndex == 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankList extends StatelessWidget {
  final List<RankEntry> entries;
  final bool isBoy;
  final int year;

  /// 선택된 탭의 리스트에만 배너를 둔다 (화면에 배너는 항상 1개).
  final bool showAd;
  const _RankList(
      {required this.entries,
      required this.isBoy,
      required this.year,
      this.showAd = false});

  @override
  Widget build(BuildContext context) {
    final maxCount =
        entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    return ListView(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      children: [
        // 트렌드 카드 (성별별로 데이터에서 자동 생성)
        Card(
          color: isBoy ? AppTheme.boy : AppTheme.girl,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text('$year년 ${isBoy ? '남아' : '여아'} 트렌드',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(trendLines(year, boy: isBoy).join(' '),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white, height: 1.6)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text('${e.rank}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: e.rank <= 3 ? AppTheme.gold : AppTheme.sub)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(e.name,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Text('${e.count}명',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.sub)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.count / maxCount,
                          minHeight: 6,
                          backgroundColor: AppTheme.line,
                          valueColor: AlwaysStoppedAnimation(
                              isBoy ? AppTheme.boy : AppTheme.girl),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text('랭킹 읽는 법',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '· 출처: ${rankingSourceFor(year)}\n'
                '· 건수는 집계 시점에 따라 발표 수치와 조금 다를 수 있어요.\n'
                '· TOP 20에 든 이름은 또래에 같은 이름이 많을 수 있어요. '
                '작명별 추천에서는 이런 이름에 사용성 점수 조정이 들어갑니다.',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.sub, height: 1.6),
              ),
            ],
          ),
        ),
        // 하단 배너 광고: 다른 탭처럼 리스트 최하단에서만 보인다.
        // AdService.bannerEnabled 플래그로 제어 (출시 초기에는 랭킹만 노출).
        if (showAd &&
            AdService.bannerEnabledFor(AdPlacement.ranking)) ...[
          const SizedBox(height: 16),
          const Center(
              child: BannerAdWidget(placement: AdPlacement.ranking)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
