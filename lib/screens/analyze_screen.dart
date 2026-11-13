import 'dart:async';
import 'package:flutter/material.dart';
import '../engine/best_hanja.dart';
import '../engine/compat.dart';
import '../engine/hanja_order.dart';
import '../engine/pure_korean.dart';
import '../engine/saju.dart';
import '../engine/scoring.dart';
import '../favorites.dart';
import '../models.dart';
import '../services/ad_service.dart';
import '../services/interstitial_gate.dart';
import '../services/family_members.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/hanja_picker_sheet.dart';
import '../widgets/member_dialog.dart';
import '../widgets/surname_picker.dart';
import 'compat_screen.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';
import 'reveal_screen.dart';

/// 직접 이름 분석 — 이미 정한 이름을 입력해 평가
/// [baby]·[onBabyChanged]가 있으면 아기 기본 정보를 이름 짓기 탭과 공유한다.
/// [analyzeNameRequest]는 랭킹 탭에서 넘어온 이름(성별 포함)으로, 오면 입력 폼에 채운다.
class AnalyzeScreen extends StatefulWidget {
  final SharedBaby? baby;
  final ValueChanged<SharedBaby>? onBabyChanged;
  final String? analyzeNameRequest;
  final Gender? analyzeGenderRequest;
  final VoidCallback? onAnalyzeNameConsumed;
  const AnalyzeScreen({
    super.key,
    this.baby,
    this.onBabyChanged,
    this.analyzeNameRequest,
    this.analyzeGenderRequest,
    this.onAnalyzeNameConsumed,
  });

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _givenCtrl = TextEditingController();
  late SurnamePick _surnamePick;
  late Gender _gender;
  late DateTime _birth;
  TimeOfDay? _birthTime;
  late bool _timeUnknown;
  bool _isPureKorean = false;
  SharedBaby? _lastSynced;
  String? _appliedNameRequest;
  // 음절별 선택된 한자 인덱스
  final Map<int, int> _hanjaIdx = {};
  // 보관함에서 불러온 호환 한자 등 orderedHanja() 목록에 없는 저장값.
  // 음절별 임시 목록 끝에 덧붙여 저장된 이름 그대로 분석되게 한다.
  final Map<int, HanjaPick> _extraHanja = {};
  // 가족 궁합 모드
  bool _compatMode = false;
  // 이동 중 연타 가드 — 분석·궁합 화면으로 넘어가는 동안 버튼을 눌러도
  // 결과 화면이 2장 쌓이지 않게 한다.
  bool _navigating = false;
  // 저장된 구성원이 있으면 불러오고, 없으면 기본값(아빠·엄마)을 쓴다.
  final List<FamilyMemberInput> _members = defaultFamilyMembers();

  @override
  void initState() {
    super.initState();
    _applyShared(widget.baby ?? SharedBaby.initial());
    _loadMembers();
  }

  /// 저장된 가족 구성원을 불러와 화면에 반영한다.
  /// 저장된 게 없으면 기본값을 그대로 둔다.
  Future<void> _loadMembers() async {
    final saved = await loadFamilyMembers();
    if (!mounted || saved.isEmpty) return;
    setState(() {
      _members
        ..clear()
        ..addAll(saved);
    });
  }

  /// 구성원이 바뀔 때마다 저장한다 — 앱을 껐다 켜도, 탭을 오가도 유지된다.
  Future<void> _saveMembers() => saveFamilyMembers(_members);

