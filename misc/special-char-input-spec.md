# 기호 확장 배열 구현 스펙

## 개요

세벌식 한글 상태에서 조합할 수 없는 키 조합을 기호 입력 트리거로 사용한다.
자판마다 트리거 메커니즘이 다르며, 트리거 후 단(layer)을 선택하고 기호 키를 눌러 특수 문자를 확정하는 다단 입력 방식이다.

### 신세벌식 P2/PCS — 초성 충돌 트리거

첫소리 ㅇ(j)을 먼저 누르고, ㄱ(k)/ㅈ(l)/ㅂ(;) 중 하나를 눌러 기호 단을 선택한 뒤, 세 번째 키로 기호를 확정한다.
ㅇ 뒤에 ㄱ/ㅈ/ㅂ은 겹자음이 될 수 없으므로 기호 확장 트리거로 쓸 수 있다.

```
[트리거] → [단 선택] → [기호 키]
   j(ㅇ) →    k(ㄱ)  →   g       = … (말줄임표)
   j(ㅇ) →    l(ㅈ)  →   f       = ♠ (예시)
   j(ㅇ) →    ;(ㅂ)  →   d       = ★ (예시)
```

Shift를 함께 누르면 4~6단으로 확장되어 총 6단 × 키보드 키 수만큼의 기호를 배정할 수 있다.

| 단 | 키 조합 | Shift 여부 |
|----|---------|-----------|
| 1단 | j → k → [키] | 없음 |
| 2단 | j → l → [키] | 없음 |
| 3단 | j → ; → [키] | 없음 |
| 4단 | j → k → Shift+[키] | 있음 |
| 5단 | j → l → Shift+[키] | 있음 |
| 6단 | j → ; → Shift+[키] | 있음 |

### 공세벌식 P3 — 중복 모음 키 트리거

공세벌식은 오른쪽 ㅗ·ㅜ 글쇠가 두 개씩 있는 특징을 이용한다.
- `v`와 `/` 모두 중성.오(ㅗ)에 매핑
- `b`와 `9` 모두 중성.우(ㅜ)에 매핑

중복 키(`/`=오른쪽 ㅗ, `9`=오른쪽 ㅜ)를 한 번 또는 여러 번 눌러 기호 단을 선택한 뒤, 다른 일반 글쇠를 눌러 기호를 넣는다.

```
[전환 글쇠]  → [기호 키]
   /(ㅗ)    →    f(ㅏ)     = · (가운뎃점, 예시)
   9(ㅜ)    →    s(ㄴ받침)  = □ (네모, 예시)
   / → /    →    f         = ♣ (2회 누름 = 2단, 예시)
```

| 단 | 키 조합 | 비고 |
|----|---------|------|
| 1단 | / → [키] | 오른쪽 ㅗ 1회 |
| 2단 | 9 → [키] | 오른쪽 ㅜ 1회 |
| 3단 | / → / → [키] | 오른쪽 ㅗ 2회 |
| 4단 | 9 → 9 → [키] | 오른쪽 ㅜ 2회 |

> 참고: 실제 단 구성은 pat.im 배열표 기준으로 확정 필요

## 현재 동작 분석

### 신세벌식 P2/PCS — j → k 입력 시

1. `j` 입력 → `createEvent` → 초성.이응(ㅇ) → 상태: `.initialConsonant`
2. `k` 입력 → `handleInitialConsonantChosung` → `pickChosung(by: "jk")` → nil (겹자음 아님)
3. **현재**: ㅇ을 커밋하고 ㄱ으로 새 조합 시작
4. **목표**: ㅇ을 커밋하지 않고 기호 확장 모드 진입

### 공세벌식 P3 — 중복 모음 키 입력 시

`/` 키는 중성.오(ㅗ)에 매핑되어 있다. 초성 없이 `/`를 누르면:

1. `/` 입력 → `createEvent` → 중성.오(ㅗ) → 정상 중성 입력으로 처리
2. 이후 일반 키 입력 → 한글 조합 진행

공세벌에서 `/`가 기호 트리거가 되려면, **빈 상태 또는 초성 직후**에 `/`가 눌렸을 때 기호 후보로 감지하고, 다음 키가 기호 맵에 있으면 기호를 출력, 없으면 정상 중성 조합으로 복귀해야 한다.

핵심 차이: 신세벌은 초성+초성(불가능한 조합)이 트리거이고, 공세벌은 중복 모음 키(어느 쪽이든 같은 모음)가 트리거이다.

