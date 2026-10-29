import 'package:flutter/material.dart';
import '../engine/saju.dart';
import '../models.dart';
import '../services/ad_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/surname_picker.dart';
import 'recommend_screen.dart';
import 'reveal_screen.dart';

/// 홈 — 아기 정보 입력
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SurnamePick _surnamePick =
      const SurnamePick(name: '김', hanja: '金', strokes: 8);
  Gender _gender = Gender.boy;
  DateTime _birth = DateTime(2026, 10, 19);
  TimeOfDay? _birthTime;
  bool _timeUnknown = false;
  bool _isPureKorean = false;

  Future<void> _chooseSurname() async {
    final pick = await showSurnamePicker(context, _surnamePick);
    if (pick != null) {
      setState(() => _surnamePick = pick);
    }
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

  void _goRecommend() {
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
    // 결과를 바로 보여주지 않고 별 애니메이션으로 기대감을 준 뒤 공개
    // (출시 후 전면 광고는 RevealScreen 자리에 붙일 예정)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RevealScreen(
          nextBuilder: (_) => RecommendScreen(
              baby: baby, saju: saju, isPureKorean: _isPureKorean),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_birth.year}년 ${_birth.month}월 ${_birth.day}일';
    final timeStr = _timeUnknown
        ? '모름'
        : (_birthTime == null
            ? '선택 안 함'
            : '${_birthTime!.hour}시 ${_birthTime!.minute}분');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            // 헤더
            const StarHero(
              title: '작명별',
              subtitle: '사주와 성명학으로 짓는 아기 이름',
            ),
            const SizedBox(height: 20),
            // 성씨 선택
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('성씨',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _chooseSurname,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Text(
                                _surnamePick.hanja.isEmpty
                                    ? _surnamePick.name
                                    : _surnamePick.hanja,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _surnamePick.hanja.isEmpty
                                        ? _surnamePick.name
                                        : '${_surnamePick.name}(${_surnamePick.hanja})',
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight:
                                            FontWeight.w800),
                                  ),
                                  Text(
                                    '획수 ${_surnamePick.strokes}획 · 자동 적용됨',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.sub),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppTheme.sub),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        '성씨를 누르면 전체 목록에서 고를 수 있어요. 한자를 고르면 획수가 자동 입력됩니다.',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.sub)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // 성별
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
            const SizedBox(height: 4),
            // 생년월일시
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('생년월일시',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cake_outlined,
                          color: AppTheme.primary),
                      title: Text(dateStr,
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
                      title: Text('태어난 시간 · $timeStr',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickTime,
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('태어난 시간을 몰라요',
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
            const SizedBox(height: 4),
            // 이름 종류
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('이름 종류',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
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
                      onSelectionChanged: (s) =>
                          setState(() => _isPureKorean = s.first),
                    ),
                    if (_isPureKorean) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '순우리말 이름은 한자가 없어 한글 자모 획수로 수리를 계산하고, 초성의 발음오행으로 사주를 보완하는 간이 계산이에요.',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.sub),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _goRecommend,
              child: const Text('아기에게 좋은 이름 지어보기'),
            ),
            const SizedBox(height: 16),
            const Text(
              '작명별의 분석은 전통 성명학의 간이 계산이에요. 수리·음양·오행은 학파별 차이가 있을 수 있으니 중요한 결정 전에는 전문가 상담을 권장합니다.',
              style: TextStyle(fontSize: 11, color: AppTheme.sub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // 하단 배너 광고 (AdService.bannerEnabled 플래그로 제어)
            if (AdService.bannerEnabledFor(AdPlacement.home))
              const Center(child: BannerAdWidget()),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

