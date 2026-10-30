# WorkManager / Room 유지 규칙
#
# 배경: google_mobile_ads가 내부적으로 WorkManager를 쓰고, WorkManager는
# Room 데이터베이스(WorkDatabase)를 리플렉션(이름으로 찾기)으로 생성한다.
# Flutter 릴리즈 빌드는 기본적으로 R8 축소·난독화를 켜는데, 유지 규칙이
# 없으면 R8이 WorkDatabase_Impl 클래스를 지우거나 이름을 바꿔버린다.
# 그러면 앱 시작 직후 androidx.startup 초기화 단계에서
# "Failed to create an instance of androidx.work.impl.WorkDatabase" 크래시가
# 나고 Flutter 코드가 실행되기도 전에 프로세스가 죽는다.
# (디버그 빌드는 R8을 안 돌려서 미리보기에서는 재현되지 않았다.)
#
# 이 파일은 Flutter 플러그인이 릴리즈 빌드 때 자동으로 proguardFiles에 추가한다.
# (android/app/proguard-rules.pro 가 존재할 때만 적용됨)

# WorkManager 전체 유지 (WorkDatabase_Impl 포함)
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Room 전체 유지 (WorkDatabase의 부모 클래스 계열 포함)
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**
