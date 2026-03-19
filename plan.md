# Option 키 라틴 입력 기능 구현 계획

## 목표

한글 입력기 활성 상태에서 Option(Alt) 키를 누른 채 글자 키를 누르면, macOS 시스템 특수문자(예: ∫, ƒ, ∂) 대신 **표준 라틴 알파벳 문자**(예: b, f, d)가 commit 되도록 한다.

## 현재 동작

1. `verifyProcessable()`에서 `managableModifiers`에 `NONE`과 `SHIFT`만 포함
2. Option 키가 눌리면 `modifierCode`가 `524288`(ALT)이므로 `return false`
3. 조합 중이던 한글은 flush 되고, OS가 Option+key 조합의 특수문자를 출력

## 변경 계획

### 1단계: LayoutTrait 추가

**파일: `macOS/Patal/HangulLayout.swift`**

- `LayoutTrait` enum에 `옵션라틴` case 추가
- `HangulAutomata` extension에 `can옵션라틴` computed property 추가

### 2단계: 각 자판 레이아웃에 trait 등록

**파일: `macOS/Patal/Layouts/Han3P3.swift`, `Han3ShinP2.swift`, `Han3ShinPcsLayout.swift`**

- 3개 자판 모두의 `availableTraits`에 `옵션라틴` 추가 (선택 가능하도록)
- `traits` 기본값에는 포함하지 않음 (사용자가 직접 켜야 함)

### 3단계: PatalInputController에서 Option+키 처리

**파일: `macOS/Patal/PatalInputController.swift`**

`inputText` 메서드에서 `verifyProcessable` 호출 전에 Option 키 분기 추가:

```
if modifiers == ModifierCode.ALT.rawValue (또는 ALT+SHIFT)
   && processor.hangulLayout.can옵션라틴
   && KeyCodeMapper.isHangulInputKey(keyCode)
then:
   1. 조합 중인 한글 flush → client.insertText
   2. KeyCodeMapper.mapKeyCodeToHangulChar(keyCode, modifiers=0 또는 SHIFT만) → 라틴 문자 획득
   3. client.insertText(라틴문자) → commit
   4. return true (OS에 전달하지 않음)
```

핵심: Option 비트를 제거하고 SHIFT만 남겨서 KeyCodeMapper에 전달하면 `physicalKeyMap`/`shiftKeyMap`에서 표준 라틴 문자를 얻을 수 있다.

### 4단계: 테스트 작성

**파일: `macOS/PatalTests/` 하위에 테스트 추가**

- `can옵션라틴` trait 활성/비활성 시 동작 확인
- Option+키 입력 시 라틴 문자 반환 확인
- Option+Shift+키 입력 시 대문자 라틴 문자 반환 확인
- trait 비활성 시 기존 동작(OS 위임) 유지 확인

## 수정 파일 목록

| 파일 | 변경 내용 |
|---|---|
| `macOS/Patal/HangulLayout.swift` | `옵션라틴` trait case + `can옵션라틴` property |
| `macOS/Patal/Layouts/Han3P3.swift` | `availableTraits`에 `옵션라틴` 추가 |
| `macOS/Patal/Layouts/Han3ShinP2.swift` | `availableTraits`에 `옵션라틴` 추가 |
| `macOS/Patal/Layouts/Han3ShinPcsLayout.swift` | `availableTraits`에 `옵션라틴` 추가 |
| `macOS/Patal/PatalInputController.swift` | Option 키 라틴 입력 분기 로직 |
| `macOS/PatalTests/` | 관련 테스트 |

## 설계 포인트

- **trait 기반 토글**: 메뉴에서 켜고 끌 수 있어 사용자 선택권 보장
- **KeyCodeMapper 재활용**: 새 매핑 테이블 불필요. 기존 `physicalKeyMap`/`shiftKeyMap` 사용
- **Option+Shift 지원**: modifier에서 ALT 비트를 제거하고 SHIFT만 남겨 대소문자 구분
- **조합 flush 우선**: Option 키 입력 시 진행 중인 한글 조합을 먼저 commit
