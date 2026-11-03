import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/engine/scoring.dart';
import 'package:jakmyeongbyeol/favorites.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/screens/detail_screen.dart';
import 'package:jakmyeongbyeol/screens/favorites_screen.dart';

SajuResult fakeSaju() => const SajuResult(
      year: SajuPillar('갑', '진'),
      month: SajuPillar('병', '인'),
      day: SajuPillar('갑', '자'),
      hour: null,
      dayMaster: '갑',
      dayElement: '목',
      elementCounts: {'목': 2, '화': 1, '토': 1, '금': 2, '수': 2},
      strongBody: false,
      yongsin: '수',
      huishin: null,
      johu: null,
      notes: [],
    );

BabyInfo testBaby() => BabyInfo(
      surname: '김',
      surnameHanja: '金',
      surnameStrokes: 8,
      gender: Gender.boy,
      birth: DateTime(2024, 3, 10),
    );

List<HanjaPick> testPicks() => const [
      HanjaPick(
          syllable: '도', char: '度', meaning: '헤아릴', strokes: 9, element: '토'),
      HanjaPick(
          syllable: '윤', char: '潤', meaning: '윤택', strokes: 16, element: '수'),
    ];

NameAnalysis testAnalysis() => analyzeName(
      surname: '김',
      surnameStrokes: 8,
      saju: fakeSaju(),
      gender: Gender.boy,
      picks: testPicks(),
    );

/// 스낵바 큐·진입 애니메이션 때문에 바로 안 보일 수 있어, 최대 2초간 기다린다.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('보관함 저장소', () {
    test('저장→불러오기→삭제 왕복이 된다', () async {
      SharedPreferences.setMockInitialValues({});
      final item = FavoriteItem(
        baby: testBaby(),
        picks: testPicks(),
        total: 91.0,
        savedAt: DateTime(2026, 11, 3, 16, 30),
      );
      expect(await loadFavorites(), isEmpty);
      await saveFavorite(item);
      final loaded = await loadFavorites();
      expect(loaded.length, 1);
      expect(loaded.single.fullName, '김도윤');
      expect(loaded.single.hanjaName, '度潤');
      expect(await isFavorite('김도윤', '度潤'), isTrue);
      await removeFavorite(item);
      expect(await loadFavorites(), isEmpty);
      expect(await isFavorite('김도윤', '度潤'), isFalse);
    });

    test('같은 이름+한자 저장은 중복 없이 하나로 유지된다', () async {
      SharedPreferences.setMockInitialValues({});
      final item = FavoriteItem(
          baby: testBaby(), picks: testPicks(), total: 91.0, savedAt: DateTime.now());
      await saveFavorite(item);
      await saveFavorite(item);
      expect((await loadFavorites()).length, 1);
    });

    test('깨진 저장값은 빈 목록으로 처리한다', () async {
      SharedPreferences.setMockInitialValues(
          {'jakmyeongbyeol_favorites': 'not-json[['});
      expect(await loadFavorites(), isEmpty);
    });
  });

  group('상세 화면 저장 버튼', () {
    Future<void> pumpDetail(WidgetTester tester, {double height = 1400}) async {
      tester.view.physicalSize = Size(390, height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: DetailScreen(baby: testBaby(), analysis: testAnalysis())));
      await tester.pumpAndSettle();
    }

    testWidgets('우상단 북마크를 누르면 저장되고 다시 누르면 삭제된다',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpDetail(tester);
      final bookmark = find.descendant(
          of: find.byType(AppBar), matching: find.byType(IconButton));
      expect(bookmark, findsOneWidget);

      await tester.tap(bookmark);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('보관함에 저장했어요.'), findsOneWidget);
      expect(await isFavorite('김도윤', '度潤'), isTrue);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark), findsWidgets);

      await tester.tap(bookmark);
      // 이전 스낵바가 나가는 애니메이션 뒤에 새 스낵바가 큐에서
      // 나오므로, 보일 때까지 기다린다.
      await pumpUntilFound(tester, find.text('보관함에서 삭제했어요.'));
      expect(find.text('보관함에서 삭제했어요.'), findsOneWidget);
      expect(await isFavorite('김도윤', '度潤'), isFalse);
    });

    testWidgets('하단 저장 버튼을 누르면 저장되고 라벨이 바뀐다',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      // 화면을 길게 잡아 리스트 맨 아래 버튼까지 스크롤 없이 보이게 한다.
      await pumpDetail(tester, height: 4000);
      final saveButton =
          find.widgetWithText(ElevatedButton, '보관함에 저장하기');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('보관함에 저장했어요.'), findsOneWidget);
      expect(await isFavorite('김도윤', '度潤'), isTrue);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, '보관함에 저장됨'),
          findsOneWidget);
    });
  });

  group('보관함 화면', () {
    Future<void> pumpFavorites(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          const MaterialApp(home: FavoritesScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('저장된 이름이 목록에 뜨고 로딩이 끝나 있다',
        (tester) async {
      final item = FavoriteItem(
          baby: testBaby(), picks: testPicks(), total: 91.0, savedAt: DateTime.now());
      SharedPreferences.setMockInitialValues({
        'jakmyeongbyeol_favorites':
            jsonEncode([item.toJson()]),
      });
      await pumpFavorites(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('김도윤'), findsOneWidget);
      expect(find.text('度潤 · 남아'), findsOneWidget);
    });

    testWidgets('빈 보관함은 빈 화면을 보여주고 로딩이 끝나 있다',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpFavorites(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('아직 저장한 이름이 없어요.'), findsOneWidget);
    });

    testWidgets('깨진 저장값이어도 빈 화면을 보여준다', (tester) async {
      SharedPreferences.setMockInitialValues(
          {'jakmyeongbyeol_favorites': 'not-json[['});
      await pumpFavorites(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('아직 저장한 이름이 없어요.'), findsOneWidget);
    });

    testWidgets('목록에서 삭제하면 사라지고 실행 취소하면 돌아온다',
        (tester) async {
      final item = FavoriteItem(
          baby: testBaby(), picks: testPicks(), total: 91.0, savedAt: DateTime.now());
      SharedPreferences.setMockInitialValues({
        'jakmyeongbyeol_favorites': jsonEncode([item.toJson()]),
      });
      await pumpFavorites(tester);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('김도윤'), findsNothing);
      final undoButton = find.ancestor(
          of: find.text('실행 취소'), matching: find.byType(TextButton));
      // 스낵바 액션 버튼이 화면 아래쪽에 걸쳐 있으면 탭이 안 닿으므로,
      // 화면에 들어오게 한 뒤 누른다.
      await tester.ensureVisible(undoButton);
      await tester.pumpAndSettle();
      expect(await loadFavorites(), isEmpty);
      await tester.tap(find.text('실행 취소'));
      await tester.pumpAndSettle();
      expect(find.text('김도윤'), findsOneWidget);
      expect((await loadFavorites()).length, 1);
    });

    testWidgets('목록을 누르면 상세 화면이 열린다', (tester) async {
      final item = FavoriteItem(
          baby: testBaby(), picks: testPicks(), total: 91.0, savedAt: DateTime.now());
      SharedPreferences.setMockInitialValues({
        'jakmyeongbyeol_favorites': jsonEncode([item.toJson()]),
      });
      await pumpFavorites(tester);
      await tester.tap(find.text('김도윤'));
      await tester.pumpAndSettle();
      expect(find.text('이름 상세 분석'), findsOneWidget);
    });
  });
}
