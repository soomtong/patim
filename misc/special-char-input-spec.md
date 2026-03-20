# 기호 확장 배열 구현 스펙

## 설계 원칙

**불가능한 자소 조합을 기호 트리거로 사용한다.**

세벌식 자판에서 한글 조합 규칙상 존재할 수 없는 자소 조합이 있다.
현재 상태머신은 이런 조합이 들어오면 "이전 글자 커밋 + 새 글자 시작"으로 처리한다.
기호 확장은 이 커밋 대신 기호 입력 모드로 전환하는 것이다.

| 자판 | 불가능한 조합 | 현재 동작 | 기호 확장 동작 |
|------|-------------|----------|-------------|
| 신세벌 P2/PCS | 초성+초성 (ㅇ+ㄱ) | ㅇ 커밋, ㄱ 새 조합 | 기호 모드 진입 |
| 공세벌 P3 | 겹중성 (ㅗ+ㅗ) | ㅗ 커밋, ㅗ 새 조합 | 기호 모드 진입 |

두 자판 모두 **같은 패턴**: 트리거 자소 입력 → 불가능한 후속 자소 → 기호 모드.

## 자판별 기호 확장 구조

### 신세벌식 P2/PCS — 초성 충돌 (3키 시퀀스)

첫소리 ㅇ(j) + 단 선택 초성(k/l/;) + 기호 키의 3키 시퀀스.
ㅇ 뒤에 ㄱ/ㅈ/ㅂ은 겹자음이 될 수 없으므로 트리거로 쓸 수 있다.

```
[트리거] → [단 선택]  → [기호 키]
   j(ㅇ) →    k(ㄱ)   →   g        = … (예시)
   j(ㅇ) →    l(ㅈ)   →   f        = ♠ (예시)
   j(ㅇ) →    ;(ㅂ)   →   d        = ★ (예시)
   j(ㅇ) →    k(ㄱ)   →   Shift+g  = ♣ (예시, 4단)
```

| 단 | 키 조합 | 비고 |
|----|---------|------|
| 1단 | j → k → [키] | |
| 2단 | j → l → [키] | |
| 3단 | j → ; → [키] | |
| 4단 | j → k → Shift+[키] | 기호 키에 Shift |
| 5단 | j → l → Shift+[키] | 기호 키에 Shift |
| 6단 | j → ; → Shift+[키] | 기호 키에 Shift |

Shift는 **단 선택 키가 아니라 기호 키(3번째 키)**에 적용된다.

### 공세벌식 P3 — 겹중성 충돌 (3키 시퀀스)

오른쪽 ㅗ(`/`)·ㅜ(`9`) 2회 누름 + 기호 키의 3키 시퀀스.
`/`+`/`(ㅗ+ㅗ), `9`+`9`(ㅜ+ㅜ)는 유효한 겹모음이 아니므로 트리거로 쓸 수 있다.

```
[트리거]  → [같은 키] → [기호 키]
   /(ㅗ) →    /(ㅗ)  →   f        = · (예시)
   9(ㅜ) →    9(ㅜ)  →   s        = □ (예시)
   /(ㅗ) →    /(ㅗ)  →   Shift+f  = ♠ (예시, 3단)
```

| 단 | 키 조합 | 비고 |
|----|---------|------|
| 1단 | / → / → [키] | ㅗ+ㅗ (2회 누름) |
| 2단 | 9 → 9 → [키] | ㅜ+ㅜ (2회 누름) |
| 3단 | / → / → Shift+[키] | 기호 키에 Shift |
| 4단 | 9 → 9 → Shift+[키] | 기호 키에 Shift |

왼쪽 ㅗ(`v`)·ㅜ(`b`)는 기호 확장과 무관하다. KeyCodeMapper가 물리 키코드 기반으로
`v`와 `/`를 구분하므로, rawKey 값으로 좌/우를 식별할 수 있다.

### 모아주기와의 공존

**공세벌 P3에서 기호확장과 모아주기는 공존 가능하다.** Mutex 불필요.

```
모아주기 ON + 기호확장 ON 일 때:

(A) 모아주기로 "고" 입력: / → k
    1. "/" → vowelOnly(ㅗ), symbolState = triggered("/")
    2. "k" → layerKeyMap에 없음 → symbolState = inactive
    3. 정상 한글조합 계속: ㅗ + ㄱ = 고 ✓

(B) 기호 확장: / → / → g
    1. "/" → vowelOnly(ㅗ), symbolState = triggered("/")
    2. "/" → layerKeyMap에 있음 → ㅗ 소급취소, layerSelected("/")
    3. "g" → symbolMap["/"["g"] → 기호 출력 ✓

(C) 겹모음 ㅘ: / → f (모아주기 여부 무관)
    1. "/" → vowelOnly(ㅗ), symbolState = triggered("/")
    2. "f" → layerKeyMap에 없음 → symbolState = inactive
    3. 정상 한글조합 계속: ㅗ + ㅏ = ㅘ ✓
```