  @override
  void didUpdateWidget(covariant AnalyzeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다른 탭에서 바꾼 아기 정보가 오면 로컬 상태에 반영한다.
    final shared = widget.baby;
    if (shared != null && shared != _lastSynced) {
      setState(() => _applyShared(shared));
    }
    // 랭킹에서 가져온 이름이 오면 입력 폼에 채우고 요청을 소비한다.
    final request = widget.analyzeNameRequest;
    if (request == null) _appliedNameRequest = null;
    if (request != null && request != _appliedNameRequest) {
      _appliedNameRequest = request;
      setState(() {
        _givenCtrl.text = request;
        if (widget.analyzeGenderRequest != null) {
          _gender = widget.analyzeGenderRequest!;
        }
        _hanjaIdx.clear();
        _extraHanja.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAnalyzeNameConsumed?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '랭킹에서 ‘$request’을(를) 가져왔어요. 한자를 골라 분석해보세요.')),
          );
        }
      });
    }
  }

  void _applyShared(SharedBaby shared) {
    _surnamePick = shared.surname;
    _gender = shared.gender;
    _birth = shared.birth;
    _birthTime = shared.timeUnknown || shared.birthHour == null
        ? null
        : TimeOfDay(
            hour: shared.birthHour!, minute: shared.birthMinute ?? 0);
    _timeUnknown = shared.timeUnknown;
    _lastSynced = shared;
  }

  /// 로컬에서 바뀐 공유 필드를 부모(MainNav)에 알린다.
  void _syncShared() {
    final shared = SharedBaby(
      surname: _surnamePick,
      gender: _gender,
      birth: _birth,
      birthHour: _timeUnknown ? null : _birthTime?.hour,
      birthMinute: _timeUnknown ? null : _birthTime?.minute,
      timeUnknown: _timeUnknown,
    );
    if (shared == _lastSynced) return;
    _lastSynced = shared;
    widget.onBabyChanged?.call(shared);
  }

  @override
  void dispose() {
    _givenCtrl.dispose();
    super.dispose();
  }

  Future<void> _chooseSurname() async {
    final pick = await showSurnamePicker(context, _surnamePick);
    if (pick != null) {
      setState(() => _surnamePick = pick);
      _syncShared();
    }
  }

  /// 보관함에서 이름을 골라 입력 폼 전체를 채워요
  /// 보관함 전면 화면(설정 > 보관함과 같은 화면)을 선택 모드로 연다.
  /// 예전에는 바텀시트 목록으로 보여줬는데, 전면 화면이 익숙하고
  /// 점수·삭제까지 같은 화면에서 되니 이쪽으로 바꿨다.
  /// 빈 보관함이면 전면 화면의 빈 상태가 안내한다.
  Future<void> _loadFromFavorites() async {
    final picked = await Navigator.of(context).push<FavoriteItem>(
      MaterialPageRoute(
        builder: (_) => const FavoritesScreen(selectMode: true),
      ),
    );
    if (picked == null || !mounted) return;
    _applyFavorite(picked);
  }

  /// 음절의 한자 선택 목록. 보관함에서 불러온 호환 한자는 orderedHanja()에
  /// 없어서, 저장된 이름 그대로 분석되도록 목록 끝에 임시로 덧붙인다.
  /// (목록 끝에 붙이면 기존 인덱스가 그대로 유지된다.)
  List<HanjaPick> _hanjaOptions(int index, String syllable) {
    final opts = orderedHanja(syllable);
    final extra = _extraHanja[index];
    if (extra == null || extra.syllable != syllable) return opts;
    if (opts.any((o) => o.char == extra.char)) return opts;
    return [...opts, extra];
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
      _extraHanja.clear();
      if (!_isPureKorean) {
        for (var i = 0; i < item.picks.length && i < 2; i++) {
          final saved = item.picks[i];
          var opts = orderedHanja(saved.syllable);
          var idx = opts.indexWhere((o) => o.char == saved.char);
          if (idx < 0) {
            // 호환 한자 등 목록에 없는 저장값: 목록 끝에 임시로 덧붙여
            // 저장된 이름 그대로 분석되게 한다. (안 붙이면 _analyze()가
            // 0번 한자로 조용히 바꿔 분석해 버린다.)
            _extraHanja[i] = saved;
            opts = _hanjaOptions(i, saved.syllable);
            idx = opts.length - 1;
          }
          _hanjaIdx[i] = idx;
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
    _syncShared();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('보관함에서 ${item.fullName}을(를) 불러왔어요.')),
    );
  }

  List<String> get _syllables =>
      _givenCtrl.text.trim().split('').where((c) => c.trim().isNotEmpty).toList();

  Future<void> _analyze() async {
    if (_navigating) return;
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
        final opts = _hanjaOptions(i, syls[i]);
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
    // 4번째 시도마다 전면 광고가 애니메이션 대신 뜨고,
    // 나머지 3번은 별 애니메이션을 보여준 뒤 상세 화면으로 넘어간다.
    setState(() => _navigating = true);
    await InterstitialGate.goToResult(
      context,
      resultBuilder: (_) => DetailScreen(baby: baby, analysis: analysis),
      revealBuilder: (_) => RevealScreen(
        message: '작명별이 이름을 분석하고 있어요',
        subMessage: '수리부터 사주까지 꼼꼼히 살펴보고 있어요.',
        nextBuilder: (_) =>
            DetailScreen(baby: baby, analysis: analysis),
      ),
    );
    if (mounted) setState(() => _navigating = false);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _birth,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(2035),
      locale: const Locale('ko'),
    );
    if (d != null) {
      setState(() => _birth = d);
      _syncShared();
    }
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
      _syncShared();
    }
  }

  /// 사주에 가장 잘 맞는 한자 조합을 자동으로 고른다.
  void _autoPickHanja() {
    final syls = _syllables;
    if (syls.length != 2) return;
    final baby = BabyInfo(
      surname: _surnamePick.name,
      surnameHanja: _surnamePick.hanja,
      surnameStrokes: _surnamePick.strokes,
      gender: _gender,
      birth: _birth,
      birthHour: _timeUnknown ? null : _birthTime?.hour,
      birthMinute: _timeUnknown ? null : _birthTime?.minute,
    );
    final best = bestHanjaCombo(
      surname: _surnamePick.name,
      surnameStrokes: _surnamePick.strokes,
      syllables: syls,
      saju: computeSaju(baby),
      gender: _gender,
    );
    if (best == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 음절로 고를 수 있는 한자가 없어요.')),
      );
      return;
    }
    setState(() {
      for (var i = 0; i < 2; i++) {
        final opts = _hanjaOptions(i, syls[i]);
        final idx = opts.indexWhere((o) => o.char == best.picks[i].char);
        if (idx >= 0) _hanjaIdx[i] = idx;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '사주에 가장 잘 맞는 한자로 골랐어요. (${best.picks.map((p) => p.char).join()} · 예상 ${best.total.toStringAsFixed(0)}점)')),
    );
  }

  // ── 한자 선택 (음절별 모달) ──
  //
  // 예전에는 음절마다 한자 목록을 인라인으로 길게 늘어놓고 각자 안쪽
  // 스크롤 영역(높이 168)을 줬는데, 그 영역이 화면 전체 스크롤을 가로채서
  // 사용자가 의도하지 않게 한자 목록만 스크롤하는 일이 잦았다.
  // 그래서 화면에는 선택된 한자 한 줄만 보여주고, 목록은 음절별 모달
  // 시트(HanjaPickerSheet)에서 고르게 바꿨다. 시트 안에서만 목록이
  // 스크롤되고, 화면 자체는 하나의 스크롤로 동작한다.

  /// 음절 하나의 선택된 한자 표시줄. 탭하면 모달 시트가 열린다.
  Widget _hanjaSelectRow(int index, String syllable) {
    final opts = _hanjaOptions(index, syllable);
    if (opts.isEmpty) {
      // 한자음이 아닌 음절(예: '늘')은 쓸 수 있는 한자가 없다.
      // 여기서 clamp(0, -1)가 되어 빌드 중 'Invalid argument(s): 0'
      // 빨간 화면이 뜨던 자리다. 행은 안내만 보여주고 탭되지 않는다.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.chipBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text('${index + 1}자',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.sub)),
            const SizedBox(width: 8),
            Text(syllable,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('쓸 수 있는 한자가 없어요',
                  style: TextStyle(fontSize: 13, color: AppTheme.sub)),
            ),
          ],
        ),
      );
    }
    final idx = (_hanjaIdx[index] ?? 0).clamp(0, opts.length - 1);
    final sel = opts[idx];
    final subColor =
        sel.meaning.isNotEmpty ? AppTheme.sub : AppTheme.hint;
    return InkWell(
      onTap: () => _openHanjaPicker(index, syllable),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.chipBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text('${index + 1}자',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.sub)),
            const SizedBox(width: 8),
            Text(syllable,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            ElementChip(sel.element),
            const SizedBox(width: 8),
            Text(sel.char,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: AppTheme.hanjaFontFallback)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                sel.meaning.isNotEmpty
                    ? '${sel.meaning} · ${sel.strokes}획'
                    : '뜻없음 · ${sel.strokes}획',
                style: TextStyle(fontSize: 13, color: subColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: AppTheme.sub),
          ],
        ),
      ),
    );
  }

  /// 음절 하나의 한자 선택 모달을 연다.
  /// 시트에서 고르면 인덱스가 바로 저장되고 시트가 닫힌다
  /// (시트가 값을 돌려주지 않는다).
  Future<void> _openHanjaPicker(int index, String syllable) async {
    final opts = _hanjaOptions(index, syllable);
    // 빈 목록 행은 탭되지 않지만, 혹시 호출돼도 크래시 없이 닫는다.
    if (opts.isEmpty) return;
    final sel = (_hanjaIdx[index] ?? 0).clamp(0, opts.length - 1);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: HanjaPickerSheet(
            syllable: syllable,
            options: opts,
            selectedIndex: sel,
            onSelected: (picked) {
              if (mounted) setState(() => _hanjaIdx[index] = picked);
            },
          ),
        ),
      ),
    );
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
      final opts = _hanjaOptions(i, syls[i]);
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

  Future<void> _analyzeCompat() async {
    if (_navigating) return;
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
    // 4번째 시도마다 전면 광고가 애니메이션 대신 뜨고,
    // 나머지 3번은 별 애니메이션을 보여준 뒤 궁합 화면으로 넘어간다.
    setState(() => _navigating = true);
    await InterstitialGate.goToResult(
      context,
      resultBuilder: (_) => CompatScreen(
        babyFullName:
            '${_surnamePick.name}${picks.map((p) => p.syllable).join()}',
        babyHanjaName:
            _isPureKorean ? '' : picks.map((p) => p.char).join(),
        isPureKorean: _isPureKorean,
        result: result,
      ),
      revealBuilder: (_) => RevealScreen(
        message: '가족 구성원 간 궁합을 알아보고 있어요',
        subMessage: '오행 보완·용신 조화·띠 궁합을 살펴보고 있어요.',
        nextBuilder: (_) => CompatScreen(
          babyFullName:
              '${_surnamePick.name}${picks.map((p) => p.syllable).join()}',
          babyHanjaName:
              _isPureKorean ? '' : picks.map((p) => p.char).join(),
          isPureKorean: _isPureKorean,
          result: result,
        ),
      ),
    );
    if (mounted) setState(() => _navigating = false);
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
      final defaultYear = memberDefaultYear(baseRole);
      birth = isGrand
          ? DateTime(defaultYear, 1, 1)
          : isElder
              ? DateTime(defaultYear, 5, 5)
              : DateTime(defaultYear, 3, 5);
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
          _members.add(FamilyMemberInput(label, result.birth!)
            ..time = result.time
            ..timeUnknown = result.timeUnknown);
        }
      }
    });
    unawaited(_saveMembers());
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
                              '${_members[i].birth.year}년 ${_members[i].birth.month}월 ${_members[i].birth.day}일 · ${_members[i].timeUnknown ? '시간 모름' : (_members[i].time == null ? '시간 미선택' : formatTimeOfDay(_members[i].time!))}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.sub),
                            ),
                          ],
                        ),
                      ),
                      if (_members.length > 1)
                        IconButton(
                          onPressed: () {
                            setState(() => _members.removeAt(i));
                            unawaited(_saveMembers());
                          },
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
      // 배경은 MainNav의 Starfield가 담당한다 (2026-11-13, 별빛 단일화).
      backgroundColor: Colors.transparent,
      body: SafeArea(
        // 하단 inset은 ListView 패딩이 처리한다 (2026-11-13 리뷰 반영).
        // SafeArea bottom을 켜 두면 하단 여백이 두 번 잡힐 수 있다.
        bottom: false,
        child: ListView(
          key: const Key('analyze_tab_body'),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.paddingOf(context).bottom),
          children: [
            // 헤더 — 공통 상수 appHeader (홈·이름 분석·설정 동일)
            appHeader,
            const SizedBox(height: 20),
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
                        // 성씨 정보와 변경 버튼을 한 Row에 두고 Spacer로
                        // 끝까지 밀어내 분리한다. 예전 Wrap(spaceBetween)은
                        // 너비가 빠듯하면 두 그룹이 달라붙어 보였고,
                        // 글자 크기가 달라 상하 중심도 어긋나 보였다.
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.35)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
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
                      onChanged: (_) => setState(() {
                            _hanjaIdx.clear();
                            _extraHanja.clear();
                          }),
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
                        _extraHanja.clear();
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
                            onTap: () {
                              setState(() => _gender = Gender.boy);
                              _syncShared();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GenderButton(
                            label: '여아',
                            icon: Icons.girl,
                            color: AppTheme.girl,
                            selected: _gender == Gender.girl,
                            onTap: () {
                              setState(() => _gender = Gender.girl);
                              _syncShared();
                            },
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
                      _hanjaSelectRow(0, syls[0]),
                      const SizedBox(height: 8),
                      _hanjaSelectRow(1, syls[1]),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _autoPickHanja,
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('사주에 맞는 한자 자동 선택'),
                        ),
                      ),
                      const Text(
                        '한자를 일일이 고르기 어려우면, 사주 기준으로 점수가 가장 높은 조합을 골라줘요.',
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.sub),
                      ),
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
                                  : formatTimeOfDay(_birthTime!))}',
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
                      onChanged: (v) {
                        setState(() => _timeUnknown = v ?? false);
                        _syncShared();
                      },
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
              onPressed:
                  _navigating ? null : (_compatMode ? _analyzeCompat : _analyze),
              child: Text(_compatMode ? '가족 궁합 보기' : '이 이름으로 분석하기'),
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
      ),
    );
  }
}

const _maxMembers = 6;

