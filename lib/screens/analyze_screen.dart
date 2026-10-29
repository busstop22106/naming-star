import 'package:flutter/material.dart';
import '../engine/compat.dart';
import '../engine/hanja_order.dart';
import '../engine/pure_korean.dart';
import '../engine/saju.dart';
import '../engine/scoring.dart';
import '../favorites.dart';
import '../models.dart';
import '../services/ad_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/member_dialog.dart';
import '../widgets/surname_picker.dart';
import 'compat_screen.dart';
import 'detail_screen.dart';

/// 직접 이름 분석 — 이미 정한 이름을 입력해 평가
class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _givenCtrl = TextEditingController();
  SurnamePick _surnamePick =
      const SurnamePick(name: '김', hanja: '金', strokes: 8);
  Gender _gender = Gender.boy;
  DateTime _birth = DateTime(2026, 10, 19);
  TimeOfDay? _birthTime;
  bool _timeUnknown = false;
  bool _isPureKorean = false;
  // 음절별 선택된 한자 인덱스
  final Map<int, int> _hanjaIdx = {};
  // 가족 궁합 모드
  bool _compatMode = false;
  final List<_MemberInput> _members = [
    _MemberInput('아빠', DateTime(1990, 5, 5)),
    _MemberInput('엄마', DateTime(1992, 7, 7)),
  ];

  @override
  void dispose() {
    _givenCtrl.dispose();
    super.dispose();
  }

  Future<void> _chooseSurname() async {
    final pick = await showSurnamePicker(context, _surnamePick);
    if (pick != null) {
      setState(() => _surnamePick = pick);
    }
  }

  /// 보관함에서 이름을 골라 입력 폼 전체를 채워요
  Future<void> _loadFromFavorites() async {
    final items = await loadFavorites();
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('보관함이 비어 있어요. 이름 짓기에서 마음에 드는 이름을 보관해보세요.')),
      );
      return;
    }
    final picked = await showModalBottomSheet<FavoriteItem>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Text('보관함에서 불러오기',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('고르면 성씨·한자·생년월일까지 그대로 채워져요.',
                    style: TextStyle(fontSize: 12, color: AppTheme.sub)),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 20, endIndent: 20),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final b = item.baby;
                    return ListTile(
                      title: Text(
                        item.hanjaName.isEmpty
                            ? item.fullName
                            : '${item.fullName} (${item.hanjaName})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                          '종합 ${item.total.toStringAsFixed(0)}점 · ${b.birth.year}년 ${b.birth.month}월 ${b.birth.day}일생'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(ctx, item),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    _applyFavorite(picked);
  }

  void _applyFavorite(FavoriteItem item) {
    final baby = item.baby;
    setState(() {
      _surnamePick = SurnamePick(
        name: baby.surname,
        hanja: baby.surnameHanja,
        strokes: baby.surnameStrokes,
      );
      _givenCtrl.text = item.picks.map((p) => p.syllable).join();
      _isPureKorean = item.picks.every((p) => p.char.isEmpty);
      _hanjaIdx.clear();
      if (!_isPureKorean) {
        for (var i = 0; i < item.picks.length && i < 2; i++) {
          final opts = orderedHanja(item.picks[i].syllable);
          final idx = opts.indexWhere((o) => o.char == item.picks[i].char);
          if (idx >= 0) _hanjaIdx[i] = idx;
        }
      }
      _gender = baby.gender;
      _birth = baby.birth;
      _timeUnknown = baby.birthHour == null;
      _birthTime = baby.birthHour == null
          ? null
          : TimeOfDay(
              hour: baby.birthHour!, minute: baby.birthMinute ?? 0);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('보관함에서 ${item.fullName}을(를) 불러왔어요.')),
    );
  }

  List<String> get _syllables =>
      _givenCtrl.text.trim().split('').where((c) => c.trim().isNotEmpty).toList();

  void _analyze() {
    final syls = _syllables;
    if (syls.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isPureKorean
                ? '순우리말 이름 2자를 입력해주세요. (예: 하늘)'
                : '이름 2자를 입력해주세요. (예: 도윤)')),
      );
      return;
    }
    // 한글 음절 확인 (순우리말 모드)
    if (_isPureKorean) {
      final hangul = RegExp(r'^[가-힣]{2}$');
      if (!hangul.hasMatch(syls.join())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('한글 2자로 입력해주세요.')),
        );
        return;
      }
    }
    final baby = BabyInfo(
      surname: _surnamePick.name,
      surnameHanja: _surnamePick.hanja,
      surnameStrokes: _surnamePick.strokes,
      gender: _gender,
      birth: _birth,
      birthHour: _timeUnknown ? null : _birthTime?.hour,
      birthMinute: _timeUnknown ? null : _birthTime?.minute,
    );
    final saju = computeSaju(baby);
    final NameAnalysis analysis;
    if (_isPureKorean) {
      analysis = analyzePureKoreanName(
        surname: _surnamePick.name,
        surnameStrokes: _surnamePick.strokes,
        givenName: syls.join(),
        saju: saju,
        gender: _gender,
      );
    } else {
      final picks = <HanjaPick>[];
      for (var i = 0; i < 2; i++) {
        final opts = orderedHanja(syls[i]);
        if (opts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('\'${syls[i]}\' 음절의 한자 데이터가 없어요.')),
          );
          return;
        }
        final idx = (_hanjaIdx[i] ?? 0).clamp(0, opts.length - 1);
        picks.add(opts[idx]);
      }
      analysis = analyzeName(
        surname: _surnamePick.name,
        surnameStrokes: _surnamePick.strokes,
        picks: picks,
        saju: saju,
        gender: _gender,
      );
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(baby: baby, analysis: analysis),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _birth,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(2035),
      locale: const Locale('ko'),
    );
    if (d != null) setState(() => _birth = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (t != null) {
      setState(() {
        _birthTime = t;
        _timeUnknown = false;
      });
    }
  }

  // ── 가족 궁합 ──

  /// 이름 2자 + 한자 선택을 검증하고 picks를 만들어요. 실패하면 null.
  List<HanjaPick>? _buildPicks() {
    final syls = _syllables;
    if (syls.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isPureKorean
                ? '순우리말 이름 2자를 입력해주세요. (예: 하늘)'
                : '이름 2자를 입력해주세요. (예: 도윤)')),
      );
      return null;
    }
    if (_isPureKorean) {
      if (!RegExp(r'^[가-힣]{2}$').hasMatch(syls.join())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('한글 2자로 입력해주세요.')),
        );
        return null;
      }
      return pureKoreanPicks(syls.join());
    }
    final picks = <HanjaPick>[];
    for (var i = 0; i < 2; i++) {
      final opts = orderedHanja(syls[i]);
      if (opts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\'${syls[i]}\' 음절의 한자 데이터가 없어요.')),
        );
        return null;
      }
      picks.add(opts[(_hanjaIdx[i] ?? 0).clamp(0, opts.length - 1)]);
    }
    return picks;
  }

  void _analyzeCompat() {
    final picks = _buildPicks();
    if (picks == null) return;
    final baby = BabyInfo(
      surname: _surnamePick.name,
      surnameHanja: _surnamePick.hanja,
      surnameStrokes: _surnamePick.strokes,
      gender: _gender,
      birth: _birth,
      birthHour: _timeUnknown ? null : _birthTime?.hour,
      birthMinute: _timeUnknown ? null : _birthTime?.minute,
    );
    final result = computeFamilyCompat(
      members: [
        for (final m in _members)
          (
            label: m.role,
            saju: sajuOfBirth(
                m.birth, m.timeUnknown ? null : m.time?.hour),
          ),
      ],
      babySaju: computeSaju(baby),
      picks: picks,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompatScreen(
          babyFullName: '${_surnamePick.name}${picks.map((p) => p.syllable).join()}',
          babyHanjaName:
              _isPureKorean ? '' : picks.map((p) => p.char).join(),
          isPureKorean: _isPureKorean,
          result: result,
        ),
      ),
    );
  }

  /// 같은 역할이 겹치면 '형 2'처럼 번호를 붙여 구분해요
  String _uniqueLabel(String base, int selfIndex) {
    var n = 0;
    for (var i = 0; i < _members.length; i++) {
      if (i == selfIndex) continue;
      final r = _members[i].role;
      if (r == base || r.startsWith('$base ')) n++;
    }
    return n == 0 ? base : '$base ${n + 1}';
  }

  /// 구성원 추가/편집 다이얼로그 팝업. index가 null이면 신규 추가.
  /// (바텀시트 방식은 일부 기기에서 내용이 안 보이는 문제가 있어
  /// 화면 중앙에 뜨는 다이얼로그로 바꿨어요.)
  Future<void> _showMemberSheet({int? index}) async {
    final editIndex = index;
    String baseRole;
    DateTime birth;
    TimeOfDay? time;
    bool timeUnknown;
    if (editIndex != null) {
      final orig = _members[editIndex];
      baseRole = orig.role.split(' ').first;
      birth = orig.birth;
      time = orig.time;
      timeUnknown = orig.timeUnknown;
    } else {
      final used = _members.map((m) => m.role.split(' ').first).toSet();
      baseRole = memberRoleOptions.firstWhere((r) => !used.contains(r),
          orElse: () => '동생');
      final isElder = ['아빠', '엄마', '할아버지', '할머니'].contains(baseRole);
      final isGrand = ['할아버지', '할머니'].contains(baseRole);
      birth = isGrand
          ? DateTime(1955, 1, 1)
          : isElder
              ? DateTime(1990, 5, 5)
              : DateTime(2021, 3, 5);
      time = null;
      timeUnknown = true;
    }
    final result = await showDialog<MemberEditResult>(
      context: context,
      builder: (_) => MemberDialog(
        isEdit: editIndex != null,
        canDelete: editIndex != null && _members.length > 1,
        initialRole: baseRole,
        initialBirth: birth,
        initialTime: time,
        initialTimeUnknown: timeUnknown,
      ),
    );
    if (result == null) return;
    setState(() {
      if (result.deleted) {
        if (editIndex != null) _members.removeAt(editIndex);
      } else {
        final label = _uniqueLabel(result.role!, editIndex ?? -1);
        if (editIndex != null) {
          final orig = _members[editIndex];
          orig.role = label;
          orig.birth = result.birth!;
          orig.time = result.time;
          orig.timeUnknown = result.timeUnknown;
        } else {
          _members.add(_MemberInput(label, result.birth!)
            ..time = result.time
            ..timeUnknown = result.timeUnknown);
        }
      }
    });
  }

  /// 섹션 헤더 (아기 정보 / 가족 구성 구분용)
  Widget _sectionHeader(IconData icon, String title, {String? badge}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(badge,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
            ),
          ],
        ],
      ),
    );
  }

  /// 가족 구성 요약 카드 — 행을 눌러 편집 시트로, ×로 삭제
  Widget _familyMembersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('행을 눌러 수정하고, ×를 눌러 삭제할 수 있어요.',
                style: TextStyle(fontSize: 11, color: AppTheme.sub)),
            const SizedBox(height: 8),
            for (var i = 0; i < _members.length; i++) ...[
              InkWell(
                onTap: () => _showMemberSheet(index: i),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppTheme.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          zodiacEmojis[sajuOfBirth(
                                      _members[i].birth, null)
                                  .year
                                  .branch] ??
                              '⭐',
                          style: const TextStyle(fontSize: 19),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_members[i].role,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text(
                              '${_members[i].birth.year}년 ${_members[i].birth.month}월 ${_members[i].birth.day}일 · ${_members[i].timeUnknown ? '시간 모름' : (_members[i].time == null ? '시간 미선택' : '${_members[i].time!.hour}시 ${_members[i].time!.minute}분')}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.sub),
                            ),
                          ],
                        ),
                      ),
                      if (_members.length > 1)
                        IconButton(
                          onPressed: () =>
                              setState(() => _members.removeAt(i)),
                          icon: const Icon(Icons.close,
                              size: 18, color: AppTheme.sub),
                          tooltip: '구성원 삭제',
                          visualDensity: VisualDensity.compact,
                        ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppTheme.sub),
                    ],
                  ),
                ),
              ),
              if (i < _members.length - 1) const Divider(height: 1),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _members.length >= _maxMembers
                    ? null
                    : () => _showMemberSheet(),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: Text(_members.length >= _maxMembers
                    ? '최대 6명까지 추가했어요'
                    : '구성원 추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syls = _syllables;

    return Scaffold(
      appBar: AppBar(title: const Text('이름 직접 분석하기')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          // 모드 전환: 이름 분석 / 가족 궁합
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: false,
                          label: Text('이름 분석'),
                          icon: Icon(Icons.analytics_outlined, size: 18)),
                      ButtonSegment(
                          value: true,
                          label: Text('가족 궁합'),
                          icon: Icon(Icons.family_restroom_outlined,
                              size: 18)),
                    ],
                    selected: {_compatMode},
                    onSelectionChanged: (s) =>
                        setState(() => _compatMode = s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _compatMode
                        ? '아빠·엄마의 사주와 아기 이름이 얼마나 잘 맞는지 봐요. 부모 정보는 한 번만 넣으면 이름만 바꿔 비교할 수 있어요.'
                        : '이미 정한 이름을 5개 차원으로 분석해요.',
                    style:
                        const TextStyle(fontSize: 11, color: AppTheme.sub),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (_compatMode)
            _sectionHeader(Icons.child_care_outlined, '아기 정보'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('분석할 이름',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        onPressed: _loadFromFavorites,
                        icon: const Icon(Icons.bookmark_outline, size: 16),
                        label: const Text('보관함에서 불러오기'),
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 성씨 선택기
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _chooseSurname,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _surnamePick.hanja.isEmpty
                                    ? _surnamePick.name
                                    : '${_surnamePick.name}(${_surnamePick.hanja})',
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_surnamePick.strokes}획',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.sub,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('성씨 변경',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600)),
                              Icon(Icons.chevron_right,
                                  size: 18,
                                  color: AppTheme.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _givenCtrl,
                    maxLength: 2,
                    decoration: InputDecoration(
                        hintText: _isPureKorean
                            ? '순우리말 이름 2자 (예: 하늘)'
                            : '이름 2자 (예: 도윤)',
                        counterText: ''),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                    onChanged: (_) =>
                        setState(() => _hanjaIdx.clear()),
                  ),
                  const SizedBox(height: 12),
                  // 이름 종류 선택
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: false,
                          label: Text('한자 이름'),
                          icon: Icon(Icons.text_fields, size: 18)),
                      ButtonSegment(
                          value: true,
                          label: Text('순우리말'),
                          icon: Icon(Icons.grass_outlined, size: 18)),
                    ],
                    selected: {_isPureKorean},
                    onSelectionChanged: (s) => setState(() {
                      _isPureKorean = s.first;
                      _hanjaIdx.clear();
                    }),
                  ),
                  if (_isPureKorean) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '순우리말 이름은 한자 획수 대신 한글 자모 획수로 수리를 계산하고, 초성의 발음오행으로 사주를 보완하는 간이 분석이에요.',
                      style:
                          TextStyle(fontSize: 11, color: AppTheme.sub),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 성별 (두 모드 공통 — 점수에는 쓰이지 않지만 폼 일관성을 위해 표시)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('성별',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GenderButton(
                          label: '남아',
                          icon: Icons.boy,
                          color: AppTheme.boy,
                          selected: _gender == Gender.boy,
                          onTap: () =>
                              setState(() => _gender = Gender.boy),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GenderButton(
                          label: '여아',
                          icon: Icons.girl,
                          color: AppTheme.girl,
                          selected: _gender == Gender.girl,
                          onTap: () =>
                              setState(() => _gender = Gender.girl),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 한자 선택 (순우리말 모드에서는 숨김)
          if (syls.length == 2 && !_isPureKorean)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('한자 선택',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('각 음절에 쓸 한자를 고르세요.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.sub)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < 2; i++) ...[
                      Text(
                          '${syls[i]} (${orderedHanja(syls[i]).length}개 한자)',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Container(
                        constraints:
                            const BoxConstraints(maxHeight: 168),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: orderedHanja(syls[i])
                                .asMap()
                                .entries
                                .map((e) {
                              final sel =
                                  (_hanjaIdx[i] ?? 0) == e.key;
                              final label = e.value.meaning
                                      .isNotEmpty
                                  ? '${e.value.char} ${e.value.meaning}'
                                  : '${e.value.char} ${e.value.strokes}획';
                              return ChoiceChip(
                                label: Text(label,
                                    style: TextStyle(
                                        color: sel
                                            ? AppTheme.primaryDark
                                            : AppTheme.ink,
                                        fontWeight: FontWeight.w700)),
                                selected: sel,
                                onSelected: (_) => setState(
                                    () => _hanjaIdx[i] = e.key),
                                selectedColor:
                                    AppTheme.primarySoft,
                                avatar: ElementChip(
                                    e.value.element),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (i == 0) const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          // 생년월일시
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_compatMode ? '아기 생년월일시' : '생년월일시',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cake_outlined,
                        color: AppTheme.primary),
                    title: Text(
                        '${_birth.year}년 ${_birth.month}월 ${_birth.day}일',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDate,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule,
                        color: AppTheme.primary),
                    title: Text(
                        '태어난 시간 · ${_timeUnknown
                            ? '모름'
                            : (_birthTime == null
                                ? '선택 안 함'
                                : '${_birthTime!.hour}시 ${_birthTime!.minute}분')}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickTime,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity:
                        ListTileControlAffinity.leading,
                    title: const Text(
                        '태어난 시간을 몰라요',
                        style: TextStyle(fontSize: 13)),
                    value: _timeUnknown,
                    onChanged: (v) =>
                        setState(() => _timeUnknown = v ?? false),
                  ),
                  const Text(
                      '사주 분석에 활용해요. 시간을 모르면 시주를 제외하고 분석합니다.',
                      style:
                          TextStyle(fontSize: 11, color: AppTheme.sub)),
                ],
              ),
            ),
          ),
          // 가족 구성 (궁합 모드) — 요약 카드 + 바텀시트 편집
          if (_compatMode) ...[
            _sectionHeader(Icons.family_restroom_outlined, '가족 구성',
                badge: '${_members.length}명'),
            _familyMembersCard(),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _compatMode ? _analyzeCompat : _analyze,
            child: Text(_compatMode ? '가족 궁합 보기' : '이 이름 분석하기'),
          ),
          const SizedBox(height: 12),
          Text(
            _compatMode
                ? '가족 구성원 사주의 오행 보완·용신 조화·띠 궁합으로 점수화해 드려요.'
                : '수리·음양·발음·사주 보완·사용성 5개 차원으로 점수화해 드려요.',
            style: const TextStyle(fontSize: 11, color: AppTheme.sub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // 하단 배너 광고 (AdService.bannerEnabled 플래그로 제어)
          if (AdService.bannerEnabledFor(AdPlacement.analyze))
            const Center(
                child: BannerAdWidget(placement: AdPlacement.analyze)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

const _maxMembers = 6;

/// 가족 궁합 구성원 입력 상태
class _MemberInput {
  String role;
  DateTime birth;
  TimeOfDay? time;
  bool timeUnknown = true;
  _MemberInput(this.role, this.birth);
}