## 설계

### 1. 새로운 LayoutTrait 추가

```swift
enum LayoutTrait: String {
    // ... 기존 trait
    case 기호확장   // 기호 확장 배열 활성화
}
```

### 2. 기호 확장 상태 모델 (`SymbolExtensionState`)

기호 확장은 한글 조합과 별개의 상태를 가진다. 한글 조합 파이프라인 밖에서 독립적으로 관리한다.
자판별로 트리거 메커니즘은 다르지만, 상태 모델은 통일한다.

```swift
enum SymbolExtensionState: Equatable, Sendable {
    /// 기호 확장 비활성 (일반 한글 입력)
    case inactive
    /// 트리거 입력됨 (다음 키 대기)
    /// - 신세벌: ㅇ이 입력된 상태
    /// - 공세벌: 중복 모음 키(/, 9)가 입력된 상태
    case triggered
    /// 단 선택됨 (기호 키 대기)
    case layerSelected(SymbolLayer)
}

enum SymbolLayer: Equatable, Sendable {
    case layer1  // 신세벌: k, 공세벌: / (1회)
    case layer2  // 신세벌: l, 공세벌: 9 (1회)
    case layer3  // 신세벌: ;, 공세벌: / (2회)
    case layer4  // 공세벌: 9 (2회). 신세벌은 Shift로 4~6단 확장
}
```

### 3. 기호 맵 데이터 구조

각 레이아웃에 기호 맵을 추가한다. 6단 × N키의 2차원 맵이다.

```swift
protocol HangulAutomata {
    // ... 기존 프로토콜

    /// 기호 확장 설정 (nil이면 기호 확장 미지원)
    var symbolExtensionConfig: SymbolExtensionConfig? { get }
}

/// 자판별 기호 확장 설정
struct SymbolExtensionConfig: Sendable {
    /// 트리거 키 (rawKey 기준)
    /// - 신세벌: "j" (초성 ㅇ)
    /// - 공세벌: "/" 또는 "9" (중복 모음 키)
    let triggerKeys: Set<String>

    /// 트리거 감지 조건
    let triggerCondition: TriggerCondition

    /// 단 선택 키 → SymbolLayer 매핑
    let layerKeyMap: [String: SymbolLayer]

    /// 기호 맵: [SymbolLayer][키] → 기호 문자열
    let symbolMap: [SymbolLayer: [String: String]]
}

enum TriggerCondition: Sendable {
    /// 초성 단독 상태에서 특정 초성일 때 (신세벌: ㅇ)
    case initialConsonant(초성)
    /// 중복 모음 키가 입력될 때 (공세벌: /, 9)
    case duplicateVowelKey
}
```

레이아웃별 기호 맵 예시 (신세벌식 P2):

```swift
let symbolExtensionConfig = SymbolExtensionConfig(
    triggerKeys: ["j"],
    triggerCondition: .initialConsonant(.이응),
    layerKeyMap: [
        "k": .layer1, "l": .layer2, ";": .layer3,   // 1~3단
        "K": .layer1, "L": .layer2, ":": .layer3,   // 4~6단 (Shift, 같은 layer에 Shift 구분은 키로)
    ],
    symbolMap: [
        .layer1: [              // j → k → [키]
            "g": "…",          // 말줄임표
            "f": "·",          // 가운뎃점
            // ... 나머지 키 매핑
        ],
        .layer2: [ /* j → l → [키] */ ],
        .layer3: [ /* j → ; → [키] */ ],
    ]
)
```

레이아웃별 기호 맵 예시 (공세벌식 P3):

```swift
let symbolExtensionConfig = SymbolExtensionConfig(
    triggerKeys: ["/", "9"],
    triggerCondition: .duplicateVowelKey,
    layerKeyMap: [
        "/": .layer1,          // 오른쪽 ㅗ 1회
        "9": .layer2,          // 오른쪽 ㅜ 1회
        // 2회 누름은 상태에서 처리 (triggered → 같은 키 → layer3/4)
    ],
    symbolMap: [
        .layer1: [              // / → [키]
            "f": "·",          // 가운뎃점 (예시)
            // ...
        ],
        .layer2: [ /* 9 → [키] */ ],
        .layer3: [ /* / → / → [키] */ ],
        .layer4: [ /* 9 → 9 → [키] */ ],
    ]
)
```

### 4. 처리 위치: HangulProcessor 레벨