2회 누름(`//`)은 어떤 모드에서도 정상 한글 조합이 아니므로 모호함이 없다.

## 현재 동작 분석

### 신세벌식 — j → k 입력 시

1. `j` 입력 → 초성.이응(ㅇ) → 상태: `.initialConsonant`
2. `k` 입력 → `handleInitialConsonantChosung` → `pickChosung(by: "jk")` → nil (겹자음 아님)
3. **현재**: `.commit("ㅇ", nextBuffer: [ㄱ])` — ㅇ 커밋, ㄱ 새 조합
4. **기호확장**: ㅇ 소급취소, 기호 모드 진입

### 공세벌식 — / → / 입력 시

1. `/` 입력 → 중성.오(ㅗ) → 상태: `.vowelOnly`
2. `/` 입력 → `handleVowelOnlyJungsung` → `pickJungsung(by: "//")` → nil (겹모음 아님)
3. **현재**: `.commit("ㅗ", nextBuffer: [ㅗ])` — ㅗ 커밋, ㅗ 새 조합
4. **기호확장**: ㅗ 소급취소, 기호 모드 진입

## 설계

### 1. 새로운 LayoutTrait 추가

```swift
enum LayoutTrait: String {
    // ... 기존 trait
    case 기호확장
}
```

### 2. 기호 확장 상태 모델

```swift
enum SymbolExtensionState: Equatable, Sendable {
    /// 비활성 (일반 한글 입력)
    case inactive
    /// 트리거 자소가 입력된 상태 (다음 키 대기)
    /// - 신세벌: ㅇ 입력됨
    /// - 공세벌: /(ㅗ) 또는 9(ㅜ) 입력됨
    case triggered(triggerKey: String)
    /// 단 선택 완료 (기호 키 대기)
    case layerSelected(layerKey: String)
}
```

`triggered`에 `triggerKey`를 포함하여 어떤 키로 진입했는지 기억한다.
`layerSelected`에 `layerKey`를 포함하여 symbolMap에서 직접 조회한다.

### 3. 기호 확장 설정 (SymbolExtensionConfig)

```swift
struct SymbolExtensionConfig: Sendable {
    /// 트리거 키 (rawKey 기준)
    /// 이 키가 입력된 뒤 triggerState에 해당하는 상태가 되면 triggered
    let triggerKeys: Set<String>

    /// 트리거 판정에 필요한 버퍼 상태
    let triggerState: TriggerBufferState

    /// 단 선택 키 집합. triggered 상태에서 이 키가 오면 layerSelected로 전이
    let layerKeys: Set<String>

    /// 기호 맵: [단선택키][기호키] → 기호 문자열
    /// 기호키에 Shift가 적용되면 대문자로 구분 (예: "g" vs "G")
    let symbolMap: [String: [String: String]]
}

enum TriggerBufferState: Sendable {
    /// 초성 단독 상태 (신세벌: ㅇ만 있는 상태)
    case initialConsonant
    /// 중성 단독 상태 (공세벌: ㅗ 또는 ㅜ만 있는 상태)
    case vowelOnly
}
```

### 4. 자판별 설정 예시

```swift
// 신세벌식 P2
let config = SymbolExtensionConfig(
    triggerKeys: ["j"],              // ㅇ
    triggerState: .initialConsonant,
    layerKeys: ["k", "l", ";"],     // ㄱ, ㅈ, ㅂ (단 선택 = 2번째 키)
    symbolMap: [
        "k": ["g": "…", "G": "♣", /* ... */],  // 1단(소문자) + 4단(대문자)
        "l": [/* 2단 + 5단 */],
        ";": [/* 3단 + 6단 */],
    ]
)

// 공세벌식 P3
let config = SymbolExtensionConfig(
    triggerKeys: ["/", "9"],         // 오른쪽 ㅗ, 오른쪽 ㅜ
    triggerState: .vowelOnly,
    layerKeys: ["/", "9"],           // 같은 키 2회 = 단 선택 (2번째 키)
    symbolMap: [
        "/": ["f": "·", "F": "♠", /* ... */],  // 1단(소문자) + 3단(대문자)
        "9": [/* 2단 + 4단 */],
    ]
)
```

### 5. 프로토콜 확장

