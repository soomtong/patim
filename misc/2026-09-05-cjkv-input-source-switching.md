# CJKV 입력 소스 전환 문제와 ESC라틴 구현 기록

**작성일**: 2026-09-05
**관련 PR**: [soomtong/patim#17](https://github.com/soomtong/patim/pull/17)
**관련 브랜치**: `esc-to-latin` (채택), `esc-latin` (폐기)

ESC 키로 라틴 자판으로 빠져나가는 기능을 구현하면서 조사한 내용과 시행착오를 정리한다.
"입력기 아이콘은 바뀌는데 입력은 그대로"라는 증상을 다시 만났을 때 이 문서부터 읽는다.

---

## 1. 문제 정의

프로그램에서 `TISSelectInputSource`로 입력 소스를 바꿀 때, 대상이 중국어·일본어·한국어·베트남어(CJKV)
입력기이면 간헐적으로 실패한다. 증상이 매우 특징적이다.

> 메뉴바 아이콘은 바뀌는데 실제 입력은 이전 입력기 그대로다.
> 다른 앱으로 포커스를 옮겼다 돌아와야 비로소 적용된다.

Karabiner-Elements 공식 문서는 **`input_mode_id` 속성을 가진 입력 소스(=CJKV)는 macOS 이슈로 전환이
실패할 수 있다**고 명시하고, 그 경우 API 대신 단축키 전송을 권한다. Kawa README는 "Carbon 라이브러리의
알려진 버그"로 기술한다. macOS 26(Tahoe)에서도 여전하다.

## 2. 왜 CJKV만 실패하는가

라틴 자판(`.keylayout`)과 CJKV 입력기는 구조가 다르다.

| | 라틴 자판 | CJKV 입력기 |
| --- | --- | --- |
| 정체 | 키코드→문자 매핑 테이블 | IMKit 기반 별도 프로세스 |
| 전환 시 | 테이블 교체로 끝 | 새 `IMKInputController` 생성 + `activateServer`/`deactivateServer` 핸드셰이크 |
| `TISSelectInputSource` | 즉시 반영 | 시스템의 "선택된 소스" 상태만 바뀌고 반환 |

CJKV로 전환하면 실제 키 이벤트 라우팅이 새 IME 프로세스로 넘어가는 것이 **비동기**다.
`TISSelectInputSource`는 상태만 바꾸고 돌아오므로, 클라이언트의 `NSTextInputContext`가 새 소스에
재바인딩하기 전에 타이핑이 들어오면 이전 입력기가 받는다. 포커스가 바뀌면 컨텍스트가
deactivate → activate를 거치며 현재 소스를 다시 읽기 때문에 그제야 적용된다.

**중요한 귀결**: 버그는 **CJKV로 들어오는** 방향에서 난다. 라틴으로 **나가는** 방향은 원래 잘 된다.

## 3. 오픈소스들의 우회법

| 프로젝트 | 접근 | 결과 |
| --- | --- | --- |
| [macism](https://github.com/laishulu/macism) | 전환 후 3×3px 더미 윈도우를 띄워 포커스를 강제 전환 | 현행 유지 |
| [kawa](https://github.com/hatashiro/kawa) | "다음 소스 선택" 단축키를 목표에 닿을 때까지 반복 | **철회** (v0.1.3) |
| [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements/issues/1602) | CJKV 대상에는 ⌃Space 단축키 전송 권장 | 문서화 |
| [Gureum](https://github.com/gureum/gureum) | 라틴 자판을 자기 번들에 포함해 전환 자체를 안 함 | 현행 유지 |

### macism — 가장 노골적인 우회

`InputSourceManager.swift`가 `kTISPropertyInputSourceLanguages`로 CJKV를 판정한 뒤, CJKV일 때만
더미 윈도우를 띄운다.

```swift
var isCJKV: Bool {
    if let lang = tisInputSource.sourceLanguages.first {
        return lang == "ko" || lang == "ja" || lang == "vi" || lang.hasPrefix("zh")
    }
    return false
}

func select() {
    if !self.isCJKV {              // 라틴이면 그냥 되므로 특별 처리 없음
        TISSelectInputSource(tisInputSource)
        return
    }
    TISSelectInputSource(tisInputSource)
    showTemporaryInputWindow(waitTimeMs: InputSourceManager.waitTimeMs)  // ← 우회
}
```

`WindowUtils.swift`의 더미 윈도우는 화면 우하단 3×3px, `.screenSaver` 레벨, 보라색 배경이다.
`activate(ignoringOtherApps: true)`로 포커스를 뺏고 대기한 뒤 종료한다. 주석에 캘리브레이션 기록이
있다 — 예전 macOS는 1ms면 됐는데 **macOS 26에서는 1ms일 때 30~50% 확률로 레이스가 나서 기본값이
150ms**가 됐다.

### kawa — 우회를 넣었다가 뺀 사례

kawa#21에서 "다음 소스 선택" 단축키를 반복 전송하는 방식을 시도했다. 발견된 실패 조건:

- `TISCopyCurrentKeyboardInputSource`는 타이핑이나 윈도우 전환 없이 빠르게 연속 전환하면 틀린 값을 반환
- `TISCreateInputSourceList`의 순서가 macOS의 실제 전환 순서와 일치하지 않음
- High Sierra에서 되던 것이 Mojave에서 깨짐

메인테이너는 "버그를 더 만들어서 득보다 실이 컸다"며 제거하고 OS 수정을 기다리는 중이다.

### Gureum — 문제를 풀지 않고 우회

Gureum `OSX/Info.plist`는 입력 모드 16개를 선언하는데 그중 4개(`system`, `qwerty`, `dvorak`,
`colemak`)가 `TISIntendedLanguage = en`이다. Gureum에게 "영문 전환"은 입력 소스 전환이 아니라
**자기 번들 안에서의 모드 전환**이고 `IMKTextInput.selectMode(_:)`로 처리한다. IME 프로세스 경계를
넘지 않으니 레이스가 발생할 수 없다. Gureum 소스 전체에 `TISSelectInputSource` 호출이 0건인 이유다.

ESC 전환은 `romanModeByEscapeKey` 옵션으로 구현되어 있다 (`GureumComposer.swift:287`).

```swift
if delegate is HangulComposer {
    // Vi-mode: esc로 로마자 키보드로 전환
    if Configuration.shared.romanModeByEscapeKey {
        if keyCode == .escape || inputKey == (.ansiLeftBracket, .control) {
            return .changeLayout(.roman, false)   // processed = false
        }
    }
}
```

두 번째 인자 `false`가 중요하다. ESC를 소비하지 않고 앱에 흘려보낸다. 테스트
`testViModeEscape`가 `XCTAssertFalse(processed)`로 이를 못박아 뒀다. 삼키면 전환은 되지만 vi가
노멀 모드로 들어가지 못한다.

## 4. 클라이언트 측 사례 — Tinycast

Tinycast(macOS 런처)는 팔레트를 열 때 라틴으로, 닫을 때 원래 입력기로 되돌린다. 우회 코드가 전혀
없는데 동작한다. 두 가지 이유다.

1. **전환 API가 다르다.** 전역 `TISSelectInputSource`가 아니라 팔레트 텍스트 필드의
   `NSTextInputContext.selectedKeyboardInputSource`에 건다. 클라이언트 자신의 컨텍스트를 통하는
   문서화된 경로다.
2. **포커스 전환이 공짜로 따라온다.** 적용은 `makeFirstResponder` 시점(필드가 포커스를 잡는 전이의
   일부)에, 복원(`TISSelectInputSource(한글)`)은 `previousApp.activate()` 직전에 일어난다.
   macism이 150ms 더미 윈도우로 인위적으로 만드는 커밋 트리거를 Tinycast는 원래 하던 일로 갖는다.

**교훈**: 클라이언트 앱은 자기 컨텍스트로 전환하면 된다. IME는 그 경로가 없다.

## 5. IMKit API 정리 — IME가 쓸 수 있는 것과 없는 것

`IMKInputSession.h`(HIToolbox) 헤더 주석 기준.

| API | 하는 일 | 다른 입력 소스로 전환 |
| --- | --- | --- |
| `overrideKeyboardWithKeyboardNamed:` | "tells the text service manager to use that layout for keyboard events" — 현재 IME 세션의 키코드→문자 레이아웃만 교체 | **불가** |
| `selectInputMode:` | "should match one of the keys in the ComponentInputModeDict" — 자기 번들의 모드만 | **불가** |
| `TISSelectInputSource` (Carbon) | 전역 입력 소스 선택 | 가능 (단, §1·§6 제약) |
| `TISCopyCurrentASCIICapableKeyboardInputSource` | macOS가 관리하는 "가장 최근에 쓴 ASCII 자판" 반환 | 대상 선정에 사용 |

IME가 **다른** 입력 소스로 넘어갈 클라이언트 측 API는 존재하지 않는다. 남는 길은 TIS뿐이다.

## 6. 두 번째 문제 — App Sandbox

이 프로젝트에서 실제로 기능을 막고 있던 것은 §1의 버그가 아니라 **샌드박스**였다.

증상이 같아서 하나로 보인다. 나가는 방향(팥알 → 라틴)은 §2에 따라 안전해야 하는데 첫 실기 테스트에서
아이콘만 바뀌고 입력은 한글로 남았다. 엔타이틀먼트에 `com.apple.security.app-sandbox = true`가
있었고, Apple 포럼 스레드 791960이 정확히 이 조합을 보고하고 있었다.

> 샌드박스를 켜면 메뉴바 아이콘은 성공적으로 바뀌지만, 실제 입력은 여전히 이전 입력기다.
> `DispatchQueue.main.async`로 미뤄도 마찬가지다.

Apple 답변은 없었다. 샌드박스만 뺀 빌드로 다시 테스트하니 즉시 동작했다.

다른 서드파티 IME들의 선택:

| IME | 샌드박스 |
| --- | --- |
| Squirrel (rime) | **명시적으로 `app-sandbox = false`** |
| fcitx5-macos | 없음 |
| OpenVanilla | 없음 |
| Gureum | 켜짐 — TIS 전환을 아예 안 쓰므로 영향 없음 |

팥알이 샌드박스로 얻는 것은 없다. 네트워크도 파일 접근도 하지 않고, `~/Library/Input Methods/`에
설치되는 IME라 App Store 요건도 아니다. Squirrel처럼 엔타이틀먼트에 `false`를 **명시**해 두어 Xcode
UI에서 무심코 다시 켜지지 않게 했다.

## 7. 팥알의 시행착오

### 1차 시도 — `esc-latin` 브랜치 (2026-02, 폐기)

| 커밋 | 내용 | 문제 |
| --- | --- | --- |
| `96dd5a3` | `TISSelectInputSource` + 하드코딩된 영문 자판 우선순위 목록 | **방향은 맞았으나** 샌드박스 때문에 동작하지 않았을 것. Dvorak 사용자도 ABC로 끌려감 |
| `4c311dc` | `client.overrideKeyboard(withKeyboardNamed:)`로 선회 | 입력 소스 전환 API가 아님 (§5). 팥알이 선택된 채로 한글을 계속 조합 |

첫 커밋이 안 되는 이유를 모른 채 다른 API로 선회했고, 그 API는 애초에 목적에 맞지 않았다.
9,210줄짜리 `session-ses_3d1d.md`가 함께 커밋되어 있다.

### 2차 시도 — `esc-to-latin` 브랜치 (2026-09, 채택)

1. `Info.plist` 확인: 팥알 모드 3개 전부 `TISIntendedLanguage = ko`, `tsInputModeIsASCIICapableKey`
   없음 → `TISCopyCurrentASCIICapableKeyboardInputSource`가 팥알 자신을 돌려줄 일이 없음
2. 이 머신에서 API 동작 확인 (`com.apple.keylayout.ABC` 반환)
3. 구현 + 단위 테스트 4개, `make test` 311개 통과
4. **첫 실기 테스트 실패** — 아이콘만 라틴, 입력은 한글
5. 엔타이틀먼트에서 `app-sandbox = true` 발견, 포럼 791960과 대조
6. xcodebuild 오버라이드(`ENABLE_APP_SANDBOX=NO`, 임시 entitlements)로 샌드박스만 뺀 빌드 설치
7. **실기 테스트 성공**
8. 추적 설정(`Patal.entitlements`, `project.pbxproj`)에 반영, `make debug` 결과물로 재확인

## 8. 최종 구현

```swift
// Util.swift
@discardableResult
func selectLatinInputSource() -> Bool {
    // 팥알은 ASCII 자판이 아니므로 이 API는 팥알이 아닌 직전 라틴 자판을 돌려준다
    guard let source = TISCopyCurrentASCIICapableKeyboardInputSource()?.takeRetainedValue() else {
        return false
    }

    return TISSelectInputSource(source) == noErr
}
```

```swift
// PatalInputController.swift — inputText 안
if keyCode == KeyCode.ESC.rawValue && modifiers == ModifierCode.NONE.rawValue
    && processor.hangulLayout.canESC라틴
{
    let flushed = processor.flushCommit()            // ① 조합 중인 글자를 먼저 확정
    if !flushed.isEmpty {
        flushed.forEach { client.insertText($0, replacementRange: .notFoundRange) }
    }
    // TIS 전환은 이 컨트롤러를 해제하므로 현재 이벤트를 반환한 뒤로 미룬다
    DispatchQueue.main.async { [logger] in           // ② 전환은 다음 런루프로
        let switched = selectLatinInputSource()
        logger.debug("ESC라틴 전환: \(switched)")
    }
    // ESC 자체는 앱이 받아야 vi가 노멀 모드로 들어간다
    return false                                     // ③ ESC를 삼키지 않는다
}
```

### 결정 사항

| 결정 | 이유 |
| --- | --- |
| **한 방향만** (한글 → 라틴) | 돌아오는 방향이 §1 버그의 방향. 시스템 한/영 키가 이미 안정적으로 처리 |
| **대상 자판을 고르지 않음** | `TISCopyCurrentASCIICapableKeyboardInputSource`가 사용자가 쓰던 자판을 돌려줌. 우선순위 목록·설정 불필요 |
| **라틴 자판을 번들에 넣지 않음** | 팥알은 한글 조합만 담당. Gureum 방식은 시스템 입력 메뉴에 팥알 영문 항목이 추가되고 사용자가 자기 ABC/Dvorak 대신 그걸 써야 함 |
| **`LayoutTrait.ESC라틴`, 기본 꺼짐** | ESC가 입력 소스를 바꾸는 건 모르고 쓰면 놀랄 동작. Gureum도 기본 `false`. 기존 사용자는 저장된 trait에 없으므로 영향 없음 |
| **`Util.swift`에 배치** | `macOS/Patal/`은 `PBXFileSystemSynchronizedRootGroup`이 아니라 신규 파일마다 pbxproj 수동 편집 필요. TIS 헬퍼가 이미 그 파일에 있음 |
| **샌드박스 해제** | §6 |

## 9. 진단 체크리스트

"아이콘은 바뀌는데 입력은 그대로"를 만나면 순서대로 확인한다.

1. **샌드박스인가?** `codesign -d --entitlements - <앱>`으로 `app-sandbox` 확인. 켜져 있으면 그게
   원인일 가능성이 가장 높다. 샌드박스만 뺀 빌드로 먼저 판별한다 (§7 2차 시도 6번).
2. **방향이 CJKV로 들어오는가?** 그렇다면 §1 버그. 포커스 전환을 뒤에 붙이거나(§3 macism, §4
   Tinycast), 그 방향을 포기하거나(§8), 번들 내부 모드로 바꾼다(§3 Gureum).
3. **`TISSelectInputSource`의 반환값은?** `noErr`인데 안 되면 1·2번. 에러면 소스가 select-capable이
   아니거나 활성화되지 않은 것 (`TISEnableInputSource` 선행).
4. **IME 안에서 동기로 호출했는가?** 자기 자신을 해제하는 호출이다. 조합을 먼저 비우고 다음 런루프로
   미룬다.
5. **`TISCopyCurrentKeyboardInputSource`를 전환 직후 읽었는가?** 타이핑·윈도우 전환 없이 연속
   호출하면 틀린 값을 준다 (kawa#21). 마지막 선택값을 직접 캐시한다.

외부 프로세스에서 같은 전환을 걸어보는 것도 유용한 판별법이다. 샌드박스 없는 CLI에서 되고 IME
안에서 안 되면 1번, CLI에서도 안 되면 2번이다.

```swift
// 3초 뒤 현재 ASCII 자판으로 전환하는 판별용 CLI
Thread.sleep(forTimeInterval: 3)
let ascii = TISCopyCurrentASCIICapableKeyboardInputSource()!.takeRetainedValue()
print(TISSelectInputSource(ascii) == noErr)
```

## 10. 후속 과제

- **ESC 캡처 한계** — `inputText`만 오버라이드하면 일부 앱에서 ESC가 들어오지 않는다 (`Note.md` Day 5).
  Gureum은 `handle(_:client:)` + `recognizedEvents(_:)`를 쓴다. 안 잡히는 앱이 실제로 나오면 그
  마이그레이션이 필요하며, 입력 경로 전체를 건드리는 변경이다.
- **`esc-latin` 브랜치 정리** — 로컬·원격 삭제. `session-ses_3d1d.md` 포함.
- **샌드박스 잔재 정리** — `ENABLE_RESOURCE_ACCESS_BLUETOOTH`/`USB`, `ENABLE_USER_SELECTED_FILES`는
  샌드박스 없이 무의미하다. 빌드 시 `device.bluetooth` 등 엔타이틀먼트를 계속 주입하므로 정리 대상.

## 11. 참고

- [sandbox causes the input method switch to fail to take effect — Apple Developer Forums](https://developer.apple.com/forums/thread/791960)
- [A Swift input method switcher works only after changing focus to another window — Apple Developer Forums](https://developer.apple.com/forums/thread/748791)
- [Workaround for CJKV input sources switching issue · Karabiner-Elements#1602](https://github.com/pqrs-org/Karabiner-Elements/issues/1602)
- [Karabiner-Elements — `to.select_input_source`](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/select-input-source/)
- [laishulu/macism](https://github.com/laishulu/macism) — `InputSourceManager.swift`, `WindowUtils.swift`
- [Select CJK input methods by pressing NEXT_INPUT_METHOD key · kawa#21](https://github.com/hatashiro/kawa/pull/21)
- [gureum/gureum](https://github.com/gureum/gureum) — `OSX/Info.plist`, `OSXCore/GureumComposer.swift`, `OSXCore/InputReceiver.swift`
- [rime/squirrel](https://github.com/rime/squirrel) — `resources/Squirrel.entitlements`
- [NSTextInputContext.selectedKeyboardInputSource — Apple Developer Documentation](https://developer.apple.com/documentation/appkit/nstextinputcontext/selectedkeyboardinputsource)
- Tinycast `Tinycast/Platform/InputSourceSwitcher.swift`, `Tinycast/Palette/PaletteWindowController.swift`
