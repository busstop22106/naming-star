import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/services/share_link.dart';

/// 테스트용 토큰 직접 만들기 (디코더 검증용 — 인코더를 거치지 않는다).
String _tokenOf(String payload) =>
    '1${base64Url.encode(utf8.encode(payload)).replaceAll('=', '')}';

void main() {
  group('공유 토큰 인코딩·디코딩', () {
    test('전체 파라미터 왕복이 된다', () {
      final params = SharedNameParams(
        name: '김도윤',
        birth: DateTime(2025, 3, 15),
        hour: 14,
        gender: Gender.boy,
        surnameHanja: '金',
        hanja: '道允',
      );
      final token = encodeShareToken(params);
      expect(token[0], '1');
      expect(token.contains('='), isFalse);
      expect(decodeShareToken(token), params);
    });

    test('생시를 모르면 시간 필드가 비어서 왕복된다', () {
      final params = SharedNameParams(
        name: '김도윤',
        birth: DateTime(2025, 3, 15),
        gender: Gender.girl,
        surnameHanja: '金',
        hanja: '道允',
      );
      expect(decodeShareToken(encodeShareToken(params)), params);
    });

    test('순우리말은 한자 필드가 비어서 왕복된다', () {
      final params = SharedNameParams(
        name: '김하늘',
        birth: DateTime(2025, 3, 15),
        hour: 10,
        gender: Gender.girl,
      );
      final token = encodeShareToken(params);
      final decoded = decodeShareToken(token);
      expect(decoded, params);
      expect(decoded?.surnameHanja, isNull);
      expect(decoded?.hanja, isNull);
    });

    test('2자 성씨 이름도 왕복된다', () {
      final params = SharedNameParams(
        name: '남궁도윤',
        birth: DateTime(2025, 3, 15),
        hour: 10,
        gender: Gender.girl,
        surnameHanja: '南',
        hanja: '道允',
      );
      expect(decodeShareToken(encodeShareToken(params)), params);
    });

    test('잘못된 토큰은 null이다', () {
      expect(decodeShareToken(''), isNull);
      expect(decodeShareToken('1'), isNull);
      // 버전이 1이 아님
      expect(decodeShareToken(_tokenOf('김도윤|20250315|14|boy|金|道允')
          .replaceFirst('1', '2')), isNull);
      // base64가 아님
      expect(decodeShareToken('1!!!'), isNull);
      // 필드 개수 부족
      expect(decodeShareToken(_tokenOf('김도윤|20250315|14|boy')), isNull);
      // 이름이 2자
      expect(
          decodeShareToken(_tokenOf('김도|20250315|14|boy|金|道允')), isNull);
      // 없는 날짜
      expect(decodeShareToken(_tokenOf('김도윤|20250230|14|boy|金|道允')),
          isNull);
      // 시간 범위 밖
      expect(
          decodeShareToken(_tokenOf('김도윤|20250315|24|boy|金|道允')), isNull);
      // 성별 오류
      expect(decodeShareToken(_tokenOf('김도윤|20250315|14|unknown|金|道允')),
          isNull);
      // 한자 형식이 틀리면 그 파라미터만 버리고 링크는 산다
      final badHanja =
          decodeShareToken(_tokenOf('김도윤|20250315|14|boy|金|道'));
      expect(badHanja, isNotNull);
      expect(badHanja?.hanja, isNull);
      expect(badHanja?.surnameHanja, '金');
      expect(badHanja?.name, '김도윤');
    });
  });

  group('짧은 링크 파싱', () {
    test('짧은 링크 왕복이 된다', () {
      final params = SharedNameParams(
        name: '김도윤',
        birth: DateTime(2025, 3, 15),
        hour: 14,
        gender: Gender.boy,
        surnameHanja: '金',
        hanja: '道允',
      );
      final uri = buildShortShareUri(params);
      expect(uri.scheme, 'https');
      expect(uri.host, 'jakmyeongbyeol.netlify.app');
      expect(uri.pathSegments.first, 's');
      expect(parseShareUri(uri), params);
    });

    test('Netlify 전체 파라미터 링크도 파싱된다', () {
      final uri = Uri.parse(
          'https://jakmyeongbyeol.netlify.app/share.html?name=%EA%B9%80%EB%8F%84%EC%9C%A4&birth=2025-03-15&hour=14&gender=boy&surname_hanja=%E9%87%91&hanja=%E9%81%93%E5%85%81');
      final parsed = parseShareUri(uri);
      expect(parsed?.name, '김도윤');
      expect(parsed?.surnameHanja, '金');
      expect(parsed?.hanja, '道允');
    });

    test('예전 github.io 링크가 그대로 동작한다', () {
      final uri = Uri.parse(
          'https://busstop22106.github.io/naming-star/share.html?name=%EA%B9%80%EB%8F%84%EC%9C%A4&birth=2025-03-15&hour=14&gender=boy&surname_hanja=%E9%87%91&hanja=%E9%81%93%E5%85%81');
      final parsed = parseShareUri(uri);
      expect(parsed?.name, '김도윤');
      expect(parsed?.surnameHanja, '金');
      expect(parsed?.hanja, '道允');
    });

    test('앱스킴 링크가 그대로 동작한다', () {
      final uri = Uri.parse(
          'jakmyeongbyeol://analyze?name=%EA%B9%80%EB%8F%84%EC%9C%A4&birth=2025-03-15&hour=14&gender=boy');
      final parsed = parseShareUri(uri);
      expect(parsed?.name, '김도윤');
      expect(parsed?.hour, 14);
    });

    test('Netlify 호스트의 엉뚱한 경로는 null이다', () {
      expect(
          parseShareUri(Uri.parse('https://jakmyeongbyeol.netlify.app/')),
          isNull);
      expect(
          parseShareUri(
              Uri.parse('https://jakmyeongbyeol.netlify.app/x/abc')),
          isNull);
    });
  });
}
