import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/screens/detail_screen.dart';
import 'package:jakmyeongbyeol/services/share_link.dart';
import 'package:jakmyeongbyeol/theme.dart';

void main() {
  group('공유 링크 생성·파싱', () {
    final params = SharedNameParams(
      name: '김도윤',
      birth: DateTime(2025, 3, 15),
      hour: 14,
      gender: Gender.boy,
    );

    test('https 공유 링크 왕복이 된다', () {
      final uri = buildShareUri(params);
      expect(uri.scheme, 'https');
      expect(uri.host, 'busstop22106.github.io');
      expect(uri.path, '/naming-star/share.html');
      expect(parseShareUri(uri), params);
    });

    test('앱스킴 링크 왕복이 된다', () {
      final uri = buildAppUri(params);
      expect(uri.scheme, 'jakmyeongbyeol');
      expect(uri.host, 'analyze');
      expect(parseShareUri(uri), params);
    });

    test('한글 이름이 URL 인코딩되고 다시 풀린다', () {
      final uri = buildShareUri(params);
      expect(uri.toString(), contains('%'));
      expect(uri.toString(), isNot(contains('김도윤')));
      expect(parseShareUri(uri)?.name, '김도윤');
    });

    test('생시를 모르면 hour 파라미터가 빠진다', () {
      final noHour = SharedNameParams(
        name: '김도윤',
        birth: DateTime(2025, 3, 15),
        gender: Gender.girl,
      );
      final uri = buildShareUri(noHour);
      expect(uri.queryParameters.containsKey('hour'), isFalse);
      final parsed = parseShareUri(uri);
      expect(parsed?.hour, isNull);
      expect(parsed?.gender, Gender.girl);
    });

    test('잘못된 파라미터는 null로 거른다', () {
      // 엉뚱한 스킴·호스트
      expect(parseShareUri(Uri.parse('https://example.com/share.html?name=김도윤&birth=2025-03-15&gender=boy')), isNull);
      expect(parseShareUri(Uri.parse('jakmyeongbyeol://other?name=김도윤&birth=2025-03-15&gender=boy')), isNull);
      // 이름 누락·형식 오류
      expect(parseShareUri(Uri.parse('jakmyeongbyeol://analyze?birth=2025-03-15&gender=boy')), isNull);
      expect(parseShareUri(Uri.parse('jakmyeongbyeol://analyze?name=김도&birth=2025-03-15&gender=boy')), isNull);
      expect(parseShareUri(Uri.parse('jakmyeongbyeol://analyze?name=KimDo&birth=2025-03-15&gender=boy')), isNull);
      // 생일 형식 오류·없는 날짜
      expect(parseShareUri(Uri.parse('jakmyeongbyeol://analyze?name=김도윤&birth=2025-3-15&gender=boy')), isNull);
      expect(parseShareUri(Uri.parse('jakmyeongbyeol://analyze?name=김도윤&birth=2025-02-30&gender=boy')), isNull);
      // 시간 범위 밖·성별 오류
      expect(parseShareUri(Uri.parse('jakmyeongbyeol://analyze?name=김도윤&birth=2025-03-15&hour=24&gender=boy')), isNull);
      expect(parseShareUri(Uri.parse('jakmyeongbyeol://analyze?name=김도윤&birth=2025-03-15&gender=unknown')), isNull);
    });
  });

  group('공유 링크 분석 복원', () {
    test('김도윤을 기본 한자로 분석해 복원한다', () {
      final params = SharedNameParams(
        name: '김도윤',
        birth: DateTime(2025, 3, 15),
        hour: 14,
        gender: Gender.boy,
      );
      final resolved = resolveSharedAnalysis(params);
      expect(resolved, isNotNull);
      expect(resolved!.baby.surname, '김');
      expect(resolved.baby.birthHour, 14);
      expect(resolved.analysis.fullName, '김도윤');
      expect(resolved.analysis.total, greaterThan(0));
      expect(resolved.analysis.total, lessThanOrEqualTo(100));
    });

    test('2자 성씨 이름도 복원한다', () {
      final params = SharedNameParams(
        name: '남궁도윤',
        birth: DateTime(2025, 3, 15),
        hour: 10,
        gender: Gender.girl,
      );
      final resolved = resolveSharedAnalysis(params);
      expect(resolved, isNotNull);
      expect(resolved!.analysis.fullName, '남궁도윤');
    });

    test('성씨가 DB에 없으면 null이다', () {
      final params = SharedNameParams(
        name: '즐도윤',
        birth: DateTime(2025, 3, 15),
        hour: 10,
        gender: Gender.boy,
      );
      expect(resolveSharedAnalysis(params), isNull);
    });

    test('한자 없는 음절은 순우리말 분석으로 복원한다', () {
      final params = SharedNameParams(
        name: '김하늘',
        birth: DateTime(2025, 3, 15),
        hour: 10,
        gender: Gender.girl,
      );
      final resolved = resolveSharedAnalysis(params);
      expect(resolved, isNotNull);
      expect(resolved!.analysis.fullName, '김하늘');
      expect(resolved.analysis.isPureKorean, isTrue);
    });
  });

  group('한자 선택 공유', () {
    test('한자 포함 링크 왕복이 된다', () {
      final params = SharedNameParams(
        name: '김도윤',
        birth: DateTime(2025, 3, 15),
        hour: 14,
        gender: Gender.boy,
        surnameHanja: '金',
        hanja: '道允',
      );
      final httpsUri = buildShareUri(params);
      expect(httpsUri.queryParameters['surname_hanja'], '金');
      expect(httpsUri.queryParameters['hanja'], '道允');
      expect(parseShareUri(httpsUri), params);
      expect(parseShareUri(buildAppUri(params)), params);
    });

    test('공유된 한자 선택대로 분석이 복원된다', () {
      // 첫 번째 후보가 아닌 한자를 골라 기본값과 달라지는지 확인한다.
      final doOpts = orderedHanja('도');
      final yunOpts = orderedHanja('윤');
      final doChosen = doOpts.last;
      final yunChosen = yunOpts.last;
      expect(doChosen.char, isNot(doOpts.first.char));
      final params = SharedNameParams(
        name: '김도윤',
        birth: DateTime(2025, 3, 15),
        hour: 14,
        gender: Gender.boy,
        surnameHanja: '金',
        hanja: doChosen.char + yunChosen.char,
      );
      final resolved = resolveSharedAnalysis(params);
      expect(resolved, isNotNull);
      expect(resolved!.analysis.picks[0].char, doChosen.char);
      expect(resolved.analysis.picks[1].char, yunChosen.char);
      // 상세 화면에서 다시 공유해도 같은 한자가 담긴다.
      final reshared =
          SharedNameParams.fromBabyAndAnalysis(resolved.baby, resolved.analysis);
      expect(reshared.surnameHanja, '金');
      expect(reshared.hanja, doChosen.char + yunChosen.char);
    });

    test('공유된 성씨 한자대로 획수가 복원된다', () {
      final params = SharedNameParams(
        name: '기서준',
        birth: DateTime(2025, 3, 15),
        hour: 10,
        gender: Gender.boy,
        surnameHanja: '箕',
      );
      final resolved = resolveSharedAnalysis(params);
      expect(resolved, isNotNull);
      expect(resolved!.baby.surnameHanja, '箕');
      expect(resolved.baby.surnameStrokes, 14);
    });

    test('목록에 없는 성씨 한자는 첫 번째 항목으로 떨어진다', () {
      final params = SharedNameParams(
        name: '기서준',
        birth: DateTime(2025, 3, 15),
        hour: 10,
        gender: Gender.boy,
        surnameHanja: '金',
      );
      final resolved = resolveSharedAnalysis(params);
      expect(resolved, isNotNull);
      expect(resolved!.baby.surnameHanja, '奇');
      expect(resolved.baby.surnameStrokes, 8);
    });

    test('틀린 한자 파라미터는 그 파라미터만 무시하고 링크는 살린다', () {
      const base =
          'jakmyeongbyeol://analyze?name=김도윤&birth=2025-03-15&gender=boy';
      final badHanja = parseShareUri(Uri.parse('$base&hanja=XYZ'));
      expect(badHanja, isNotNull);
      expect(badHanja!.hanja, isNull);
      expect(badHanja.name, '김도윤');
      expect(parseShareUri(Uri.parse('$base&hanja=道'))?.hanja, isNull);
      expect(
          parseShareUri(Uri.parse('$base&surname_hanja=AB'))?.surnameHanja,
          isNull);
      final good = parseShareUri(
          Uri.parse('$base&surname_hanja=金&hanja=道允'));
      expect(good?.surnameHanja, '金');
      expect(good?.hanja, '道允');
    });

    test('순우리말이면 한자 파라미터가 생략된다', () {
      final params = SharedNameParams(
        name: '김하늘',
        birth: DateTime(2025, 3, 15),
        hour: 10,
        gender: Gender.girl,
      );
      final resolved = resolveSharedAnalysis(params)!;
      expect(resolved.analysis.isPureKorean, isTrue);
      final shared =
          SharedNameParams.fromBabyAndAnalysis(resolved.baby, resolved.analysis);
      final uri = buildShareUri(shared);
      expect(uri.queryParameters.containsKey('hanja'), isFalse);
      expect(uri.queryParameters.containsKey('surname_hanja'), isFalse);
    });

    test('한자 파라미터 없는 예전 링크도 동작한다', () {
      final parsed = parseShareUri(Uri.parse(
          'https://busstop22106.github.io/naming-star/share.html?name=%EA%B9%80%EB%8F%84%EC%9C%A4&birth=2025-03-15&hour=14&gender=boy'));
      expect(parsed, isNotNull);
      expect(parsed!.surnameHanja, isNull);
      expect(parsed.hanja, isNull);
      final resolved = resolveSharedAnalysis(parsed);
      expect(resolved, isNotNull);
      expect(resolved!.analysis.picks[0].char, orderedHanja('도').first.char);
    });
  });

  group('상세 화면 공유 버튼', () {
    testWidgets('상세 화면 앱바에 공유 버튼이 있다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final params = SharedNameParams(
        name: '김도윤',
        birth: DateTime(2025, 3, 15),
        hour: 14,
        gender: Gender.boy,
      );
      final resolved = resolveSharedAnalysis(params)!;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: DetailScreen(
            baby: resolved.baby,
            analysis: resolved.analysis,
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
    });
  });
}
