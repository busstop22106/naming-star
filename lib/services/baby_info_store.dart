import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// 탭 간 공유하는 아기 기본 정보(성씨·성별·생년월일시) 저장/복원.
/// 앱 재시작 뒤에도 마지막에 입력한 값이 유지된다.
/// 파싱에 실패하면 null을 돌려주고, 호출하는 쪽은 기본값을 쓴다.
class BabyInfoStore {
  static const _key = 'jakmyeongbyeol_baby_info';
  static const _schemaVersion = 1;

  static Map<String, dynamic> _toJson(SharedBaby baby) => {
        'version': _schemaVersion,
        'surname': {
          'name': baby.surname.name,
          'hanja': baby.surname.hanja,
          'strokes': baby.surname.strokes,
          'manual': baby.surname.manual,
        },
        'gender': baby.gender.name,
        'birth': baby.birth.toIso8601String(),
        'birthHour': baby.birthHour,
        'birthMinute': baby.birthMinute,
        'timeUnknown': baby.timeUnknown,
      };

  static SharedBaby? _tryFromJson(Map<String, dynamic> j) {
    try {
      if (j['version'] != _schemaVersion) return null;
      final surnameRaw = j['surname'];
      final genderRaw = j['gender'];
      final birthRaw = j['birth'];
      if (surnameRaw is! Map<String, dynamic>) return null;
      final name = surnameRaw['name'];
      final hanja = surnameRaw['hanja'];
      final strokes = surnameRaw['strokes'];
      if (name is! String || name.isEmpty) return null;
      if (hanja is! String) return null;
      if (strokes is! num) return null;
      if (genderRaw is! String ||
          (genderRaw != 'boy' && genderRaw != 'girl')) {
        return null;
      }
      if (birthRaw is! String) return null;
      final birth = DateTime.parse(birthRaw);
      final hour = j['birthHour'];
      final minute = j['birthMinute'];
      if (hour is num && (hour < 0 || hour > 23)) return null;
      if (minute is num && (minute < 0 || minute > 59)) return null;
      return SharedBaby(
        surname: SurnamePick(
          name: name,
          hanja: hanja,
          strokes: strokes.toInt(),
          manual:
              surnameRaw['manual'] is bool ? surnameRaw['manual'] as bool : false,
        ),
        gender: genderRaw == 'boy' ? Gender.boy : Gender.girl,
        birth: birth,
        birthHour: hour is num ? hour.toInt() : null,
        birthMinute: minute is num ? minute.toInt() : null,
        timeUnknown:
            j['timeUnknown'] is bool ? j['timeUnknown'] as bool : false,
      );
    } catch (_) {
      return null;
    }
  }

  /// 저장된 아기 정보가 없거나 깨졌으면 null.
  static Future<SharedBaby?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _tryFromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(SharedBaby baby) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_toJson(baby)));
  }
}
