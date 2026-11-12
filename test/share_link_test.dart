import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
