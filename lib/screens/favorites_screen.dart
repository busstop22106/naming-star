import 'package:flutter/material.dart';
import '../engine/saju.dart';
import '../engine/scoring.dart';
import '../favorites.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

/// 보관함.
/// [selectMode]가 true면 전면 화면은 그대로지만, 카드를 탭했을 때
/// 상세 화면으로 들어가지 않고 그 항목을 돌려주며 닫힌다.
/// 이름 분석 탭의 '보관함에서 불러오기'가 이 모드로 연다.
class FavoritesScreen extends StatefulWidget {
  final bool selectMode;
  const FavoritesScreen({super.key, this.selectMode = false});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteItem> _items = [];
  bool _loading = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // 저장소 응답이 멈춰도 스피너가 영원히 돌지 않게 5초 제한을 둔다.
      final items =
          await loadFavorites().timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _loadError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = true;
      });
    }
  }

  Future<void> _open(FavoriteItem item) async {
    // 선택 모드에서는 상세로 들어가지 않고 항목을 그대로 돌려준다.
    if (widget.selectMode) {
      if (mounted) Navigator.pop(context, item);
      return;
    }
    final saju = computeSaju(item.baby);
    final analysis = analyzeName(
      surname: item.baby.surname,
      surnameStrokes: item.baby.surnameStrokes,
      picks: item.picks,
      saju: saju,
      gender: item.baby.gender,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetailScreen(baby: item.baby, analysis: analysis),
      ),
    );
    _load(); // 돌아오면 새로고침 (삭제 반영)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('보관함')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError
              ? EmptyState(
                  title: '보관함을 불러오지 못했어요.',
                  subtitle: '저장소 응답이 늦어지고 있어요. 다시 시도해 주세요.',
                  action: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _loadError = false;
                      });
                      _load();
                    },
                    child: const Text('다시 시도'),
                  ),
                )
              : _items.isEmpty
              ? EmptyState(
                  title: '아직 저장한 이름이 없어요.',
                  subtitle: '마음에 드는 이름에서 북마크를 눌러 저장하세요.\n별이 반짝이는 이름, 하나씩 모아보세요.',
                  // 빈 화면은 두 번째 온보딩 — 다음 행동 버튼을 반드시 둔다.
                  action: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('이름 지으러 가기'),
                  ),
                )
              // 성능: 저장 개수가 늘면 한 번에 다 만드는 ListView(children:)가
              // 무거워진다 — 보이는 행만 만드는 builder로 바꾼다.
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _open(item),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.fullName,
                                        style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight:
                                                FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${item.hanjaName} · ${item.baby.gender.label}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.sub)),
                                  ],
                                ),
                              ),
                              ScoreRing(
                                  score: item.total,
                                  size: 56,
                                  strokeWidth: 6),
                              IconButton(
                                icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.sub),
                                onPressed: () async {
                                  // 즉시 삭제하되 실행 취소로 원래 순서 그대로 되돌릴 수 있다.
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final index = i;
                                  final removed = _items.removeAt(index);
                                  await replaceFavorites(_items);
                                  if (!mounted) return;
                                  setState(() {});
                                  // 연타해도 이전 토스트가 뒤에 줄줄이 뜨지 않게
                                  // 대기 중인 토스트를 비우고 새 토스트만 띄운다.
                                  showSingleSnackBar(
                                    messenger,
                                    '보관함에서 삭제했어요.',
                                    action: SnackBarAction(
                                      label: '실행 취소',
                                      onPressed: () async {
                                        final items =
                                            List<FavoriteItem>.of(
                                                _items);
                                        items.insert(
                                            index.clamp(
                                                0, items.length),
                                            removed);
                                        await replaceFavorites(items);
                                        setState(
                                            () => _items = items);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