기호 확장은 **CompositionStateMachine 밖, HangulProcessor 레벨**에서 처리한다.

이유:
- 상태머신은 한글 자소 조합에 집중해야 한다 (단일 책임)
- 기호 확장은 한글 조합 결과가 아니라 한글 조합을 **대체**하는 것이다
- 트리거(ㅇ)는 한글 초성으로도 유효하므로, 다음 키에 따라 소급 취소가 필요하다

```swift
// HangulProcessor 에 추가
private var symbolState: SymbolExtensionState = .inactive
```

### 5. 입력 처리 플로우

#### 5-A. 신세벌식 (초성 충돌 트리거)

```
KeyEvent 수신 (PatalInputController.inputText)
  │
  ├─ 기호확장 config 없음 → 기존 로직 그대로
  │
  └─ 기호확장 config 있음
      │
      ├─ symbolState == .inactive
      │    └─ 기존 한글조합() 호출
      │       한글조합 결과에서 초성ㅇ 단독 상태 감지 시 → symbolState = .triggered
      │
      ├─ symbolState == .triggered
      │    ├─ 다음 키가 단 선택 키 (k/l/;)?
      │    │    → 조합 중인 ㅇ 취소 (상태머신 버퍼 리셋)
      │    │    → symbolState = .layerSelected(layer)
      │    │    → preedit에 기호 모드 표시 (선택적)
      │    │    → true 반환 (키 소비)
      │    │
      │    └─ 다른 키?
      │         → symbolState = .inactive
      │         → 기존 한글조합() 흐름으로 진행 (ㅇ + 새 키)
      │
      └─ symbolState == .layerSelected(layer)
           ├─ symbolMap[layer][키] 에 기호가 있음?
           │    → 조합 버퍼 초기화
           │    → 기호 문자열을 insertText로 출력
           │    → symbolState = .inactive
           │    → true 반환
           │
           ├─ 백스페이스?
           │    → symbolState = .triggered 로 복귀
           │    → true 반환
           │
           └─ 매핑 없는 키?
                → symbolState = .inactive
                → 기호 모드 탈출, 키를 일반 처리로 전달
```

#### 5-B. 공세벌식 (중복 모음 키 트리거)

공세벌식은 트리거와 단 선택이 하나의 키에 통합되어 있다.
`/`(오른쪽 ㅗ)와 `9`(오른쪽 ㅜ)는 각각 `v`(왼쪽 ㅗ)와 `b`(왼쪽 ㅜ)와 동일한 중성을 생성하므로, 이 키가 **빈 상태 또는 초성 직후**에 입력되면 기호 트리거 후보가 된다.

```
KeyEvent 수신
  │
  ├─ symbolState == .inactive
  │    └─ rawKey가 트리거 키 ("/" 또는 "9")?
  │         ├─ 현재 상태가 빈 상태 또는 초성만 있는 상태?
  │         │    → 기존 한글조합() 호출 (중성 입력으로 정상 처리)
  │         │    → symbolState = .triggered
  │         │    → 트리거 키 기억 (triggeredKey = rawKey)
  │         │
  │         └─ 그 외 → 기존 한글조합()만 호출
  │
  ├─ symbolState == .triggered
  │    ├─ 같은 트리거 키 재입력 ("/→/" 또는 "9→9")?
  │    │    → 현재 모음 조합 취소 (소급 취소)
  │    │    → symbolState = .layerSelected(2회 단)
  │    │
  │    ├─ symbolMap[layer1 or layer2][rawKey]에 기호가 있음?
  │    │    → 현재 모음 조합 취소 (소급 취소)
  │    │    → 기호 출력
  │    │    → symbolState = .inactive
  │    │
  │    └─ 기호 맵에 없음?
  │         → symbolState = .inactive
  │         → 기존 한글조합() 흐름 계속 (이미 입력된 모음은 유지)
  │
  └─ symbolState == .layerSelected(layer)
       └─ (신세벌과 동일한 처리)
```

핵심 차이점:
- 신세벌: 트리거(ㅇ)와 단 선택(ㄱ/ㅈ/ㅂ)이 별개의 키
- 공세벌: 트리거 키 자체가 단 선택 역할 (`/`=1단, `9`=2단, `//`=3단, `99`=4단)
- 공세벌에서 소급 취소 시 모음(ㅗ/ㅜ)이 이미 조합에 들어갔으므로, 초성+중성 상태에서 중성을 제거하거나 중성 단독 상태를 해제해야 한다

