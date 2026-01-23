# macOS 입력기 앱별 자판 불일치 문제 원인 분석 및 해결

## 문제 현상
사용자가 "신세벌 PCS" 자판을 선택했음에도 불구하고, 오랫동안 사용하지 않던 앱에서 한글 입력 시 다른 자판으로 동작함.

## 원인 분석

- https://www.logcg.com/en/archives/3563.html와
- https://developer.apple.com/documentation/inputmethodkit/imkinputcontroller에 따르면:

### 핵심 원인: `activateServer()`에서 자판 재확인 누락

**IMKInputController 라이프사이클:**
1. `init()` - 앱이 **최초로** 입력기를 사용할 때 **한 번만** 호출
2. `activateServer()` - 앱이 포커스를 받을 때 **매번** 호출
3. `deactivateServer()` - 앱이 포커스를 잃을 때 호출

**문제 시나리오:**
```
1. 앱 A에서 "신세벌 P2" 자판 사용 → InputController 생성 (layoutName = HAN3_SHIN_P2)
2. 사용자가 시스템에서 "신세벌 PCS"로 자판 변경
3. 앱 B 사용 (한글 입력 없음)
4. 다시 앱 A로 돌아옴
5. activateServer() 호출되지만 자판 재확인 안 함
6. → 앱 A는 여전히 "신세벌 P2"로 동작 (의도치 않은 자판!)
```

### 코드상 문제점

**1. `activateServer()`가 로깅만 수행** (`InputController.swift:51-54`)
```swift
override open func activateServer(_ sender: Any!) {
    super.activateServer(sender)
    logger.debug("입력기 서버 시작: \(layoutName)")  // 자판 재확인 없음
}
```

**2. `layoutName`이 `let`으로 선언됨** (`InputController.swift:16`)
```swift
internal let layoutName: LayoutName  // 변경 불가능
```

**3. `processor`도 `let`으로 선언됨** (`InputController.swift:19`)
```swift
let processor: HangulProcessor  // 변경 불가능
```

## 해결 방안

### 수정 파일 목록
1. `/Users/dp/Repository/PatInputMethod/macOS/Patal/InputController.swift`
2. `/Users/dp/Repository/PatInputMethod/macOS/Patal/HangulProcessor.swift` (선택적)

### 구현 단계

#### 1단계: `layoutName`을 `var`로 변경
```swift
internal var layoutName: LayoutName
```

#### 2단계: `processor`를 `var`로 변경하거나 레이아웃 교체 메서드 추가
```swift
var processor: HangulProcessor
```

#### 3단계: `activateServer()`에서 자판 재확인 로직 추가
```swift
override open func activateServer(_ sender: Any!) {
    super.activateServer(sender)

    if let inputMethodID = getCurrentInputMethodID() {
        let currentLayout = getInputLayoutID(id: inputMethodID)

        if currentLayout != layoutName {
            logger.debug("자판 변경 감지: \(layoutName) → \(currentLayout)")
            updateLayout(to: currentLayout)
        }
    }

    logger.debug("입력기 서버 시작: \(layoutName)")
}
```

#### 4단계: 레이아웃 업데이트 메서드 구현
```swift
private func updateLayout(to newLayout: LayoutName) {
    // 1. 기존 조합 상태 flush
    let flushed = processor.flushCommit()

    // 2. 새 레이아웃으로 교체
    layoutName = newLayout
    let hangulLayout = createLayoutInstance(name: layoutName)
    processor = HangulProcessor(layout: hangulLayout)

    // 3. 저장된 특성 로드
    let traitKey = buildTraitKey(name: layoutName)
    if let loadedTraits = loadActiveOptions(traitKey: traitKey) {
        processor.hangulLayout.traits = loadedTraits
    } else {
        processor.hangulLayout.traits = processor.hangulLayout.availableTraits
    }

    // 4. 메뉴 업데이트
    optionMenu = OptionMenu(layout: processor.hangulLayout)
}
```

## 검증 방법

1. 입력기 빌드 및 설치
2. 앱 A에서 "신세벌 PCS" 자판으로 한글 입력
3. 시스템 설정에서 다른 Patal 자판 (예: "3벌식 P3")으로 변경
4. 앱 B에서 한글 입력 확인
5. 다시 앱 A로 돌아와서 한글 입력 → 변경된 자판("3벌식 P3")으로 동작하는지 확인
6. Console.app에서 "자판 변경 감지" 로그 확인

## 고려사항

- `optionMenu`도 `var`로 변경 필요 (자판별 옵션이 다름)
- 조합 중 자판 변경 시 기존 조합 문자 처리 필요 (flush)
