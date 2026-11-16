# 작명별 (Jakmyeongbyeol)

사주와 전통 성명학 기반으로 아기 이름을 추천·평가하는 Flutter 앱.

## 주요 기능

- **이름 추천**: 성씨·성별·생년월일시 입력 → 사주(용신/희신) 분석 → 한자 이름 최대 60개 후보(순우리말 49개)를 5개 차원으로 점수화해 추천
- **5차원 점수화** (100점 만점)
  - 수리 35% — 한자 원획 → 원격·형격·이격·정격 → 81수리 길흉 (대길/길/반길반흉/흉 4등급)
  - 사주 보완 25% — 사주에 부족한 오행(용신·희신)을 자원오행 한자로 보완
  - 발음 20% — 초성 발음오행 상생상극 + 받침·중복음절·이중모음 등 부르기 쉬움 평가
  - 음양 10% — 획수 홀짝 음양 배열 조화
  - 사용성 10% — 2024 출생신고 랭킹 기반 유행도, 읽기 쉬움, 놀림감 단어 필터
- **이름 상세 분석**: 종합 점수 링, 차원별 상세 풀이, 사주 팔자·오행 분포, 수리 사격표, 한자 바꾸기(실시간 재계산)
- **직접 분석**: 이미 정한 한글 이름 + 한자 선택 → 같은 기준으로 평가
- **아기 이름 랭킹**: 2024년 남/여 TOP 20 (출처: 법원 전자가족관계등록시스템) + 2025 트렌드 요약
- **보관함**: 마음에 드는 이름 저장 (기기 내 저장)

## 성명학 계산의 한계 (앱 내에도 고지)

- 만세력은 간이 계산: 절기 경계일(±1일) 출생, 23시 이후 출생 등은 전문 만세력과 대조 필요
- 용신은 신강/신약 + 조후 간이 로직 — 실제 감정은 격국·합충까지 보는 전문가 영역
- 자원오행·81수리 일부 수는 학파별 이견 존재 → 반길반흉 등급 + 상세 화면에 표시
- 한자 획수는 강희자전 원획 기준, 한자 DB는 대표 100여 자로 시작 (확장 예정)

## 실행 방법 (맥북 기준, 단계별)

### 0. 준비물
- Flutter SDK 3.x (없으면 https://docs.flutter.dev/get-started/install/macos 에서 설치)
- VS Code 또는 Android Studio (에디터)
- 안드로이드 실기기 또는 아이폰 실기기 (USB 케이블)

### 1. 압축 해제
`작명별_소스.zip`을 원하는 위치에 압축 해제합니다. (예: `~/projects/naming-star`)

### 2. 터미널에서 프로젝트 폴더로 이동
```bash
cd ~/projects/naming-star
```

### 3. Flutter 상태 확인 (최초 1회)
```bash
flutter doctor
```
- `!` 표시가 있으면 안내에 따라 해결합니다. (Android Studio, Xcode 등)
- 안드로이드 실기기 실행 시: 폰의 **설정 → 개발자 옵션 → USB 디버깅**을 켜고 USB로 연결합니다.

### 4. 패키지 설치
```bash
flutter pub get
```

### 5. 실행
```bash
flutter run
```
- 연결된 기기가 여러 대면 번호를 선택하라는 메시지가 나옵니다.
- 아이폰 시뮬레이터만 띄우려면: `open -a Simulator` 후 `flutter run`
- 첫 실행은 Gradle/Xcode 빌드 때문에 3~10분 걸릴 수 있습니다.

### 6. 릴리즈 빌드 (배포용 파일 만들기)
```bash
# 안드로이드 APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# iOS (Apple Developer 계정 필요)
flutter build ipa --release
```

### 자주 겪는 문제
- `flutter: command not found` → Flutter SDK의 `bin` 폴더를 PATH에 등록했는지 확인
- 안드로이드 기기가 안 잡힘 → USB 디버깅 ON, 케이블이 데이터 통신용인지 확인, `flutter devices`로 확인
- iOS 실기기 실행 시 서명 오류 → Xcode에서 Runner 프로젝트의 Signing에 본인 Apple ID로 팀 설정

## 테스트

```bash
flutter test      # 일주 기준일 검증(2026-08-30=병자일) + 엔진 스모크 테스트
flutter analyze   # No issues
```

## 프로젝트 구조

```
lib/
  main.dart            # 하단 내비게이션 (홈/이름 분석/랭킹/보관함)
  theme.dart           # 디자인 시스템
  models.dart          # BabyInfo, SajuResult, NameAnalysis 등
  favorites.dart       # 보관함 저장소 (shared_preferences)
  data/
    hanja.dart         # 이름 한자 DB (음절→한자, 원획, 자원오행, 뜻)
    suri81.dart        # 81수리 길흉표
    surnames.dart      # 성씨 원획표
    rankings.dart      # 2024 남/여 아기 이름 TOP 20
  engine/
    saju.dart          # 간이 만세력 (연월일시주, 오행 분포, 용신/희신)
    scoring.dart       # 5차원 점수 엔진
    generator.dart     # 후보 이름 생성
  screens/
    home_screen.dart      # 아기 정보 입력
    recommend_screen.dart # 추천 리스트
    detail_screen.dart    # 상세 분석 + 한자 바꾸기
    analyze_screen.dart   # 직접 입력 분석
    ranking_screen.dart   # 랭킹
    favorites_screen.dart # 보관함
  widgets/common.dart  # 점수 링, 차원 바, 섹션 카드 등
```

## 향후 과제

- [ ] '작명별' 상표 키프리스 조회 (출시 전)
- [ ] 한자 DB 확장 (현재 100여 자 → 수백 자)
- [ ] 순우리말 이름 분석 지원
- [ ] 넴유베 특허(10-1514656) 회피 검토 — 분석 로직 표현·화면 흐름은 자체 설계이나 출시 전 변리사 확인 권장