### 6. 트리거 감지 조건

#### 신세벌식

ㅇ이 초성 단독으로 존재할 때만 기호 확장 후보가 된다.

```swift
/// HangulProcessor 내부
private func checkSymbolTrigger() {
    guard let config = hangulLayout.symbolExtensionConfig else { return }

    switch config.triggerCondition {
    case .initialConsonant(let targetChosung):
        let preedit = stateMachine.buffer
        if preedit.state == .initialConsonant
           && preedit.chosung == targetChosung
        {
            symbolState = .triggered
        }
    case .duplicateVowelKey:
        // 공세벌은 키 입력 시점에서 직접 감지 (rawKey 기반)
        break
    }
}
```

이 체크는 `한글조합()` 결과가 `.composing`일 때 수행한다.

#### 공세벌식

rawKey가 트리거 키 집합에 포함되는지 직접 확인한다.

```swift
private func checkDuplicateVowelTrigger(rawKey: String) {
    guard let config = hangulLayout.symbolExtensionConfig,
          case .duplicateVowelKey = config.triggerCondition,
          config.triggerKeys.contains(rawKey)
    else { return }

    // 빈 상태이거나 초성만 있는 상태에서 중복 모음 키가 입력됨
    let state = stateMachine.buffer.state
    if state == .empty || state == .initialConsonant {
        symbolState = .triggered
        triggeredKey = rawKey  // 어떤 트리거 키인지 기억
    }
}
```

### 7. 소급 취소 (Retroactive Cancel)

트리거 후 기호 확장이 확정되면, 이미 상태머신에 들어간 자소를 취소해야 한다.

#### 신세벌식

상태머신에 들어간 초성 ㅇ을 제거한다.

```swift
func enterSymbolMode(layer: SymbolLayer) {
    stateMachine.reset()  // ㅇ 제거
    symbolState = .layerSelected(layer)
}
```

#### 공세벌식

상태머신에 들어간 중성(ㅗ 또는 ㅜ)을 제거한다.
상황에 따라 두 가지 경우가 있다:

1. **빈 상태에서 트리거** → 중성만 있는 상태 → `reset()`으로 전체 초기화
2. **초성 있는 상태에서 트리거** → 초성+중성 상태 → 중성만 제거하고 초성 유지

```swift
func enterSymbolModeForVowelTrigger(layer: SymbolLayer) {
    if stateMachine.buffer.state == .consonantVowel {
        // 초성은 유지하고 중성만 제거 → 초성을 커밋하고 기호 모드 진입
        let committed = composeString(from: buffer with chosung only)
        stateMachine.reset()
        // committed가 있으면 insertText로 출력
    } else {
        stateMachine.reset()  // 모음만 있었으면 전체 초기화
    }
    symbolState = .layerSelected(layer)
}
```

`stateMachine.reset()`은 기존에 없으므로 추가해야 한다:

```swift
// CompositionStateMachine
mutating func reset() {
    buffer = .empty
}
```

### 8. Preedit 표시 (선택적)

기호 확장 모드 진입 시 사용자에게 시각적 피드백을 줄 수 있다.

- `triggered` 상태: ㅇ이 preedit에 보이는 것은 현재 동작과 동일
- `layerSelected` 상태: preedit을 비우거나 "기호" 같은 힌트 표시 (선택적)
- 기호 확정 후: preedit 해제, insertText로 기호 출력

시각적 피드백은 첫 구현에서는 생략하고, 기호 확정 시 바로 출력하는 것만 구현해도 무방하다.

### 9. 백스페이스 처리

```
상태별 백스페이스 동작:
- layerSelected → triggered (단 선택 취소, ㅇ 복원)
- triggered → inactive (ㅇ도 삭제, 상태머신에 위임)
- inactive → 기존 백스페이스 로직
```

`layerSelected`에서 백스페이스 시 ㅇ을 다시 상태머신에 넣어 preedit을 복원한다:

```swift
func backspaceInSymbolMode() {
    switch symbolState {
    case .layerSelected:
        // ㅇ 복원
        stateMachine.reset()
        _ = stateMachine.processInput("j")  // ㅇ 재입력
        symbolState = .triggered
    case .triggered:
        symbolState = .inactive
        // 기존 백스페이스 로직 위임
    case .inactive:
        break  // 기존 로직
    }
}
```

### 10. Trait 상호배제 (Mutex)

