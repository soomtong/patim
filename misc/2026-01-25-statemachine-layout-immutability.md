# StateMachine Layout 불변성 개선

**날짜**: 2026-01-25
**관련 파일**: `CompositionStateMachine.swift`, `HangulProcessor.swift`

## 배경

`HangulProcessor.swift:181`에서 매 입력마다 StateMachine의 layout을 직접 할당하고 있었음:

```swift
private func 한글조합StateMachine() -> CommitState {
    stateMachine.layout = hangulLayout  // 문제의 코드
    let result = stateMachine.processInput(rawChar)
    ...
}
```

## 문제점

1. **값 복사 오버헤드**: `HangulAutomata`는 struct 기반이므로 매번 값 복사 발생
2. **캡슐화 위반**: StateMachine 내부 상태를 외부에서 직접 수정
3. **일관성 위험**: 상태 전이 중 layout이 바뀌면 예측 불가능한 동작
4. **traits 동기화 복잡성**: `HangulProcessor.hangulLayout`과 `stateMachine.layout` 두 곳에서 layout을 관리하여 불일치 가능

## 해결 방안

### 핵심 아이디어

- `CompositionStateMachine.layout`을 불변(`let`)으로 만들어 외부 수정 차단
- `HangulProcessor.hangulLayout` 변경 시 `didSet`으로 StateMachine 재생성
- 버퍼 상태 보존으로 조합 중 traits 변경에도 안정적으로 동작

### 변경 내용

#### 1. CompositionStateMachine.swift

```swift
// 변경 전
var layout: HangulAutomata

// 변경 후
let layout: HangulAutomata
```

#### 2. HangulProcessor.swift

```swift
// 변경 전
var hangulLayout: HangulAutomata

// 변경 후
var hangulLayout: HangulAutomata {
    didSet {
        recreateStateMachinePreservingBuffer()
    }
}

/// traits 변경 시 StateMachine을 재생성하면서 버퍼 상태 보존
private func recreateStateMachinePreservingBuffer() {
    let savedBuffer = stateMachine.buffer
    stateMachine = CompositionStateMachine(layout: hangulLayout)
    stateMachine.setBuffer(savedBuffer)
}
```

#### 3. 한글조합StateMachine()

```swift
// 변경 전
private func 한글조합StateMachine() -> CommitState {
    stateMachine.layout = hangulLayout
    let result = stateMachine.processInput(rawChar)
    ...
}

// 변경 후
private func 한글조합StateMachine() -> CommitState {
    // layout은 hangulLayout didSet에서 자동 동기화됨
    let result = stateMachine.processInput(rawChar)
    ...
}
```

## 동작 방식

### 기존 방식
- 매 입력마다 `stateMachine.layout = hangulLayout` 실행
- 불필요한 값 복사 + 캡슐화 위반

### 개선된 방식
- `hangulLayout` 프로퍼티 변경 시에만 `didSet` 트리거
- StateMachine 재생성하면서 버퍼 상태 보존
- 매 입력마다 할당 없음

### Swift 초기화 특성
- `init` 내에서 프로퍼티 할당은 `didSet`을 트리거하지 않음
- 따라서 초기화 시에는 정상 동작, 이후 변경 시에만 재생성

## 호환성

| 기존 코드 | 영향 |
|-----------|------|
| `InputController.updateLayout()` | 새 processor 생성 → 변경 불필요 |
| `PatalInputController.changeLayoutOption()` | `processor.hangulLayout.traits` 수정 시 `didSet` 트리거 → 자동 동기화 |
| 테스트 코드 | StateMachine 생성 시 layout 전달 → 기존 패턴 유지 |

## 검증 결과

- 기존 테스트 221개 전체 통과
- traits 변경 시나리오 정상 동작
