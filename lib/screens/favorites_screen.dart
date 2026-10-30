import 'package:flutter/material.dart';
import '../engine/saju.dart';
import '../engine/scoring.dart';
import '../favorites.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

/// 보관함
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await loadFavorites();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _open(FavoriteItem item) async {
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
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: _items.map((item) {
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
                                  final index = _items.indexOf(item);
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
                  }).toList(),
                ),
    );
  }
}