기호확장 트리거 키가 다른 trait의 키와 겹치는 경우, 두 trait을 동시에 활성화할 수 없다.

#### 충돌 분석

| 자판 | 기호확장 트리거 | 모아주기와 충돌 | 이유 |
|------|--------------|--------------|------|
| 신세벌 P2 | j(ㅇ) + 초성 | **충돌 없음** | ㅇ+ㄱ 등은 모아주기 여부와 무관하게 불가능한 겹자음 |
| 신세벌 PCS | j(ㅇ) + 초성 | **충돌 없음** | 동일 |
| 공세벌 P3 | /(ㅗ), 9(ㅜ) | **충돌** | 모아주기에서 `/`는 중성 단독 입력(vowelOnly)의 시작. 기호확장에서는 트리거. 다음 키가 올 때까지 의도 구분 불가 |

공세벌 P3에서의 구체적 충돌 시나리오:

```
모아주기 ON + 기호확장 ON 일 때:

사용자가 "/" 입력
  ├─ 모아주기 해석: vowelOnly(ㅗ) 상태 → 다음에 초성/종성을 눌러 음절 완성
  └─ 기호확장 해석: triggered 상태 → 다음 키로 기호 출력

사용자가 "/" → "k" 입력
  ├─ 모아주기 해석: ㅗ + ㄱ(초성) → 고 (consonantVowel)
  └─ 기호확장 해석: / + k → 기호 맵에서 기호 출력

→ 동일한 키 시퀀스에 두 가지 해석이 존재하므로 공존 불가
```

#### 상호배제 규칙

```swift
/// Trait 간 상호배제 규칙
/// 하나를 켜면 충돌하는 trait은 자동으로 꺼진다
let traitMutexRules: [(LayoutTrait, LayoutTrait)] = [
    (.기호확장, .모아주기),   // 공세벌 P3에서 충돌
]
```

적용 조건: 상호배제는 **실제로 충돌이 발생하는 자판에서만** 적용한다.

| 자판 | 기호확장 ↔ 모아주기 상호배제 |
|------|-------------------------|
| 공세벌 P3 | **적용** (중복 모음 키 트리거이므로) |
| 신세벌 P2 | 미적용 (모아주기 trait 자체가 없음) |
| 신세벌 PCS | 미적용 (모아주기 trait 자체가 없음) |

#### 구현

`toggleLayoutTrait`에서 trait을 켤 때 mutex 규칙을 확인한다:

```swift
/// 자판별 상호배제 규칙: 트리거 메커니즘이 충돌하는 trait 쌍
/// 자판의 availableTraits에 두 trait이 모두 있을 때만 적용
let traitMutexPairs: [(LayoutTrait, LayoutTrait)] = [
    (.기호확장, .모아주기),
]

func toggleLayoutTrait(
    trait: LayoutTrait, for menuItem: NSMenuItem, in layout: inout HangulAutomata
) -> String {
    if layout.traits.contains(trait) {
        // 끄기: 그냥 제거
        layout.traits.remove(trait)
        menuItem.state = .off
    } else {
        // 켜기: 상호배제 trait 확인 후 끄기
        for (a, b) in traitMutexPairs {
            if trait == a && layout.traits.contains(b)
               && layout.availableTraits.contains(a)
               && layout.availableTraits.contains(b)
            {
                layout.traits.remove(b)
                // 해당 메뉴 아이템도 off로 변경 필요
            }
            if trait == b && layout.traits.contains(a)
               && layout.availableTraits.contains(a)
               && layout.availableTraits.contains(b)
            {
                layout.traits.remove(a)
            }
        }
        layout.traits.insert(trait)
        menuItem.state = .on
    }
    // ...
}
```

> 참고: 신세벌 P2/PCS는 `availableTraits`에 `모아주기`가 없으므로 mutex 규칙이 자동으로 무시된다. 공세벌 P3에 `기호확장`을 추가하면 `availableTraits`에 `모아주기`와 `기호확장`이 모두 존재하게 되어 mutex가 발동한다.

### 11. 자판별 적용 범위

