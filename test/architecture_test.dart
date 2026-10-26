import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/data/hanja.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';

void main() {
  test('orderedHanja: curated 한자가 curated 순서대로 앞에 온다', () {
    final list = orderedHanja('준');
    final curatedOrder =
        hanjaBySyllable['준']!.map((e) => e.char).toList();
    final head = list.take(curatedOrder.length).map((e) => e.char).toList();
    expect(head, curatedOrder);
  });

  test('orderedHanja: curated 뒤 나머지는 획수 오름차순이다', () {
    final list = orderedHanja('준');
    final curatedOrder =
        hanjaBySyllable['준']!.map((e) => e.char).toSet();
    final rest = list.where((e) => !curatedOrder.contains(e.char)).toList();
    for (var i = 0; i + 1 < rest.length; i++) {
      expect(rest[i].strokes <= rest[i + 1].strokes, true);
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
    // detail_screen은 analyze_screen이 아니라 engine에서 orderedHanja를 가져와야 한다
    final detail = File('lib/screens/detail_screen.dart').readAsStringSync();
    expect(detail.contains("import 'analyze_screen.dart'"), false);
  });
}