```swift
protocol HangulAutomata {
    // ... 기존 프로토콜
    var symbolExtensionConfig: SymbolExtensionConfig? { get }
}

extension HangulAutomata {
    // 기본 구현: 기호 확장 미지원
    var symbolExtensionConfig: SymbolExtensionConfig? { nil }
}
```

`기호확장` trait이 켜져 있을 때만 config를 반환하는 computed property로 구현 가능:

```swift
var symbolExtensionConfig: SymbolExtensionConfig? {
    guard traits.contains(.기호확장) else { return nil }
    return _symbolExtensionConfig  // 레이아웃별 상수
}
```

### 6. 처리 위치: HangulProcessor 레벨

기호 확장은 **CompositionStateMachine 밖, HangulProcessor 레벨**에서 처리한다.

- 상태머신은 한글 자소 조합에 집중 (단일 책임)
- 기호 확장은 한글 조합을 **대체**하는 것이므로 상위 레벨에서 가로챔
- 트리거 자소는 한글로도 유효하므로, 다음 키에 따라 소급 취소 필요

```swift
// HangulProcessor에 추가
private var symbolState: SymbolExtensionState = .inactive
```

### 7. 입력 처리 플로우 (통합)

신세벌과 공세벌 모두 동일한 플로우를 탄다.

```
KeyEvent 수신 (PatalInputController.inputText)
  │
  ├─ config == nil → 기존 로직 그대로
  │
  └─ config != nil
      │
      ├─ symbolState == .inactive
      │    └─ 기존 한글조합() 호출
      │       조합 후 트리거 조건 충족 시 → symbolState = .triggered(triggerKey)
      │       (조건: rawKey ∈ triggerKeys AND buffer.state == triggerState)
      │
      ├─ symbolState == .triggered(triggerKey)
      │    ├─ rawKey ∈ layerKeys?
      │    │    → 상태머신 버퍼 리셋 (트리거 자소 소급취소)
      │    │    → setMarkedText("") (preedit 해제)
      │    │    → symbolState = .layerSelected(layerKey: rawKey)
      │    │    → true 반환 (키 소비)
      │    │
      │    └─ rawKey ∉ layerKeys?
      │         → symbolState = .inactive
      │         → 기존 한글조합() 호출 (트리거 자소는 이미 버퍼에 있으므로 정상 진행)
      │
      └─ symbolState == .layerSelected(layerKey)
           ├─ symbolMap[layerKey][rawKey] 에 기호가 있음?
           │    → 기호 문자열을 insertText로 출력
           │    → symbolState = .inactive
           │    → true 반환
           │
           ├─ 백스페이스?
           │    → 상태머신에 트리거 자소 재입력 (triggered로 복원)
           │    → symbolState = .triggered(triggerKey)
           │    → true 반환
           │
           └─ 매핑 없는 키?
                → symbolState = .inactive
                → 키를 일반 처리로 전달 (한글 조합 또는 OS 처리)
```

### 8. 소급 취소 (Retroactive Cancel)

트리거 자소가 이미 상태머신에 들어간 상태에서 기호 모드 진입이 확정되면 취소한다.

```swift
mutating func enterSymbolMode(layerKey: String, triggerKey: String) {
    stateMachine.reset()  // 트리거 자소 제거
    symbolState = .layerSelected(layerKey: layerKey)
}
```

`stateMachine.reset()`은 새로 추가:

```swift
// CompositionStateMachine
mutating func reset() {
    buffer = .empty
}
```

신세벌: 초성ㅇ만 있는 상태 → reset()으로 완전 초기화.
공세벌: 중성ㅗ/ㅜ만 있는 상태 → reset()으로 완전 초기화.

두 경우 모두 버퍼에 트리거 자소 하나만 있으므로 reset()이면 충분하다.

### 9. 백스페이스 처리

```
상태별 백스페이스:
  layerSelected(layerKey) → triggered(triggerKey) 복귀
  triggered(triggerKey)   → inactive (기존 백스페이스 위임)
  inactive                → 기존 백스페이스 로직
```

```swift
func backspaceInSymbolMode() -> Bool {
    switch symbolState {
    case .layerSelected(let layerKey):
        // triggered로 복귀: 트리거 자소를 상태머신에 재입력
        guard let config = hangulLayout.symbolExtensionConfig else {
            symbolState = .inactive
            return false
        }
        // layerKey → triggerKey 역추적
        // 신세벌: 항상 "j", 공세벌: layerKey == triggerKey (같은 키 2회이므로)
        let triggerKey = config.triggerKeys.first(where: { _ in true }) ?? layerKey
        stateMachine.reset()
        _ = stateMachine.processInput(triggerKey)
        symbolState = .triggered(triggerKey: triggerKey)
        return true  // 백스페이스 소비

    case .triggered:
        symbolState = .inactive
        return false  // 기존 백스페이스 로직에 위임

    case .inactive:
        return false
    }
}
```

