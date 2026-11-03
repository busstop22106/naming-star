import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/screens/analyze_screen.dart';
import 'package:jakmyeongbyeol/widgets/hanja_picker_sheet.dart';

void main() {
  group('filterHanjaOptions', () {
    test('빈 검색어면 전체를 원래 인덱스와 함께 돌려준다', () {
      final ordered = orderedHanja('윤');
      final filtered = filterHanjaOptions(ordered, '');
      expect(filtered.length, ordered.length);
      for (var i = 0; i < ordered.length; i++) {
        expect(filtered[i].key, i);
        expect(filtered[i].value, ordered[i]);
      }
    });

    test('한자 한 글자로 찾는다', () {
      final ordered = orderedHanja('윤');
      final filtered = filterHanjaOptions(ordered, '尹');
      expect(filtered.length, 1);
      expect(filtered.single.value.char, '尹');
      expect(filtered.single.key,
          ordered.indexWhere((o) => o.char == '尹'));
    });

    test('뜻 부분 일치로 찾는다', () {
      final ordered = orderedHanja('윤');
      final filtered = filterHanjaOptions(ordered, '빛');
      expect(filtered.map((e) => e.value.char).toList(), ['昀']);
    });

    test('획수는 숫자와 "N획" 모두 정확 일치로 찾는다', () {
      final ordered = orderedHanja('윤');
      final byDigits = filterHanjaOptions(ordered, '10');
      final byStrokes = filterHanjaOptions(ordered, '10획');
      expect(byDigits.map((e) => e.value.char).toSet(), {'倫', '倫'});
      expect(byStrokes.map((e) => e.value.char).toSet(), {'倫', '倫'});
      for (final e in byDigits) {
        expect(e.value.strokes, 10);
      }
    });

    test('없는 검색어는 빈 목록을 돌려준다', () {
      expect(filterHanjaOptions(orderedHanja('윤'), 'zzz'), isEmpty);
    });
  });

  group('한자 선택 검색 UI', () {
    testWidgets('모달에서 검색하면 칩이 줄고, 한자는 17pt·획수는 항상 보인다',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: AnalyzeScreen()));
      await tester.pumpAndSettle();

      final nameField = find.byWidgetPredicate((w) =>
          w is TextField && w.decoration?.hintText == '이름 2자 (예: 도윤)');
      await tester.enterText(nameField, '도윤');
      await tester.pumpAndSettle();

      // 두 번째 음절(윤) 행을 탭하면 한자 선택 모달이 열린다.
      final secondRow = find.text('2자');
      expect(secondRow, findsOneWidget);
      await tester.ensureVisible(secondRow);
      await tester.pumpAndSettle();
      await tester.tap(secondRow);
      await tester.pumpAndSettle();

      final searchField = find.byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.hintText == '한자나 뜻으로 검색 (예: 빛, 尹, 10획)');
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, '빛');
      await tester.pumpAndSettle();

      bool richTextContains(String text) => find
          .byWidgetPredicate((w) =>
              w is RichText && w.text.toPlainText().contains(text))
          .evaluate()
          .isNotEmpty;
      // '빛'이 들어간 뜻(햇빛)만 남고, 다른 뜻(젖을)은 사라진다.
      expect(richTextContains('햇빛'), isTrue);
      expect(richTextContains('젖을'), isFalse);
      // 뜻이 있는 칩도 획수를 함께 보여준다.
      expect(richTextContains('햇빛 8획'), isTrue);
      // 한자 글자는 17pt로 보인다.
      final label = tester.widget<RichText>(find.byWidgetPredicate((w) =>
          w is RichText && w.text.toPlainText().contains('햇빛')));
      final spans = (label.text as TextSpan).children!;
      expect((spans.first as TextSpan).style?.fontSize, 17);
    });

    testWidgets('한자가 없는 음절(늘)이면 크래시 없이 안내가 보인다',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: AnalyzeScreen()));
      await tester.pumpAndSettle();

      final nameField = find.byWidgetPredicate((w) =>
          w is TextField && w.decoration?.hintText == '이름 2자 (예: 도윤)');
      await tester.enterText(nameField, '하늘');
      await tester.pumpAndSettle();

      // '늘' 행은 안내만 보이고, '하' 행은 정상적으로 보인다.
      // (예전에는 여기서 clamp(0, -1) 때문에
      // 'Invalid argument(s): 0' 빨간 화면이 떴다.)
      expect(find.text('쓸 수 있는 한자가 없어요'), findsOneWidget);
      expect(find.text('1자'), findsOneWidget);
      expect(find.text('2자'), findsOneWidget);
    });

    testWidgets('모달에서 고르고 내리면 행에 그 한자가 반영된다',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: AnalyzeScreen()));
      await tester.pumpAndSettle();

      final nameField = find.byWidgetPredicate((w) =>
          w is TextField && w.decoration?.hintText == '이름 2자 (예: 도윤)');
      await tester.enterText(nameField, '도윤');
      await tester.pumpAndSettle();

      final secondRow = find.text('2자');
      await tester.ensureVisible(secondRow);
      await tester.pumpAndSettle();
      await tester.tap(secondRow);
      await tester.pumpAndSettle();

      // 潤(젖을 16획)을 고르면 모달은 그대로 열려 있다.
      final runChip = find.byWidgetPredicate((w) =>
          w is RichText && w.text.toPlainText().contains('潤 젖을 16획'));
      await tester.ensureVisible(runChip);
      await tester.pumpAndSettle();
      await tester.tap(runChip);
      await tester.pumpAndSettle();
      expect(find.byType(HanjaPickerSheet), findsOneWidget);

      // 제목을 아래로 끌어 모달을 내리면 행에 潤이 반영된다.
      await tester.drag(
          find.text('윤 한자 선택 (27개)'), const Offset(0, 900));
      await tester.pumpAndSettle();
      expect(find.byType(HanjaPickerSheet), findsNothing);
      expect(find.text('潤'), findsOneWidget);
      expect(find.text('젖을 · 16획'), findsOneWidget);
    });
  });
}
