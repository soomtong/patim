# 기호 확장 배열 구현 스펙

## 개요

세벌식 한글 상태에서 조합할 수 없는 초성 연타를 기호 입력 트리거로 사용한다.
신세벌식 P2 기준으로 첫소리 ㅇ(j) 을 먼저 누르고, ㄱ(k)/ㅈ(l)/ㅂ(;) 중 하나를 눌러 기호 단(layer)을 선택한 뒤, 세 번째 키로 기호를 확정하는 3단 입력 방식이다.

```
[트리거] → [단 선택] → [기호 키]
   j     →    k      →   g       = … (말줄임표)
   j     →    l      →   f       = ♠ (예시)
   j     →    ;      →   d       = ★ (예시)
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

## 현재 동작 분석

현재 코드에서 j → k 입력 시:

1. `j` 입력 → `createEvent` → 초성.이응(ㅇ) → 상태: `.initialConsonant`
2. `k` 입력 → `handleInitialConsonantChosung` → `pickChosung(by: "jk")` → nil (겹자음 아님)
3. **현재**: ㅇ을 커밋하고 ㄱ으로 새 조합 시작
4. **목표**: ㅇ을 커밋하지 않고 기호 확장 모드 진입

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

```swift
enum SymbolExtensionState: Equatable, Sendable {
    /// 기호 확장 비활성 (일반 한글 입력)
    case inactive
    /// 트리거 입력됨 (ㅇ이 입력된 상태, 다음 키 대기)
    case triggered
    /// 단 선택됨 (기호 키 대기)
    case layerSelected(SymbolLayer)
}

enum SymbolLayer: Equatable, Sendable {
    case layer1  // k
    case layer2  // l
    case layer3  // ;
}
```

### 3. 기호 맵 데이터 구조

각 레이아웃에 기호 맵을 추가한다. 6단 × N키의 2차원 맵이다.

```swift
protocol HangulAutomata {
    // ... 기존 프로토콜

    /// 기호 확장 맵: [단][키] → 기호 문자열
    /// 단 키: "k", "l", ";" (1~3단), Shift 조합은 키 문자열로 구분
    var symbolExtensionMap: [String: [String: String]] { get }

    /// 기호 확장 트리거 키 (초성 ㅇ에 해당하는 rawKey)
    var symbolTriggerKey: String { get }  // "j"

    /// 기호 확장 단 선택 키 목록
    var symbolLayerKeys: Set<String> { get }  // ["k", "l", ";"]
}
```

레이아웃별 기호 맵 예시 (신세벌식 P2):

```swift
let symbolExtensionMap: [String: [String: String]] = [
    // 1단: j → k → [키]
    "k": [
        "g": "…",     // 말줄임표
        "f": "·",     // 가운뎃점
        // ... 나머지 키 매핑
    ],
    // 2단: j → l → [키]
    "l": [
        "f": "♠",
        // ...
    ],
    // 3단: j → ; → [키]
    ";": [
        // ...
    ],
    // 4단: j → k → Shift+[키]
    "K": [
        // ... Shift 조합은 대문자 키로 구분
    ],
    "L": [:],  // 5단
    ":": [:],  // 6단
]
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

```
KeyEvent 수신 (PatalInputController.inputText)
  │
  ├─ 기호확장 trait 없음 → 기존 로직 그대로
  │
  └─ 기호확장 trait 있음
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
           ├─ symbolExtensionMap[layer][키] 에 기호가 있음?
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

### 6. 트리거 감지 조건

ㅇ이 초성 단독으로 존재할 때만 기호 확장 후보가 된다.

```swift
/// HangulProcessor 내부
private func checkSymbolTrigger() {
    guard hangulLayout.has기호확장 else { return }

    let preedit = stateMachine.buffer
    // 초성만 있고, 그것이 이응(ㅇ)이면 트리거 상태
    if preedit.state == .initialConsonant
       && preedit.chosung == .이응
    {
        symbolState = .triggered
    }
}
```

이 체크는 `한글조합()` 결과가 `.composing`일 때 수행한다.

### 7. 소급 취소 (Retroactive Cancel)

트리거 후 단 선택 키가 들어오면, 이미 상태머신에 들어간 ㅇ을 취소해야 한다.

```swift
/// 기호 확장 모드 진입 시 현재 조합 버퍼 초기화
func enterSymbolMode(layer: SymbolLayer) {
    // 상태머신 버퍼를 비운다 (ㅇ 제거)
    stateMachine.reset()
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

### 10. 자판별 적용 범위

| 자판 | 기호 확장 지원 | 트리거 키 | 비고 |
|------|-------------|----------|------|
| 신세벌 P2 | O | j (ㅇ) | pat.im 기호 확장 배열 |
| 신세벌 PCS | O | j (ㅇ) | 동일 메커니즘 |
| 공세벌 P3 | △ | j (ㅇ) | 별도 기호 맵 필요 시 추가 |

공세벌 P3는 기호 확장 배열이 정의되어 있지 않으면 trait만 추가하지 않으면 된다.

### 11. 구현 단계

#### Phase 1: 기본 인프라
1. `LayoutTrait.기호확장` 추가
2. `SymbolExtensionState` enum 정의
3. `HangulAutomata` 프로토콜에 기호 맵 관련 인터페이스 추가 (기본 구현 = 빈 맵)
4. `CompositionStateMachine.reset()` 추가
5. `HangulProcessor`에 `symbolState` 관리 로직 추가

#### Phase 2: 입력 흐름 연결
6. `PatalInputController.inputText`에서 기호 확장 분기 처리
7. 트리거 감지 → 단 선택 → 기호 확정 플로우 구현
8. 백스페이스 처리

#### Phase 3: 기호 맵 데이터
9. 신세벌 P2 기호 확장 맵 정의 (pat.im 배열표 기반)
10. 신세벌 PCS 기호 맵 정의 (필요 시)

#### Phase 4: 테스트
11. 상태 전이 단위 테스트
12. 기호 출력 통합 테스트
13. 백스페이스 테스트
14. 기호 확장 비활성 시 기존 동작 유지 확인

### 12. 주의사항

- **성능**: 기호 확장 체크는 모든 키 입력에서 발생하므로 최소한의 분기로 처리해야 한다. `symbolState == .inactive && !has기호확장`이면 즉시 기존 경로로 진행.
- **기존 동작 보존**: 기호확장 trait이 꺼져 있으면 현재 동작과 100% 동일해야 한다.
- **ㅇ + 모음 시퀀스**: ㅇ 뒤에 모음이 오면 (예: 아, 어) 기호 확장이 아닌 정상 한글 조합이다. triggered 상태에서 모음이 오면 즉시 inactive로 전환하고 정상 조합을 진행해야 한다.
- **ㅇㅇ (쌍이응)**: 신세벌 P2 chosungMap에 "jj"는 없으므로 현재도 ㅇ 커밋 + ㅇ 새 조합으로 처리된다. 기호 확장에서 j는 단 선택 키가 아니므로 영향 없다.
- **앱 전환**: `commitComposition` 호출 시 symbolState도 `.inactive`로 리셋해야 한다.
