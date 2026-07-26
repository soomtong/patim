# Input Menu에 CFBundleName/버전 해시가 갱신되지 않는 문제

**분석 일자**: 2026-07-26

## 문제 설명

`CFBundleVersion` git-hash 스탬프 수정(0f3b4b2)과 `Localizable.strings` 추가(c4a8a57)를
반영해 재설치했음에도, 메뉴바 Input Menu에는 여전히 옛 상태가 보였음.

- 헤더에 `팥알입력기` 대신 로컬라이즈 키 이름 그대로인 `CFBundleName`이 표시됨
- 버전 라인이 `팥알입력기 v1.6.1 (0f3b4b2)`가 아니라 `팥알입력기 v1.6.1 (_HASH_)`로 표시됨

## 원인 분석

설치된 번들을 직접 검사하면 실제로는 정상이었음.

```bash
APP="/Users/$USER/Library/Input Methods/Patal.app"
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP/Contents/Info.plist"
# → 0f3b4b2  (git rev-parse --short HEAD 와 일치)
find "$APP/Contents/Resources" -iname "Localizable.strings"
# → en.lproj, ko.lproj 둘 다 존재, 내용도 정상
```

즉 빌드 파이프라인 수정(`Update Build Version with Git Commit` 스크립트 phase,
`Localizable.strings` PBXVariantGroup 등록)은 모두 올바르게 동작 중이었음.

문제는 macOS 시스템 프로세스인 `TextInputMenuAgent`
(`/System/Library/CoreServices/TextInputMenuAgent.app`)가 메뉴바 Input Menu의
표시 문자열(입력 소스 이름, 버전 등)을 **로그인 시점 등에 한 번 읽어 캐시**해두고,
입력기 번들을 재설치해도 캐시를 갱신하지 않는다는 점.

```bash
ps aux | grep TextInputMenuAgent
# → 입력기 재설치보다 훨씬 이전부터 떠 있던 PID 확인됨
```

번들 내용은 최신인데, 이를 그리는 에이전트가 옛 스냅샷을 계속 보여준 것.

## 해결 방법

`TextInputMenuAgent`는 사용자 소유의 per-user 에이전트이며 종료해도 시스템이
즉시 자동으로 재실행함(데이터 손실 없음, 안전).

```bash
make refresh-menu
# 내부적으로: killall TextInputMenuAgent
```

재실행된 에이전트가 번들 메타데이터를 다시 읽어 Input Menu에 최신 값이 표시됨.
재현되지 않으면 대안으로 로그아웃/로그인, 또는 시스템 설정 > 키보드 > 입력 소스에서
입력 소스를 제거 후 재등록하는 방법도 있음.

## 재발 방지

`CFBundleName`, `CFBundleVersion`, `CFBundleShortVersionString` 등 Input Menu에
직접 노출되는 메타데이터를 바꾼 뒤에는, 번들 내용만 확인하지 말고 아래 순서로
검증할 것.

1. 설치된 번들의 `Info.plist` / `Localizable.strings`가 최신인지 직접 확인
   (`PlistBuddy -c "Print :KEY" .../Info.plist`)
2. `make refresh-menu`로 Input Menu 캐시 새로고침
3. 메뉴바에서 실제 표시 확인

`make install`(`script/install.sh`) 자체에는 이 캐시 새로고침을 포함시키지 않고
`make refresh-menu`라는 별도 타깃으로 분리했음 — 일반적인 개발 사이클(단축키
로직 등 메뉴 텍스트와 무관한 변경)에서 매 설치마다 메뉴바 아이콘이 깜빡이는
부작용을 피하고, CFBundleName/버전 표시 문자열을 바꾼 경우에만 명시적으로
호출하도록 하기 위함.

## 관련 파일/커밋

| 대상 | 역할 |
|------|------|
| `script/install.sh` | 로컬 설치, `cp -R`로 DerivedData 유지, `killall Patal`로 입력기 프로세스만 재기동 |
| `Makefile` (`refresh-menu` 타깃) | `killall TextInputMenuAgent`로 Input Menu 캐시 새로고침, 필요할 때만 명시적으로 호출 |
| `macOS/Patal.xcodeproj/project.pbxproj` | `Update Build Version with Git Commit` 스크립트 phase, `Localizable.strings` PBXVariantGroup |
| `macOS/Resource/{en,ko}.lproj/Localizable.strings` | Input Menu가 조회하는 `CFBundleName` 로컬라이즈 테이블 |
| 커밋 `0f3b4b2` | 증분/재설치 빌드에서 git-hash 스탬프가 `_HASH_`로 남는 문제 수정 |
| 커밋 `c4a8a57` | Input Menu 헤더가 `CFBundleName` 키 이름 그대로 보이는 문제 수정 |

## 디버깅 명령어

```bash
# 설치된 번들의 실제 스탬프 확인
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" \
  "/Users/$USER/Library/Input Methods/Patal.app/Contents/Info.plist"

# Input Menu 관련 프로세스 기동 시각 확인
ps aux | grep -E "TextInputMenuAgent|imklaunchagent|Patal" | grep -v grep

# Input Menu 캐시 새로고침
make refresh-menu
```
