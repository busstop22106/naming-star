# 작명별 공유 링크 사이트 (Netlify 무료 서브도메인)

공유용 짧은 링크의 랜딩 페이지. `https://jakmyeongbyeol.netlify.app`에 배포한다.
도메인 구매 없이 무료 서브도메인을 쓰는 결정 (2026-11-13).

## 파일
- `share.html` — 랜딩 페이지. `/s/<토큰>`(짧은 링크)과 `/share.html?전체파라미터` 둘 다 받는다. 토큰은 앱 쪽 `encodeShareToken`과 같은 규칙으로 디코드한다. 미리보기(이름·생년월일·시간·남자/여자) + "앱에서 결과 보기" intent 버튼 + Play 스토어 폴백.
- `_redirects` — `/s/*`를 URL을 유지한 채 `share.html`로 연결한다 (Netlify rewrite).
- `.well-known/assetlinks.json` — App Links 검증 파일. **지문이 아직 비어 있다.** 아래 순서대로 채워야 App Links(링크 탭 → 앱 바로 열기)가 동작한다.

## Netlify 배포 (드래그앤드롭, 빌드 없음)
1. Netlify(https://app.netlify.com)에 로그인 → 팀 '버스정류장' 선택.
2. "Add new site" → "Deploy manually" → 이 폴더(`netlify-site/`)를 통째로 드래그앤드롭.
   - 빌드 명령어 없음. 정적 파일만 올라간다 (팀 크레딧을 쓰지 않는다).
3. 배포된 사이트 → Site settings → Site details → "Change site name" → `jakmyeongbyeol`로 변경.
   - 이미 선점돼 있으면 `jakmyeongbyeol-app`으로 하고 Muse에게 알려줄 것 (앱 코드의 호스트 상수도 같이 바꿔야 한다).
4. 확인: `https://jakmyeongbyeol.netlify.app/share.html`이 열리면 배포 완료.

## assetlinks.json 지문 채우기 (App Links 동작 조건)
지문이 비어 있으면 App Links 검증이 안 돼서, 링크를 눌러도 브라우저 랜딩 페이지가 뜨고 거기서 intent 버튼을 눌러 앱을 여는 흐름으로 동작한다 (고장이 아니라 폴백이다). 앱이 바로 열리게 하려면 지문 3개를 채우고 이 폴더를 다시 배포한다.

**1. 앱 서명 키 지문 (스토어 설치 앱용 — 가장 중요)**
Play Console → 설정 → 앱 무결성 → "앱 서명 키 인증서" → SHA-256 지문을 복사한다.
스토어에서 설치한 앱은 구글의 앱 서명 키로 서명돼 있어서, 이 지문이 있어야 검증이 된다. 업로드 키 지문만으로는 안 된다.

**2. 업로드 키 지문 (맥북 AAB 빌드용)**
맥북에서 업로드 키스토어로 실행:
`keytool -list -v -keystore <업로드 키스토어 경로> -alias <별칭> | grep SHA256`

**3. 디버그 키 지문 (맥북 로컬 디버그 빌드용)**
맥북에서 실행:
`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android | grep SHA256`

3개 지문을 `sha256_cert_fingerprints` 배열에 넣고 다시 배포한다.
(Actions 디버그 APK 지문은 러너마다 새로 생기는 키라 쓸 수 없다 — 위 맥북 디버그 키만 유효하다.)
