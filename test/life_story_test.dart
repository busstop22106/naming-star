import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/engine/compat.dart';
import 'package:jakmyeongbyeol/engine/life_story.dart';
import 'package:jakmyeongbyeol/engine/pure_korean.dart';
import 'package:jakmyeongbyeol/engine/scoring.dart';
import 'package:jakmyeongbyeol/models.dart';

NameAnalysis sample({bool pureKorean = false}) {
  final saju = sajuOfBirth(DateTime(2026, 5, 5), 10);
  return analyzeName(
    surname: '김',
    surnameStrokes: 8,
    saju: saju,
    gender: Gender.boy,
    isPureKorean: pureKorean,
    picks: pureKorean
        ? const [
            HanjaPick(syllable: '하', char: '', meaning: '하늘', strokes: 0, element: '수'),
            HanjaPick(syllable: '늘', char: '', meaning: '늘', strokes: 0, element: '목'),
          ]
        : const [
            HanjaPick(syllable: '도', char: '道', meaning: '길', strokes: 13, element: '화'),
            HanjaPick(syllable: '윤', char: '潤', meaning: '윤택', strokes: 16, element: '수'),
          ],
  );
}

void main() {
  test('일대기는 4단계, 순서·점수 범위·결정성', () {
    final a = sample();
    final stages = buildLifeStory(a);
    expect(stages.length, 4);
    expect(stages.map((s) => s.title).toList(),
        ['유년기', '청년기', '중년기', '말년기']);
    for (final s in stages) {
      expect(s.score, greaterThanOrEqualTo(0));
      expect(s.score, lessThanOrEqualTo(100));
      expect(s.headline.isNotEmpty, true);
      expect(s.body.isNotEmpty, true);
    }
    final again = buildLifeStory(a);
    expect(again.map((s) => s.body).toList(),
        stages.map((s) => s.body).toList());
  });

  test('순우리말 이름에서도 동작', () {
    final a = analyzePureKoreanName(
      surname: '김',
      surnameStrokes: 8,
      givenName: '하늘',
      saju: sajuOfBirth(DateTime(2026, 5, 5), 10),
      gender: Gender.boy,
    );
    final stages = buildLifeStory(a);
    expect(stages.length, 4);
    expect(stages.every((s) => s.body.isNotEmpty), true);
  });

  test('용신이 있으면 청년·중년 풀이에 보완 문장이 들어간다', () {
    final a = sample();
    if (a.saju.yongsin != null) {
      expect(
          stagesContainYongshin(buildLifeStory(a)), true);
    }
  });
}

bool stagesContainYongshin(List<LifeStage> stages) =>
    stages[1].body.contains('사주에 필요한') ||
    stages[2].body.contains('사주에 필요한');
