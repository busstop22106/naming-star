import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/widgets/hanja_picker_sheet.dart';

void main() {
  // '윤'의 한자: 㣧 11획(뜻없음), 䦞 15획(뜻없음), 潤 16획(젖을).
  final yoonOpts = orderedHanja('윤');
  final runIdx = yoonOpts.indexWhere((o) => o.char == '潤');

  // 칩 라벨은 RichText(한자 span + 부가정보 span)라서 전체 문장으로 찾는다.
  Finder richTextContaining(String s) => find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains(s));

  Widget sheet({ValueChanged<int>? onSelected}) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 1200,
            child: HanjaPickerSheet(
              syllable: '윤',
              options: yoonOpts,
              selectedIndex: runIdx,
              onSelected: onSelected ?? (_) {},
            ),
          ),
        ),
      );

  testWidgets('뜻 없는 한자는 뜻없음으로 보인다', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(sheet());
    await tester.pumpAndSettle();
    expect(richTextContaining('㣧 뜻없음 11획'), findsWidgets);
    expect(richTextContaining('䦞 뜻없음 15획'), findsWidgets);
  });

  testWidgets('검색하면 획수가 맞는 한자만 남는다', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(sheet());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '11');
    await tester.pumpAndSettle();
    expect(richTextContaining('㣧 뜻없음 11획'), findsWidgets);
    expect(richTextContaining('潤 젖을 16획'), findsNothing);
  });

  testWidgets('처음부터 전체 목록을 스크롤할 수 있다', (tester) async {
    // '도'는 64개라 '더 보기' 분할이 있던 시절에는 첫 페이지 뒤에
    // 남았다. 이제는 분할 없이 64개가 한 번에 보인다.
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 1200,
          child: HanjaPickerSheet(
            syllable: '도',
            options: orderedHanja('도'),
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNWidgets(64));
    expect(find.textContaining('더 보기'), findsNothing);
  });

  testWidgets('고르면 시트가 닫히지 않고 선택이 바깥에 전달된다', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    int? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              await showModalBottomSheet<void>(
                context: ctx,
                isScrollControlled: true,
                builder: (_) => SizedBox(
                  height: 1000,
                  child: HanjaPickerSheet(
                    syllable: '윤',
                    options: yoonOpts,
                    selectedIndex: runIdx,
                    onSelected: (i) => picked = i,
                  ),
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.byType(HanjaPickerSheet), findsOneWidget);
    // 潤이 아닌 다른 한자(倫)를 고른다.
    final otherIdx = yoonOpts.indexWhere((o) => o.char == '倫');
    final otherChip = richTextContaining('倫 인륜 10획');
    await tester.ensureVisible(otherChip);
    await tester.pumpAndSettle();
    await tester.tap(otherChip);
    await tester.pumpAndSettle();
    // 시트는 그대로 열려 있고, 선택은 바깥에 전달됐다.
    expect(find.byType(HanjaPickerSheet), findsOneWidget);
    expect(picked, otherIdx);
    // 선택된 칩은 체크가 아니라 보라색 테두리다.
    final chip = tester.widget<ChoiceChip>(find.ancestor(
        of: otherChip, matching: find.byType(ChoiceChip)));
    expect(chip.showCheckmark, isFalse);
    expect(chip.side?.color, const Color(0xFF5B4DBC));
    expect(chip.side?.width, 1.5);
    // 제목을 아래로 끌면 시트가 닫힌다.
    await tester.drag(find.text('윤 한자 선택 (27개)'), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.byType(HanjaPickerSheet), findsNothing);
  });
}
