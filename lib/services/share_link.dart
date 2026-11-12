// 이름 분석 결과 공유 링크 — 생성·파싱·분석 복원.
//
// 공유되는 짧은 링크 (기본):
//   https://jakmyeongbyeol.netlify.app/s/<토큰>
// 토큰은 파라미터를 통째로 압축한 것으로, 서버 없이 만든다:
//   페이로드 = [전체이름, YYYYMMDD, 시간(없으면 빈칸), gender(boy|girl),
//               성씨한자(없으면 빈칸), 이름한자(없으면 빈칸)] 을 '|'로 연결
//   토큰 = '1'(버전) + base64url(UTF-8(페이로드)), 패딩('=') 제거
//   예: 김도윤|20250315|14|boy|金|道允
// 예전 전체 파라미터 링크도 그대로 받는다:
//   https://busstop22106.github.io/naming-star/share.html?name=...&birth=YYYY-MM-DD&hour=0-23&gender=boy|girl&surname_hanja=金&hanja=道允
//   https://jakmyeongbyeol.netlify.app/share.html?... (같은 전체 파라미터)
// 앱이 받는 앱스킴:
//   jakmyeongbyeol://analyze?name=...&birth=YYYY-MM-DD&hour=0-23&gender=boy|girl&surname_hanja=金&hanja=道允
// hour는 생시를 모르면 생략한다. surname_hanja(성씨 한자 1자)와 hanja(이름
// 한자 2자)는 순우리말이면 생략하고, 없는 예전 링크도 그대로 동작한다.
// 랜딩 페이지(share.html)가 https 링크를 intent:// URL로 바꿔 앱을 열고,
// 앱이 없으면 Play 스토어로 보낸다.
// App Links 검증 파일(assetlinks.json)은 Netlify 사이트 루트에 둔다.
// (github.io 프로젝트 사이트에서는 호스트 루트에 파일을 둘 수 없어 불가했다.)
//
// 순수 Dart — Flutter import 없음. 엔진(사주·채점·한자 정렬)만 재사용한다.
import 'dart:convert';

import '../data/surnames.dart';
import '../engine/hanja_order.dart';
import '../engine/pure_korean.dart';
import '../engine/saju.dart';
import '../engine/scoring.dart';
import '../models.dart';

/// 공유 링크에 담는 분석 조건 (이름·생년월일·시간·성별·한자 선택).
/// share_plus가 export하는 ShareParams와 이름이 겹쳐 SharedNameParams로 둔다.
class SharedNameParams {
  final String name; // 전체 이름 (예: '김도윤')
  final DateTime birth; // 생년월일 (시간 부분은 쓰지 않음)
  final int? hour; // 출생 시 (0-23), 모르면 null
  final Gender gender;
  final String? surnameHanja; // 성씨 한자 1자 (예: '金'), 없으면 null
  final String? hanja; // 이름 한자 2자 연결 (예: '道允'), 없으면 null

  const SharedNameParams({
    required this.name,
    required this.birth,
    this.hour,
    required this.gender,
    this.surnameHanja,
    this.hanja,
  });

