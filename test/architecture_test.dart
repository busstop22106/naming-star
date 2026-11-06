import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/data/hanja.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';

/// 소스에서 marker로 시작하는 호출 전체를 괄호 균형으로 잘라낸다.
/// (문자열·라인 주석 안의 괄호는 세지 않는다.)
List<String> _extractCalls(String src, String marker) {
  final calls = <String>[];
  var from = 0;
  while (true) {
    final start = src.indexOf(marker, from);
    if (start < 0) break;
    var depth = 0;
    var inSingle = false;
    var inDouble = false;
    var escaped = false;
    var j = start + marker.length - 1; // marker 끝의 '('
    for (; j < src.length; j++) {
      final c = src[j];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (c == '\\' && (inSingle || inDouble)) {
        escaped = true;
        continue;
      }
      if (inSingle) {
        if (c == "'") inSingle = false;
        continue;
      }
      if (inDouble) {
        if (c == '"') inDouble = false;
        continue;
      }
      if (c == "'") {
        inSingle = true;
        continue;
      }
      if (c == '"') {
        inDouble = true;
        continue;
      }
      if (c == '/' && j + 1 < src.length && src[j + 1] == '/') {
        final nl = src.indexOf('\n', j);
        j = nl < 0 ? src.length - 1 : nl;
        continue;
      }
      if (c == '(') depth++;
      if (c == ')') {
        depth--;
        if (depth == 0) break;
      }
    }
    calls.add(src.substring(start, j + 1));
    from = j + 1;
  }
  return calls;
}

/// 화면 파일의 공개 최상위 선언 중, 다른 화면이 가져오면 안 되는
/// 로직 심볼(위젯 클래스가 아닌 것)을 모은다.
/// 화면 이동용 위젯 클래스(StatelessWidget/StatefulWidget)는 제외한다.
Set<String> _publicLogicNames(String src) {
  final names = <String>{};
  for (final m in RegExp(r'^class\s+(\w+)(?:\s+extends\s+([\w<>]+))?',
          multiLine: true)
      .allMatches(src)) {
    final name = m.group(1)!;
    if (name.startsWith('_')) continue;
    if ((m.group(2) ?? '').contains('Widget')) continue;
    names.add(name);
  }
  for (final m in RegExp(r'^(?:enum|mixin|typedef|extension)\s+(\w+)',
          multiLine: true)
      .allMatches(src)) {
    final name = m.group(1)!;
    if (!name.startsWith('_')) names.add(name);
  }
  // 최상위 함수 (컬럼 0에서 시작 — 들여쓰인 메소드는 제외)
  for (final m in RegExp(r'^([A-Za-z_]\w*)\s+(\w+)\s*\([^;]*\)\s*\{',
          multiLine: true)
      .allMatches(src)) {
    final name = m.group(2)!;
    if (!name.startsWith('_')) names.add(name);
  }
  // 최상위 변수
  for (final m in RegExp(
          r'^(?:final|const|var|late final|late var)\s+(?:[\w<>,\s\?]+?\s+)?(\w+)\s*=',
          multiLine: true)
      .allMatches(src)) {
    final name = m.group(1)!;
    if (!name.startsWith('_')) names.add(name);
  }
  return names;
}

/// 주석과 import 문을 지운다 (심볼 참조 검사에서 오탐을 줄이기 위해).
String _stripCommentsAndImports(String src) {
  final noBlock = src.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ');
  return noBlock
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('import '))
      .map((l) {
        final idx = l.indexOf('//');
        return idx < 0 ? l : l.substring(0, idx);
      })
      .join('\n');
}

List<File> _screenFiles() => Directory('lib/screens')
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

List<File> _libDartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