### 10. 리셋 조건

symbolState를 `.inactive`로 리셋해야 하는 모든 경로:

- `commitComposition` 호출 (자판 전환, 마우스 클릭 등)
- `flushCommit` 호출 (스페이스, 엔터, 비한글 키)
- triggered 상태에서 layerKey가 아닌 키 입력
- layerSelected 상태에서 symbolMap에 없는 키 입력

```swift
// HangulProcessor
func resetSymbolState() {
    symbolState = .inactive
}

// 기존 flushCommit()에 추가
func flushCommit() -> [String] {
    resetSymbolState()
    // ... 기존 로직
}
```

### 11. 자판별 적용 범위

| 자판 | 기호 확장 | 트리거 | 단 선택 | 총 단수 | 모아주기 공존 |
|------|---------|-------|--------|---------|------------|
| 신세벌 P2 | O | j(ㅇ) | k, l, ; | 6단 (3×Shift) | 해당 없음 |
| 신세벌 PCS | O | j(ㅇ) | k, l, ; | 6단 (3×Shift) | 해당 없음 |
| 공세벌 P3 | O | /, 9 | / (=트리거), 9 (=트리거) | 4단 (2×Shift) | **공존 가능** |

### 12. 구현 단계

#### Phase 1: 기본 인프라
1. `LayoutTrait.기호확장` 추가
2. `SymbolExtensionState`, `SymbolExtensionConfig`, `TriggerBufferState` 정의
3. `HangulAutomata` 프로토콜에 `symbolExtensionConfig` 추가 (기본 = nil)
4. `CompositionStateMachine.reset()` 추가
5. `HangulProcessor`에 `symbolState` 관리 로직 추가

#### Phase 2: 입력 흐름 연결
6. `PatalInputController.inputText`에서 기호 확장 분기 처리
7. 트리거 감지 → 단 선택 → 기호 확정 플로우 구현
8. 백스페이스 처리
9. 리셋 경로 (flush, commit, 앱 전환) 처리

#### Phase 3: 기호 맵 데이터
10. 신세벌 P2 기호 확장 맵 정의
11. 공세벌 P3 기호 확장 맵 정의
12. 신세벌 PCS 기호 맵 정의 (필요 시)

#### Phase 4: 테스트
13. 트리거 감지 테스트 (신세벌: ㅇ 단독, 공세벌: ㅗ/ㅜ 단독)
14. 기호 출력 테스트 (각 단별)
15. 폴백 테스트 (트리거 후 비기호 키 → 정상 한글 조합 계속)
16. 모아주기+기호확장 동시 테스트 (공세벌 P3)
17. 백스페이스 테스트 (layerSelected → triggered → inactive)
18. 리셋 테스트 (flush, commit 시 symbolState 초기화)
19. 기호확장 trait OFF 시 기존 동작 유지 확인

### 13. 주의사항

- **성능**: `symbolState == .inactive && config == nil`이면 즉시 기존 경로. 추가 분기 최소화.
- **기존 동작 보존**: `기호확장` trait OFF 또는 config == nil이면 현재 동작과 100% 동일.
- **ㅇ + 모음 (신세벌)**: triggered 상태에서 모음이 오면 → inactive로 전환, 정상 한글조합 계속. ㅇ은 이미 버퍼에 있으므로 ㅇ+ㅏ=아 등이 자연스럽게 진행.
- **좌/우 ㅗ·ㅜ 구분 (공세벌)**: `v`(왼쪽 ㅗ)와 `b`(왼쪽 ㅜ)는 triggerKeys에 포함되지 않으므로 기호확장을 발동하지 않는다. KeyCodeMapper가 물리 키코드 기반으로 두 키를 구분한다.
- **초성 뒤 `/` (공세벌)**: `ㄱ` + `/` = `고`는 정상 한글. 이때 buffer.state == `.consonantVowel`이므로 triggerState(`.vowelOnly`)와 불일치 → triggered 되지 않음.
- **앱 전환/flush**: `commitComposition`, `flushCommit`, 스페이스, 엔터 등 모든 flush 경로에서 `resetSymbolState()` 호출.
- **기호 맵 데이터**: pat.im 배열표가 이미지 기반이므로, 날개셋 ist 파일이나 온라인 입력기 소스에서 매핑 데이터 추출 필요.