  /// 상세 화면의 아기 정보 + 분석 결과에서 공유용 파라미터를 만든다.
  /// 순우리말(이름 한자가 비어 있음)이면 한자 파라미터를 둘 다 생략한다.
  factory SharedNameParams.fromBabyAndAnalysis(
      BabyInfo baby, NameAnalysis analysis) {
    final picks = analysis.picks;
    final hasHanja =
        picks.length == 2 && picks.every((p) => p.char.isNotEmpty);
    return SharedNameParams(
      name: analysis.fullName,
      birth: DateTime(baby.birth.year, baby.birth.month, baby.birth.day),
      hour: baby.birthHour,
      gender: baby.gender,
      // 순우리말이면 성씨 한자도 함께 생략한다 (예전 링크와 같은 기본값 동작).
      surnameHanja: hasHanja && baby.surnameHanja.length == 1
          ? baby.surnameHanja
          : null,
      hanja: hasHanja ? picks.map((p) => p.char).join() : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SharedNameParams &&
      other.name == name &&
      other.birth == birth &&
      other.hour == hour &&
      other.gender == gender &&
      other.surnameHanja == surnameHanja &&
      other.hanja == hanja;

  @override
  int get hashCode =>
      Object.hash(name, birth, hour, gender, surnameHanja, hanja);
}

const String _shareHost = 'busstop22106.github.io';
const String _sharePath = '/naming-star/share.html';

// 짧은 링크 호스트 (Netlify 무료 서브도메인).
// 사이트 이름이 선점돼 jakmyeongbyeol-app으로 만들면 여기도 같이 바꿔야 한다.
const String _shortHost = 'jakmyeongbyeol.netlify.app';
const String _shortPath = '/s/';

Map<String, String> _queryOf(SharedNameParams params) {
  final q = <String, String>{
    'name': params.name,
    'birth':
        '${params.birth.year}-${params.birth.month.toString().padLeft(2, '0')}-${params.birth.day.toString().padLeft(2, '0')}',
    'gender': params.gender.name,
  };
  if (params.hour != null) q['hour'] = params.hour.toString();
  if (params.surnameHanja != null) q['surname_hanja'] = params.surnameHanja!;
  if (params.hanja != null) q['hanja'] = params.hanja!;
  return q;
}

/// 실제로 공유되는 https 링크 (친구가 받는 주소).
Uri buildShareUri(SharedNameParams params) => Uri(
      scheme: 'https',
      host: _shareHost,
      path: _sharePath,
      queryParameters: _queryOf(params),
    );

/// 앱이 직접 받는 앱스킴 링크.
Uri buildAppUri(SharedNameParams params) => Uri(
      scheme: 'jakmyeongbyeol',
      host: 'analyze',
      queryParameters: _queryOf(params),
    );

/// 짧은 링크용 토큰을 만든다.
/// 페이로드 = 이름|YYYYMMDD|시간|성별|성씨한자|이름한자 ('|' 연결, 없는 값은 빈칸).
/// 토큰 = '1'(버전) + base64url(UTF-8(페이로드)), 패딩 제거.
String encodeShareToken(SharedNameParams params) {
  final birth = params.birth;
  final payload = [
    params.name,
    '${birth.year}${birth.month.toString().padLeft(2, '0')}${birth.day.toString().padLeft(2, '0')}',
    params.hour?.toString() ?? '',
    params.gender.name,
    params.surnameHanja ?? '',
    params.hanja ?? '',
  ].join('|');
  final encoded =
      base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
  return '1$encoded';
}

/// 짧은 링크용 토큰을 파라미터로 바꾼다. 형식이 틀리면 null.
SharedNameParams? decodeShareToken(String token) {
  if (token.isEmpty || token[0] != '1') return null;
  final encoded = token.substring(1);
  if (encoded.isEmpty) return null;
  // base64url 패딩 복원 (디코더가 패딩을 요구할 수 있어 명시적으로 채운다).
  final padded = encoded + '=' * ((4 - encoded.length % 4) % 4);
  late final String payload;
  try {
    payload = utf8.decode(base64Url.decode(padded));
  } catch (_) {
    return null;
  }
  final fields = payload.split('|');
  if (fields.length != 6) return null;
  final name = fields[0];
  if (name.length < 3 || name.length > 4) return null;
  if (!RegExp(r'^[가-힣]+$').hasMatch(name)) return null;

  final birthText = fields[1];
  if (!RegExp(r'^\d{8}$').hasMatch(birthText)) return null;
  final birth = DateTime.tryParse(
    '${birthText.substring(0, 4)}-${birthText.substring(4, 6)}-${birthText.substring(6, 8)}',
  );
  if (birth == null) return null;
  if (birth.year != int.parse(birthText.substring(0, 4)) ||
      birth.month != int.parse(birthText.substring(4, 6)) ||
      birth.day != int.parse(birthText.substring(6, 8))) {
    return null;
  }
  if (birth.year < 1900 || birth.year > 2035) return null;

  int? hour;
  final hourText = fields[2];
  if (hourText.isNotEmpty) {
    hour = int.tryParse(hourText);
    if (hour == null || hour < 0 || hour > 23) return null;
  }

  final Gender? gender = switch (fields[3]) {
    'boy' => Gender.boy,
    'girl' => Gender.girl,
    _ => null,
  };
  if (gender == null) return null;

  // 한자 선택: 틀린 값이면 그 파라미터만 버리고 기본값으로 떨어뜨린다.
  final surnameHanjaText = fields[4];
  final String? surnameHanja = surnameHanjaText.isNotEmpty &&
          _isHanja(surnameHanjaText, 1)
      ? surnameHanjaText
      : null;
  final hanjaText = fields[5];
  final String? hanja =
      hanjaText.isNotEmpty && _isHanja(hanjaText, 2) ? hanjaText : null;

  return SharedNameParams(
    name: name,
    birth: DateTime(birth.year, birth.month, birth.day),
    hour: hour,
    gender: gender,
    surnameHanja: surnameHanja,
    hanja: hanja,
  );
}

/// 실제로 공유되는 짧은 링크 (친구가 받는 주소).
/// 예: https://jakmyeongbyeol.netlify.app/s/1...
Uri buildShortShareUri(SharedNameParams params) => Uri(
      scheme: 'https',
      host: _shortHost,
      path: '$_shortPath${encodeShareToken(params)}',
    );

/// [text]가 한자 [count]개로만 이뤄졌는지 확인한다.
/// (CJK 통합 한자 + 호환 한자 범위. 범위를 벗어난 평면 외 한자는 드물어
/// 형식이 틀린 것으로 보고 기본값으로 떨어뜨린다.)
bool _isHanja(String text, int count) {
  if (text.length != count) return false;
  return RegExp(r'^[\u4E00-\u9FFF\uf900-\ufaff]+$').hasMatch(text);
}

/// 앱스킴 링크 또는 https 공유 링크를 파라미터로 바꾼다.
/// 받는 형식:
/// - 앱스킴 `jakmyeongbyeol://analyze?...` (전체 파라미터)
/// - 예전 github.io 전체 파라미터 링크 (`/naming-star/share.html?...`)
/// - Netlify 전체 파라미터 링크 (`/share.html?...`)
/// - Netlify 짧은 링크 (`/s/<토큰>`)
/// 형식이 틀리거나 값이 유효하지 않으면 null (링크를 무시한다).
/// 단, 한자 선택 파라미터가 틀렸을 때는 그 파라미터만 무시하고 기본값으로
/// 떨어뜨린다 — 이름·생년월일이 유효하면 링크는 살린다.
SharedNameParams? parseShareUri(Uri uri) {
  final isAppLink = uri.scheme == 'jakmyeongbyeol' && uri.host == 'analyze';
  final isOldShareLink = uri.scheme == 'https' &&
      uri.host == _shareHost &&
      uri.path == _sharePath;
  final isShortHost = uri.scheme == 'https' && uri.host == _shortHost;
  if (!isAppLink && !isOldShareLink && !isShortHost) return null;

  if (isShortHost) {
    // 짧은 링크: /s/<토큰>
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 's') {
      return decodeShareToken(uri.pathSegments[1]);
    }
    // 전체 파라미터 링크: /share.html?...
    if (uri.path == '/share.html') {
      return _parseQueryParams(uri.queryParameters);
    }
    return null;
  }
  return _parseQueryParams(uri.queryParameters);
}

/// 전체 파라미터 쿼리(name/birth/hour/gender/surname_hanja/hanja)를
/// SharedNameParams로 바꾼다. 핵심 값이 유효하지 않으면 null.
SharedNameParams? _parseQueryParams(Map<String, String> q) {
  final name = q['name'];
  if (name == null || name.length < 3 || name.length > 4) return null;
  if (!RegExp(r'^[가-힣]+$').hasMatch(name)) return null;

  final birthText = q['birth'];
  if (birthText == null ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(birthText)) {
    return null;
  }
  final birth = DateTime.tryParse(birthText);
  if (birth == null) return null;
  // DateTime.tryParse가 2025-02-30 같은 날짜를 넘겨짚지 않게 입력과 대조한다.
  final parts = birthText.split('-');
  if (birth.year != int.parse(parts[0]) ||
      birth.month != int.parse(parts[1]) ||
      birth.day != int.parse(parts[2])) {
    return null;
  }
  if (birth.year < 1900 || birth.year > 2035) return null;

  int? hour;
  final hourText = q['hour'];
  if (hourText != null) {
    hour = int.tryParse(hourText);
    if (hour == null || hour < 0 || hour > 23) return null;
  }

  final genderText = q['gender'];
  final Gender? gender = switch (genderText) {
    'boy' => Gender.boy,
    'girl' => Gender.girl,
    _ => null,
  };
  if (gender == null) return null;

  // 한자 선택: 틀린 값이면 그 파라미터만 버리고 기본값으로 떨어뜨린다.
  final surnameHanjaText = q['surname_hanja'];
  final String? surnameHanja =
      surnameHanjaText != null && _isHanja(surnameHanjaText, 1)
          ? surnameHanjaText
          : null;
  final hanjaText = q['hanja'];
  final String? hanja =
      hanjaText != null && _isHanja(hanjaText, 2) ? hanjaText : null;

  return SharedNameParams(
    name: name,
    birth: DateTime(birth.year, birth.month, birth.day),
    hour: hour,
    gender: gender,
    surnameHanja: surnameHanja,
    hanja: hanja,
  );
}

/// 공유 링크의 조건으로 분석을 다시 계산한다.
/// - 성씨는 공유된 한자와 일치하는 항목을 쓰고, 없으면 첫 번째 한자(기본값).
/// - 이름 2자는 공유된 한자가 후보 목록에 있으면 그걸 쓰고, 없으면
///   첫 번째 후보(기본값). 호환 한자 등 목록에 없는 한자도 기본값으로 떨어진다.
/// - 한자가 없는 음절이 있으면 순우리말 분석으로 바꾼다.
/// - 성씨가 DB에 없거나 이름 형태가 맞지 않으면 null (링크를 무시한다).
({BabyInfo baby, NameAnalysis analysis})? resolveSharedAnalysis(
    SharedNameParams params) {
  final name = params.name;
  String? surname;
  String? given;
  if (name.length == 4 && surnamesByName.containsKey(name.substring(0, 2))) {
    surname = name.substring(0, 2);
    given = name.substring(2);
  } else if (name.length == 3) {
    surname = name.substring(0, 1);
    given = name.substring(1);
  } else {
    return null;
  }

  final entries = surnamesByName[surname];
  if (entries == null || entries.isEmpty) return null;
  final entry = params.surnameHanja == null
      ? entries.first
      : entries.firstWhere(
          (e) => e.hanja == params.surnameHanja,
          orElse: () => entries.first,
        );

  final baby = BabyInfo(
    surname: surname,
    surnameHanja: entry.hanja,
    surnameStrokes: entry.strokes,
    gender: params.gender,
    birth: DateTime(params.birth.year, params.birth.month, params.birth.day),
    birthHour: params.hour,
  );
  final saju = computeSaju(baby);

  final opts0 = orderedHanja(given[0]);
  final opts1 = orderedHanja(given[1]);
  if (opts0.isNotEmpty && opts1.isNotEmpty) {
    HanjaPick pickFor(int index, List<HanjaPick> opts) {
      final shared = params.hanja?[index];
      if (shared == null) return opts.first;
      return opts.firstWhere(
        (o) => o.char == shared,
        orElse: () => opts.first,
      );
    }

    final analysis = analyzeName(
      surname: surname,
      surnameStrokes: entry.strokes,
      picks: [pickFor(0, opts0), pickFor(1, opts1)],
      saju: saju,
      gender: params.gender,
    );
    return (baby: baby, analysis: analysis);
  }
  if (RegExp(r'^[가-힣]{2}$').hasMatch(given)) {
    final analysis = analyzePureKoreanName(
      surname: surname,
      surnameStrokes: entry.strokes,
      givenName: given,
      saju: saju,
      gender: params.gender,
    );
    return (baby: baby, analysis: analysis);
  }
  return null;
}
