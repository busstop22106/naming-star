import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// 역할별 기본 출생 연도 — 구성원을 추가할 때의 시작값.
/// (다이얼로그 안에서 역할을 바꾸면, 아직 기본값 그대로인 경우에만 새 역할의
/// 기본 연도로 따라간다. 사용자가 직접 고른 연도는 건드리지 않는다.)
int memberDefaultYear(String role) {
  if (role == '할아버지' || role == '할머니') return 1955;
  if (role == '아빠' || role == '엄마') return 1990;
  return 2021;
}

bool _isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

/// 가족 구성원 역할 선택지
const memberRoleOptions = [
  '아빠', '엄마', '형', '오빠', '누나', '언니', '동생', '할아버지', '할머니'
];

/// 구성원 다이얼로그 결과 (저장 또는 삭제)
class MemberEditResult {
  final String? role;
  final DateTime? birth;
  final TimeOfDay? time;
  final bool timeUnknown;
  final bool deleted;
  const MemberEditResult({
    required this.role,
    required this.birth,
    required this.time,
    required this.timeUnknown,
  }) : deleted = false;
  const MemberEditResult.deleted()
      : role = null,
        birth = null,
        time = null,
        timeUnknown = true,
        deleted = true;
}

/// 구성원 추가/편집 다이얼로그
class MemberDialog extends StatefulWidget {
  final bool isEdit;
  final bool canDelete;
  final String initialRole;
  final DateTime initialBirth;
  final TimeOfDay? initialTime;
  final bool initialTimeUnknown;
  const MemberDialog({
    super.key,
    required this.isEdit,
    required this.canDelete,
    required this.initialRole,
    required this.initialBirth,
    required this.initialTime,
    required this.initialTimeUnknown,
  });
  @override
  State<MemberDialog> createState() => MemberDialogState();
}

class MemberDialogState extends State<MemberDialog> {
  late String baseRole = widget.initialRole;
  late DateTime birth = widget.initialBirth;
  late TimeOfDay? time = widget.initialTime;
  late bool timeUnknown = widget.initialTimeUnknown;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: birth,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(2035),
      locale: const Locale('ko'),
    );
    if (d != null) setState(() => birth = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: time ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (t != null) {
      setState(() {
        time = t;
        timeUnknown = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.isEdit ? '구성원 편집' : '구성원 추가',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('역할',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in memberRoleOptions)
                    ChoiceChip(
                      label: Text(r,
                          style: TextStyle(
                              fontSize: 13,
                              color: baseRole == r
                                  ? AppTheme.primaryDark
                                  : AppTheme.ink,
                              fontWeight: FontWeight.w700)),
                      selected: baseRole == r,
                      onSelected: (_) => setState(() {
                        // 아직 이전 역할의 기본 연도 그대로면 새 역할의
                        // 기본 연도로 따라간다 (예: 형 2021 → 할아버지 1955).
                        // 사용자가 연도를 직접 바꾼 뒤에는 따라가지 않는다.
                        if (birth.year ==
                            memberDefaultYear(baseRole)) {
                          var day = birth.day;
                          if (birth.month == 2 &&
                              day == 29 &&
                              !_isLeapYear(memberDefaultYear(r))) {
                            day = 28;
                          }
                          birth = DateTime(memberDefaultYear(r),
                              birth.month, day);
                        }
                        baseRole = r;
                      }),
                      selectedColor: AppTheme.primarySoft,
                      // 체크 표시를 끄면 라벨이 늘어나 정렬이 바뀌는 현상이 사라진다.
                      showCheckmark: false,
                      side: BorderSide(
                        color: baseRole == r
                            ? AppTheme.primary
                            : AppTheme.chipBorder,
                        width: baseRole == r ? 1.5 : 1,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_outlined,
                    color: AppTheme.primary),
                title: Text(
                    '${birth.year}년 ${birth.month}월 ${birth.day}일',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.schedule, color: AppTheme.primary),
                title: Text(
                    '태어난 시간 · ${timeUnknown ? '모름' : (time == null ? '선택 안 함' : formatTimeOfDay(time!))}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickTime,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('태어난 시간을 몰라요',
                    style: TextStyle(fontSize: 13)),
                value: timeUnknown,
                onChanged: (v) =>
                    setState(() => timeUnknown = v ?? false),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.canDelete)
                    TextButton.icon(
                      onPressed: () => Navigator.pop(
                          context, const MemberEditResult.deleted()),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('삭제'),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red),
                    ),
                  if (widget.canDelete) const Spacer(),
                  // 작은 화면 + 큰 글자에서도 버튼이 줄바꿈되게 Wrap 사용
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48)),
                          onPressed: () => Navigator.pop(
                            context,
                            MemberEditResult(
                              role: baseRole,
                              birth: birth,
                              time: time,
                              timeUnknown: timeUnknown,
                            ),
                          ),
                          child: Text(widget.isEdit ? '저장' : '추가'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