| 자판 | 기호 확장 지원 | 트리거 메커니즘 | 트리거 키 | 단 선택 키 | 모아주기와 공존 |
|------|-------------|--------------|----------|----------|-------------|
| 신세벌 P2 | O | 초성 충돌 | j (ㅇ) | k(ㄱ), l(ㅈ), ;(ㅂ) | 해당 없음 |
| 신세벌 PCS | O | 초성 충돌 | j (ㅇ) | k(ㄱ), l(ㅈ), ;(ㅂ) | 해당 없음 |
| 공세벌 P3 | O | 중복 모음 키 | / (오른쪽 ㅗ), 9 (오른쪽 ㅜ) | 트리거 키와 동일 | **불가 (mutex)** |

각 자판의 `symbolExtensionConfig`이 nil이면 기호 확장이 비활성화된다.

### 12. 구현 단계

#### Phase 1: 기본 인프라
1. `LayoutTrait.기호확장` 추가
2. Trait 상호배제 로직 구현 (`toggleLayoutTrait`에서 mutex 처리)
3. `SymbolExtensionState` enum 정의
4. `HangulAutomata` 프로토콜에 기호 맵 관련 인터페이스 추가 (기본 구현 = 빈 맵)
5. `CompositionStateMachine.reset()` 추가
6. `HangulProcessor`에 `symbolState` 관리 로직 추가

#### Phase 2: 입력 흐름 연결
7. `PatalInputController.inputText`에서 기호 확장 분기 처리
8. 트리거 감지 → 단 선택 → 기호 확정 플로우 구현
9. 백스페이스 처리

#### Phase 3: 기호 맵 데이터
10. 신세벌 P2 기호 확장 맵 정의 (pat.im 배열표 기반)
11. 공세벌 P3 기호 확장 맵 정의 (pat.im 배열표 기반)
12. 신세벌 PCS 기호 맵 정의 (필요 시)

#### Phase 4: 테스트
13. 신세벌 상태 전이 단위 테스트 (초성 충돌 트리거)
14. 공세벌 상태 전이 단위 테스트 (중복 모음 키 트리거)
15. Trait 상호배제 테스트 (공세벌 P3에서 기호확장 ON → 모아주기 OFF 확인)
16. 기호 출력 통합 테스트
17. 백스페이스 테스트
18. 기호 확장 비활성 시 기존 동작 유지 확인

### 13. 주의사항

- **성능**: 기호 확장 체크는 모든 키 입력에서 발생하므로 최소한의 분기로 처리해야 한다. `symbolState == .inactive && config == nil`이면 즉시 기존 경로로 진행.
- **기존 동작 보존**: `symbolExtensionConfig`이 nil이면 현재 동작과 100% 동일해야 한다.
- **ㅇ + 모음 시퀀스 (신세벌)**: ㅇ 뒤에 모음이 오면 (예: 아, 어) 기호 확장이 아닌 정상 한글 조합이다. triggered 상태에서 모음이 오면 즉시 inactive로 전환하고 정상 조합을 진행해야 한다.
- **ㅇㅇ (쌍이응, 신세벌)**: 신세벌 P2 chosungMap에 "jj"는 없으므로 현재도 ㅇ 커밋 + ㅇ 새 조합으로 처리된다. 기호 확장에서 j는 단 선택 키가 아니므로 영향 없다.
- **겹모음과의 충돌 (공세벌)**: `/f`는 중성.와(ㅘ), `/e`는 중성.왜(ㅙ), `/d`는 중성.외(ㅚ)로 매핑되어 있다. 기호 확장 트리거 후 이 키들이 오면, 기호 맵에 있는지 먼저 확인하고 없으면 겹모음 조합으로 폴백해야 한다. 단, `/` 뒤에 `f`/`e`/`d`가 오는 것은 이미 한글 겹모음이므로 기호 맵에서 이 키를 제외하거나, 기호 트리거 발동 조건을 더 엄격하게 제한해야 한다.
- **초성 후 중복 모음 키 (공세벌)**: `ㄱ` + `/` = `고`(가+ㅗ)는 정상 한글 조합이다. 기호 트리거와 구별하려면, 공세벌에서는 `/`가 기호 트리거가 되는 조건을 **빈 상태에서만** 또는 **특정 초성 조건**으로 제한하는 것이 안전할 수 있다. 이 부분은 pat.im 원본 동작을 추가 확인해야 한다.
- **앱 전환**: `commitComposition` 호출 시 symbolState도 `.inactive`로 리셋해야 한다.
- **기호 맵 데이터**: pat.im의 배열표가 이미지로만 제공되어 텍스트 추출이 불가하다. 날개셋 ist 파일이나 온라인 한글 입력기 소스에서 매핑 데이터를 추출하는 것을 검토해야 한다.
