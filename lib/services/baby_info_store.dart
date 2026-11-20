import 'dart:convert';

import '../models.dart';
import 'safe_prefs.dart';

/// 탭 간 공유하는 아기 기본 정보(성씨·성별·생년월일시) 저장/복원.
/// 앱 재시작 뒤에도 마지막에 입력한 값이 유지된다.
/// 파싱에 실패하면 null을 돌려주고, 호출하는 쪽은 기본값을 쓴다.
/// 저장소 실패가 앱 시작·화면 전환을 깨뜨리지 않게 SafePrefs를 쓴다
/// (2026-11-20 저장소 전수 점검).
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
  /// 저장소를 못 읽어도 null을 돌려주고 던지지 않는다.
  static Future<SharedBaby?> load() async {
    final raw = await SafePrefs.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _tryFromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// 저장 성공 여부를 반환한다. 실패해도 던지지 않는다.
  static Future<bool> save(SharedBaby baby) async {
    return SafePrefs.setString(_key, jsonEncode(_toJson(baby)));
  }
}
