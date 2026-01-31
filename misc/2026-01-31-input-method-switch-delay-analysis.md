# 입력기 전환 지연 문제 분석

**분석 일자**: 2026-01-31

## 문제 설명
ABC 레이아웃에서 Patal 한글 입력기로 전환할 때 간헐적으로 지연이 발생함.

---

## 입력기 전환 흐름 분석

```
[사용자] ABC → Patal 입력기 전환
    ↓
[macOS TIS] kTISNotifySelectedKeyboardInputSourceChanged 알림 발생
    ↓
[DistributedNotificationCenter]
    ↓
[AppDelegate.handleInputSourceChanged()]
    → NotificationCenter.post(.inputSourceChanged)
    ↓
[InputController.handleInputSourceChanged()]
    → guard isControllerActivated
    ↓
[syncLayoutIfNeeded()]
    ├── guard !isInstanceSynced
    ├── getCurrentInputMethodID()  ← TIS API 동기 호출
    ├── getInputLayoutID(id:)
    └── if currentLayout != layoutName → updateLayout()
    ↓
[updateLayout(to:)]
    ├── processor.flushCommit()
    ├── createLayoutInstance(name:)  ← 레이아웃 인스턴스 생성
    ├── HangulProcessor(layout:)     ← 상태머신 포함 전체 초기화
    ├── loadActiveOptions(traitKey:) ← UserDefaults 읽기
    └── OptionMenu(layout:)          ← NSMenu 생성
```

---

## 식별된 잠재적 병목 지점

### 1. TIS API 동기 호출 (심각도: 높음)
**위치**: `Util.swift:43-55`

```swift
func getCurrentInputMethodID() -> String? {
    guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
        return nil
    }
    if let inputMethodID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
        return Unmanaged<CFString>.fromOpaque(inputMethodID).takeUnretainedValue() as String
    }
    return nil
}
```

**문제점**:
- Carbon API(TISCopyCurrentKeyboardInputSource)는 메인 스레드에서 동기 실행
- 시스템 상태에 따라 1-15ms 가변성 존재
- 입력기 전환 시 최소 2회 호출됨 (init, syncLayoutIfNeeded)

### 2. 레이아웃 매번 재생성 (심각도: 중간)
**위치**: `InputController.swift:104`

```swift
let hangulLayout = createLayoutInstance(name: layoutName)
processor = HangulProcessor(layout: hangulLayout)
```

**문제점**:
- 전환 시마다 새 레이아웃 인스턴스 생성
- 레이아웃 내 대규모 딕셔너리 초기화 비용
- 캐싱 메커니즘 없음

### 3. UserDefaults.synchronize() (심각도: 중간)
**위치**: `Util.swift:32`

```swift
func keepUserTraits(traitKey: String, traitValue: String) {
    UserDefaults.standard.set(traitValue, forKey: traitKey)
    UserDefaults.standard.synchronize()  // ← deprecated API
}
```

**문제점**:
- `synchronize()`는 iOS 8/macOS 10.10부터 deprecated
- 불필요한 동기 디스크 I/O 유발
- 현대 macOS에서는 자동 백그라운드 저장됨

### 4. HangulProcessor 전체 초기화 (심각도: 중간)
**위치**: `InputController.swift:105`

```swift
processor = HangulProcessor(layout: hangulLayout)
```

**HangulProcessor 초기화 체인**:
- `HangulProcessor.init(layout:)`
- `CompositionStateMachine.init(layout:)` - 복잡한 상태머신 초기화
- 1000+ 라인의 전이 규칙 포함

### 5. OptionMenu 생성 (심각도: 낮음)
**위치**: `InputController.swift:116`

```swift
optionMenu = OptionMenu(layout: processor.hangulLayout)
```

**문제점**:
- NSMenu 및 NSMenuItem 생성 비용
- 매 전환 시 재생성됨

---

## 성능 측정 기준

| 단계 | 정상 범위 | 경고 | 위험 |
|------|-----------|------|------|
| TIS API 호출 | < 5ms | 5-15ms | > 15ms |
| Layout 생성 | < 1ms | 1-5ms | > 5ms |
| HangulProcessor 초기화 | < 2ms | 2-10ms | > 10ms |
| StateMachine 초기화 | < 1ms | 1-3ms | > 3ms |
| UserDefaults 접근 | < 2ms | 2-5ms | > 5ms |
| OptionMenu 생성 | < 3ms | 3-10ms | > 10ms |
| **전체 전환 시간** | < 20ms | 20-50ms | > 50ms |

---

## 최적화 권장 사항

### 즉시 적용 가능
1. **UserDefaults.synchronize() 제거** - deprecated API, 불필요
2. **디버그 로깅으로 병목 지점 확인** - isDebug = true

### 중기 최적화
1. **레이아웃 인스턴스 캐싱** - 싱글톤 또는 풀링
2. **HangulProcessor 재사용** - reset() 메서드 추가로 버퍼만 초기화
3. **OptionMenu 지연 생성** - 실제 메뉴 표시 시점에 생성

### 장기 최적화
1. **TIS API 캐싱** - 마지막 결과 캐시, 변경 시에만 갱신
2. **비동기 초기화** - 무거운 작업을 백그라운드로 분리

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `InputController.swift` | 입력기 생명주기, 전환 로직 |
| `Util.swift` | TIS API, UserDefaults 접근 |
| `Logger.swift` | 로깅 설정 |
| `HangulProcessor.swift` | 한글 처리기, 상태머신 포함 |
| `AppDelegate.swift` | TIS 알림 수신 |

---

## 디버깅 명령어

```bash
# 실시간 로그 스트리밍
log stream --predicate 'subsystem == "com.soomtong.inputmethod"' --level debug

# 특정 시간 범위 로그 조회
log show --predicate 'subsystem == "com.soomtong.inputmethod"' --last 5m
```
