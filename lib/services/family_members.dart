import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 가족 궁합 구성원 입력 상태.
/// 이름 분석 탭의 가족 궁합 모드에서 쓰는 값으로, 앱을 껐다 켜도
/// 다시 입력하지 않도록 SharedPreferences에 JSON으로 저장한다.
/// (favorites.dart의 보관함 저장과 같은 패턴.)
class FamilyMemberInput {
  String role;
  DateTime birth;
  TimeOfDay? time;
  bool timeUnknown;

  FamilyMemberInput(
    this.role,
    this.birth, {
    this.time,
    this.timeUnknown = true,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'birth': birth.toIso8601String(),
        'hour': time?.hour,
        'minute': time?.minute,
        'timeUnknown': timeUnknown,
      };

  /// 파싱에 실패한 항목은 null을 돌려준다 — 불러올 때 그 항목만 건너뛴다.
  static FamilyMemberInput? tryFromJson(Map<String, dynamic> j) {
    try {
      final role = j['role'];
      final birthRaw = j['birth'];
      if (role is! String || role.isEmpty || birthRaw is! String) {
        return null;
      }
      final birth = DateTime.parse(birthRaw);
      final hour = j['hour'];
      final minute = j['minute'];
      TimeOfDay? time;
      if (hour is int && minute is int) {
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
          return null;
        }
        time = TimeOfDay(hour: hour, minute: minute);
      }
      return FamilyMemberInput(
        role,
        birth,
        time: time,
        timeUnknown: j['timeUnknown'] is bool ? j['timeUnknown'] as bool : true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// 처음 실행할 때의 기본 구성원 (기존 화면 초기값과 동일).
List<FamilyMemberInput> defaultFamilyMembers() => [
      FamilyMemberInput('아빠', DateTime(1987, 5, 5)),
      FamilyMemberInput('엄마', DateTime(1990, 7, 7)),
    ];

const _key = 'jakmyeongbyeol_family_members';
const _maxMembers = 6;

/// 저장된 구성원을 불러온다. 저장된 게 없거나 전부 깨졌으면 빈 리스트를
/// 돌려준다 — 호출하는 쪽에서 기본값을 쓰면 된다.
Future<List<FamilyMemberInput>> loadFamilyMembers() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_key);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List;
    final members = <FamilyMemberInput>[];
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      final m = FamilyMemberInput.tryFromJson(e);
      if (m != null) members.add(m);
      if (members.length >= _maxMembers) break;
    }
    return members;
  } catch (_) {
    return [];
  }
}

/// 구성원 목록을 통째로 저장한다. 빈 리스트를 저장하면 다음 실행 때
/// 기본값으로 돌아간다.
Future<void> saveFamilyMembers(List<FamilyMemberInput> members) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      _key, jsonEncode(members.map((m) => m.toJson()).toList()));
}
