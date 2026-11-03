import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/widgets/hanja_picker_sheet.dart';

void main() {
  // '윤'의 한자: 㣧 11획(뜻없음), 䦞 15획(뜻없음), 潤 16획(젖을).
  final opts = orderedHanja('윤');
  final runIdx = opts.indexWhere((o) => o.char == '潤');

  Widget sheet() => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 1200,
            child: HanjaPickerSheet(
                syllable: '윤', options: opts, selectedIndex: runIdx),
          ),
        ),
      );

  // 칩 라벨은 RichText(한자 span + 부가정보 span)라서 전체 문장으로 찾는다.
  Finder richTextContaining(String s) => find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains(s));

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

  testWidgets('시트에서 한자를 고르면 인덱스를 돌려주고 닫힌다', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    int? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              picked = await showModalBottomSheet<int>(
                context: ctx,
                isScrollControlled: true,
                builder: (_) => SizedBox(
                  height: 1000,
                  child: HanjaPickerSheet(
                      syllable: '윤',
                      options: opts,
                      selectedIndex: runIdx),
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
    final runChip = richTextContaining('潤 젖을 16획');
    await tester.ensureVisible(runChip);
    await tester.pumpAndSettle();
    await tester.tap(runChip);
    await tester.pumpAndSettle();
    expect(picked, runIdx);
    expect(find.byType(HanjaPickerSheet), findsNothing);
  });
}