void main() {
  test('orderedHanja: curated 한자가 curated 순서대로 앞에 온다', () {
    final list = orderedHanja('준');
    final curatedOrder =
        hanjaBySyllable['준']!.map((e) => e.char).toList();
    final head = list.take(curatedOrder.length).map((e) => e.char).toList();
    expect(head, curatedOrder);
  });

  test('orderedHanja: curated 뒤 나머지는 뜻 있는 것 먼저, 각 그룹 안은 획수 오름차순이다', () {
    final list = orderedHanja('준');
    final curatedOrder =
        hanjaBySyllable['준']!.map((e) => e.char).toSet();
    final rest = list.where((e) => !curatedOrder.contains(e.char)).toList();
    // 뜻 있는 한자가 먼저, 뜻 없는 한자는 뒤에 — 각 그룹 안은 획수 오름차순.
    final firstNoMeaning = rest.indexWhere((e) => e.meaning.isEmpty);
    expect(firstNoMeaning, greaterThan(0));
    for (final group in [
      rest.sublist(0, firstNoMeaning),
      rest.sublist(firstNoMeaning),
    ]) {
      for (var i = 0; i + 1 < group.length; i++) {
        expect(group[i].strokes <= group[i + 1].strokes, true);
      }
    }
  });

  test('아키텍처: engine은 Flutter에 의존하지 않는다 (순수 Dart 유지)', () {
    final dir = Directory('lib/engine');
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      expect(src.contains('package:flutter'), false,
          reason: '${f.path}가 Flutter를 import하면 UI와 로직 분리가 깨집니다');
    }
  });

  test('아키텍처: 화면끼리 로직을 import하지 않는다', () {
    // 화면 간 이동(Navigator.push)은 상대 화면의 위젯 클래스를 import해야
    // 하므로 위젯 클래스 참조는 허용한다. 금지되는 것은 한 화면의
    // 함수·상수·모델 같은 로직 심볼을 다른 화면이 가져오는 것이다.
    // (전례: orderedHanja를 analyze_screen → engine/hanja_order.dart로 이동)
    final importRe = RegExp(r"""^import\s+'([^']+)'""", multiLine: true);
    for (final file in _screenFiles()) {
      final src = file.readAsStringSync();
      final body = _stripCommentsAndImports(src);
      for (final m in importRe.allMatches(src)) {
        final target = m.group(1)!;
        if (!target.endsWith('_screen.dart')) continue;
        final targetFile =
            File('lib/screens/${target.split('/').last}');
        if (!targetFile.existsSync()) continue;
        for (final name in _publicLogicNames(targetFile.readAsStringSync())) {
          expect(RegExp('\\b$name\\b').hasMatch(body), isFalse,
              reason:
                  '${file.path}가 ${targetFile.path}의 로직 심볼 $name을 쓴다. '
                  'engine으로 옮길 것 (AGENTS.md: 화면끼리 로직 import 금지)');
        }
      }
    }
    // 전례 회귀 방지: detail_screen은 analyze_screen이 아니라
    // engine에서 orderedHanja를 가져와야 한다.
    final detail = File('lib/screens/detail_screen.dart').readAsStringSync();
    expect(detail.contains("import 'analyze_screen.dart'"), false);
  });

  test('아키텍처: 화면 파일 안의 다이얼로그는 150줄을 넘기면 widgets/로 분리한다',
      () {
    // AGENTS.md: 화면 파일 안에만 쓰이는 다이얼로그라도 150줄을 넘기면 분리한다.
    // (전례: _MemberDialog → widgets/member_dialog.dart)
    // 다이얼로그가 아닌 화면 위젯(_FamilyMapCardState 등)은 이 규칙의
    // 대상이 아니므로 검사하지 않는다. 인라인 showDialog 빌더(몇 줄짜리
    // AlertDialog)도 다이얼로그 위젯 클래스가 아니라 대상이 아니다.
    final classRe = RegExp(r'^class\s+(\w+)\s+extends\s+([\w<>]+)',
        multiLine: true);
    for (final file in _screenFiles()) {
      final lines = file.readAsLinesSync();
      final starts = <int>[];
      final decls = <String>[];
      for (var i = 0; i < lines.length; i++) {
        final m = classRe.firstMatch(lines[i]);
        if (m != null) {
          starts.add(i);
          decls.add(lines[i]);
        }
      }
      for (var k = 0; k < starts.length; k++) {
        final end =
            k + 1 < starts.length ? starts[k + 1] : lines.length;
        final name = classRe.firstMatch(decls[k])!.group(1)!;
        final superName = classRe.firstMatch(decls[k])!.group(2)!;
        final isWidgetClass = superName.contains('Widget') ||
            superName == 'State';
        if (!isWidgetClass && !name.contains('Dialog')) continue;
        final body = lines.sublist(starts[k], end).join('\n');
        final isDialog = name.contains('Dialog') ||
            body.contains('AlertDialog(') ||
            body.contains('SimpleDialog(') ||
            RegExp(r'\bDialog\(').hasMatch(body);
        if (!isDialog) continue;
        expect(end - starts[k], lessThanOrEqualTo(150),
            reason:
                '${file.path}의 $name가 ${end - starts[k]}줄이다. 150줄을 넘긴 '
                '다이얼로그는 lib/widgets/로 분리할 것 (AGENTS.md)');
      }
    }
  });

  test('아키텍처: 모든 ChoiceChip은 라벨 색상을 명시한다', () {
    // AGENTS.md: ChoiceChip 라벨 색상은 테마 기본값에 의존하지 말고 명시한다
    // (선택: primaryDark, 미선택: ink, 체크: primaryDark).
    // 테마 기본값에만 의존했더니 실기기에서 글자가 배경에 묻히는 버그가 났다.
    var found = 0;
    for (final file in _libDartFiles()) {
      final src = file.readAsStringSync();
      for (final call in _extractCalls(src, 'ChoiceChip(')) {
        found++;
        expect(call.contains('AppTheme.primaryDark'), isTrue,
            reason: '${file.path}의 ChoiceChip에 선택 상태 라벨 색상'
                '(primaryDark) 명시가 없다');
        expect(call.contains('AppTheme.ink'), isTrue,
            reason: '${file.path}의 ChoiceChip에 미선택 상태 라벨 색상'
                '(ink) 명시가 없다');
        // 체크 표시가 있으면 체크 색상도 명시해야 한다.
        // 체크를 끈 칩(showCheckmark: false)은 해당 없음.
        if (!call.contains('showCheckmark: false')) {
          expect(call.contains('checkColor: AppTheme.primaryDark'),
              isTrue,
              reason: '${file.path}의 ChoiceChip에 체크 색상'
                  '(primaryDark) 명시가 없다');
        }
      }
    }
    // 검사 대상이 하나도 없으면 테스트가 공회전하므로 실패시킨다.
    expect(found, greaterThan(0));
  });

  test('아키텍처: 액션이 있는 SnackBar는 persist: false를 명시한다', () {
    // 액션이 있으면 SnackBar의 persist 기본값이 true라 duration을 줘도
    // 자동으로 안 사라진다. (전례: 보관함 삭제 토스트 3초 + persist: false)
    var foundAction = false;
    for (final file in _libDartFiles()) {
      final src = file.readAsStringSync();
      if (file.path.endsWith('lib/widgets/common.dart')) {
        // 헬퍼 정의: persist 파라미터를 받아 SnackBar에 그대로 전달해야 한다.
        expect(src.contains('bool? persist'), isTrue,
            reason: 'showSingleSnackBar에 persist 파라미터가 없다');
        expect(src.contains('persist: persist'), isTrue,
            reason: 'showSingleSnackBar가 persist를 SnackBar에 전달하지 않는다');
        continue;
      }
      for (final call in _extractCalls(src, 'SnackBar(')) {
        if (call.contains('action:')) {
          foundAction = true;
          expect(call.contains('persist: false'), isTrue,
              reason: '${file.path}의 SnackBar에 action이 있는데 '
                  'persist: false가 없다');
        }
      }
      for (final call in _extractCalls(src, 'showSingleSnackBar(')) {
        if (call.contains('action:')) {
          foundAction = true;
          expect(call.contains('persist: false'), isTrue,
              reason: '${file.path}의 showSingleSnackBar 호출에 action이 있는데 '
                  'persist: false가 없다');
        }
      }
    }
    expect(foundAction, isTrue,
        reason: '액션 있는 SnackBar 검사 대상이 없다 — 전례가 사라진 것인지 확인할 것');
  });
}
