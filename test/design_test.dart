import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/widgets/common.dart';

void main() {
  testWidgets('StarHero가 별 이미지와 문구를 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StarHero(title: '작명별', subtitle: '사주와 성명학으로 짓는 아기 이름'),
      ),
    ));
    expect(find.text('작명별'), findsOneWidget);
    expect(find.text('사주와 성명학으로 짓는 아기 이름'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('EmptyState가 별 이미지와 안내 문구를 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EmptyState(title: '아직 저장한 이름이 없어요.', subtitle: '북마크를 눌러 저장하세요.'),
      ),
    ));
    expect(find.text('아직 저장한 이름이 없어요.'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('SectionCard 아이콘이 둥근 칩 안에 들어간다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SectionCard(
          title: '종합 평가',
          icon: Icons.auto_awesome,
          child: Text('내용'),
        ),
      ),
    ));
    expect(find.text('종합 평가'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}
