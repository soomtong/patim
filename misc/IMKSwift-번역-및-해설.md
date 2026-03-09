# IMKSwift 번역 및 해설

> 원문: [IMKSwift README.md](https://github.com/vChewing/IMKSwift/blob/main/README.md)

---

# 1. 번역문 (Translation)

## IMKSwift

Swift 6 이상을 위한 현대화된 **InputMethodKit** 오버레이로, macOS에서 입력기 엔진을 구축하기 위한 안전하고 동시성을 지원하며 타입 안전한 API를 제공합니다.

### 개요

IMKSwift는 [vChewing 프로젝트](https://github.com/vChewing)의 일부이며, Apple의 InputMethodKit 프레임워크를 대체하는 Swift 네이티브 솔루션을 제공합니다. Objective-C 상호운용성과 Swift 6의 엄격한 동시성(Strict Concurrency) 모델을 결합하여, 현대 Swift 코드에서 더 쉽게 작업할 수 있는 `@MainActor` 격리 API를 제공합니다.

InputMethodKit은 macOS 10.5 Leopard 시절부터 존재했으며, ARC, 샌드박싱(Sandboxing), Swift 자체보다도 이전에 만들어진 것입니다. 두 세대에 걸친 기술 전환을 아우르는 레거시 프레임워크입니다. IMKSwift는 이 격차를 해소하여, 현대 Swift 개발자가 오래된 Objective-C 패턴과 씨름하지 않고도 입력기를 구축할 수 있게 합니다.

안전하지 않은 캐스팅, 순수 `id` 타입, 암묵적 전역 상태와 씨름하는 대신 IMKSwift는 다음을 제공합니다:

- **명시적 `@MainActor` 격리** — 모든 API에 적용
- **구체적이고 null 가능성이 주석 처리된 타입** — 순수 `id` 포인터 대신
- **완전한 Swift 6 동시성 지원**
- **완전한 InputMethodKit 표면 영역** — 안전한 사용을 위한 개선 포함

### 왜 IMKInputSessionController인가?

Apple의 `IMKInputController`는 MainActor에서 실행되도록 설계되었지만, Objective-C 헤더에 적절한 `@MainActor` 주석이 없습니다. Swift로 임포트될 때 근본적인 문제가 발생합니다: 원래 SDK 헤더가 액터 격리 없이 API를 노출하여 Swift 6 엄격 모드에서 **해결 불가능한 동시성 검사 오류**를 일으킵니다.

**Swift 6에서는 `IMKInputController`를 단순히 사용할 수 없습니다.** 헤더를 직접 오버라이드하려 해도 Swift가 여전히 원래 Xcode SDK 헤더를 가져와 API 충돌을 일으킵니다. 유일한 해결책은 **다른 이름의 서브클래스** — `IMKInputSessionController` — 를 사용하는 것입니다. 이 클래스는 모든 기능을 상속하면서 적절히 `@MainActor` 격리된 API를 제공합니다.

> **중요:** Swift 6에서 `IMKInputController`를 직접 서브클래싱하면 컴파일러 오류가 발생하며, 이를 "고치려면" 객체를 `@MainActor`에 강제로 올리기 위한 지저분한 포인터 조작이 필요합니다. 이렇게 하지 마십시오. 대신 `IMKInputSessionController`를 사용하십시오.

### 기능

#### 타입 안전성 및 Null 가능성
모든 API에 명시적 null 가능성 주석(`_Nullable`, `_Nonnull`)이 포함되어 있으며, 일반적인 `id` 대신 구체적인 Objective-C 타입(`NSString`, `NSAttributedString`, `NSDictionary`, `NSArray`, `NSEvent` 등)을 사용합니다.

#### MainActor 격리
모든 메서드와 프로퍼티에 `@MainActor`가 표시되어 컴파일 시점에 호출 지점 안전성을 보장하고 동시성 코드에서 경쟁 조건(Race Condition)을 방지합니다.

#### 완전한 InputMethodKit 커버리지
IMKSwift는 다음 InputMethodKit 컴포넌트를 재내보내기(re-export)하고 개선합니다:

- **IMKCandidates** — 후보 패널 관리 및 표시
- **IMKServer** — 입력기 세션 서버
- **IMKInputSessionController** — 입력기 이벤트 처리 및 조합 (**Swift 6+에서 유일하게 권장되는 기본 클래스**)
- **IMKTextInput** — 텍스트 편집 클라이언트 프로토콜
- **지원 프로토콜** — IMKStateSetting, IMKMouseHandling, IMKServerInput

#### Swift 6 대응
Swift 6의 엄격한 동시성 모델을 고려하여 구축되었습니다. 모든 API가 적절히 격리되어 있으며 데이터 경쟁 없이 동시성 컨텍스트에서 사용할 수 있습니다.

### 요구 사항

- **Swift** 6.2 이상
- **macOS** 10.13 이상 (사용하는 Swift 버전에 따라 다름)
- **Xcode** 16.0 이상

### 설치

#### Swift Package Manager

`Package.swift`에 IMKSwift를 추가합니다:

```swift
.package(url: "https://github.com/vChewing/IMKSwift.git", from: "26.03.06"),
```

그런 다음 타겟에 의존성으로 추가합니다:

```swift
.target(
  name: "MyInputMethod",
  dependencies: [
    .product(name: "IMKSwift", package: "IMKSwift"),
  ]
)
```

### 사용법

#### 기본 입력기 컨트롤러 설정

```swift
import IMKSwift

@objc(MyInputMethodController)
public final class MyInputMethodController: IMKInputSessionController {
  override public func handle(_ event: NSEvent?, client sender: any IMKTextInput) -> Bool {
    // 완전한 타입 안전성으로 이벤트 처리
    guard let event else { return false }

    // 입력 처리...
    return true
  }

  override func inputText(_ string: String, client sender: any IMKTextInput) -> Bool {
    // 텍스트 입력 처리
    return true
  }

  override func candidates(_ sender: any IMKTextInput) -> [Any]? {
    // 후보 제안 반환
    return nil
  }
}
```

#### 후보 작업

```swift
// 후보 패널 생성 및 표시
let candidates = IMKCandidates(
  server: server,
  panelType: .horizontal
)

candidates.show(.below)
```

#### 조합 관리

```swift
// 속성으로 조합 업데이트
updateComposition()

// 선택 범위 및 교체 범위 접근
let selRange = selectionRange()
let replaceRange = replacementRange()

// 조합 커밋
commitComposition(sender)
```

### 모범 사례

#### 1. NSConnection 이름 지정

입력기의 `Info.plist`에서 `InputMethodConnectionName` 키는 반드시 다음과 같이 설정해야 합니다:

```
$(PRODUCT_BUNDLE_IDENTIFIER)_Connection
```

> 이 명명 규칙은 macOS 10.7 Lion 이후로 필수입니다. 이를 지키지 않으면 샌드박스가 활성화된 상태에서 입력기가 로드되지 않습니다. `Console.app`에서 NSConnection 관련 오류를 확인할 수 있습니다.

#### 2. App Sandbox 활성화

가능하면 항상 샌드박스를 활성화하십시오. 취약한 NSConnection 메커니즘을 사용해야 하는 상황에서, 샌드박스 없이는 Apple이 입력기의 안전성을 신뢰할 방법이 없습니다. 샌드박스 활성화는 사용자에게 제공할 수 있는 최고의 보안 자격 증명입니다.

권장 `entitlements` 파일:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.app-sandbox</key>
  <true/>
  <key>com.apple.security.files.bookmarks.app-scope</key>
  <true/>
  <key>com.apple.security.files.user-selected.read-write</key>
  <true/>
  <key>com.apple.security.network.client</key>
  <true/>
  <key>com.apple.security.temporary-exception.files.home-relative-path.read-write</key>
  <array>
    <string>/Library/Preferences/$(PRODUCT_BUNDLE_IDENTIFIER).plist</string>
  </array>
  <key>com.apple.security.temporary-exception.mach-register.global-name</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)_Connection</string>
  <key>com.apple.security.temporary-exception.shared-preference.read-only</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
</dict>
</plist>
```

#### 3. 컨트롤러에서 강한 참조를 유지하지 마십시오

**`IMKInputSessionController` 서브클래스는 비즈니스 로직 객체를 직접 보유해서는 안 됩니다.** 이는 고빈도 입력기 전환(예: CapsLock으로 ABC와 자신의 IME 사이를 토글)을 처리하는 데 매우 중요합니다.

사용자가 입력기를 빠르게 전환하면 시스템은 매번 새로운 `IMKInputController` 인스턴스를 생성합니다. 컨트롤러가 무거운 객체에 대한 강한 참조를 유지하면 ARC 정리로 인해 눈에 띄는 지연이 발생합니다.

**권장 패턴:** 클라이언트 객체를 키로 하는 약한 키 캐시(`NSMapTable`)를 사용합니다:

```swift
import IMKSwift

@objc(MyInputMethodController)
public final class MyInputMethodController: IMKInputSessionController {
  // 세션에 대한 약한 참조 사용
  weak var session: InputSession?

  override public init(server: IMKServer, delegate: Any?, client inputClient: any IMKTextInput) {
    super.init(server: server, delegate: delegate, client: inputClient)

    // 캐시된 세션 초기화 또는 검색
    self.session = InputSessionCache.session(for: inputClient, controller: self)
  }
}

@MainActor
final class InputSessionCache {
  private static let cache = NSMapTable<NSObject, InputSession>.weakToStrongObjects()

  static func session(for client: any IMKTextInput, controller: MyInputMethodController) -> InputSession {
    let clientObj = client as! NSObject
    if let cached = cache.object(forKey: clientObj) {
      cached.reassign(controller: controller)
      return cached
    }
    let newSession = InputSession(controller: controller)
    cache.setObject(newSession, forKey: clientObj)
    return newSession
  }
}

@MainActor
final class InputSession {
  weak var controller: MyInputMethodController?

  init(controller: MyInputMethodController) {
    self.controller = controller
  }

  func reassign(controller: MyInputMethodController) {
    self.controller = controller
  }
}
```

#### 4. Swift Package 라이브러리로 구조화

macOS 입력기는 중단점(breakpoint)으로 디버깅할 수 없습니다 — 클라이언트 애플리케이션과 전체 데스크톱이 멈춰버립니다. 유일하게 실행 가능한 방법은 모의 클라이언트(mocked client)를 사용한 단위 테스트입니다.

입력기를 Swift Package로 구조화하십시오:
- **핵심 라이브러리** — 비즈니스 로직, 단위 테스트로 테스트 가능
- **입력기 타겟** — IMKSwift를 핵심 라이브러리에 연결하는 얇은 래퍼

이 방식을 사용하면 타이핑을 시뮬레이션하고 Instruments로 메모리 누수를 감지하기 위한 표준 AppKit 앱도 작성할 수 있습니다.

#### 5. IMKCandidates 사용 지양

시스템이 제공하는 `IMKCandidates`에는 심각한 문제가 있으며, 특히 macOS 26에서는 LiquidGlass 렌더링이 시각적 결함(투명한 배경 위에 흰색 텍스트)을 일으킵니다. **SwiftUI 또는 AppKit을 사용하여 자체 후보 패널을 구현하는 것을 고려하십시오.**

> Apple 자체의 NumberInput 샘플조차 `IMKCandidates`를 피합니다.

#### 6. 메모리 관리

사용자 메모리는 소중합니다. macOS 26의 AppKit 비효율성으로 인해 입력기가 80-200 MB를 소비할 수 있습니다:

- `activateServer()`에서 **메모리 사용량을 모니터링**하고 1024 MB를 초과하면 자체 종료합니다 (`NSNotification`으로 사용자에게 알림)
- **NSWindow 수를 최소화** — macOS 26부터 NSWindow 메모리는 절대 회수되지 않습니다. 패널(툴팁, 후보 창 등)을 가능한 한 단일 `NSPanel`로 통합하십시오

### 아키텍처

#### 구조

- **IMKSwift** — 프로토콜 정의 및 확장이 포함된 메인 Swift 라이브러리
- **IMKSwiftModernHeaders** — `@MainActor` 주석 및 타입 개선이 포함된 현대화된 Objective-C 헤더

#### IMKInputSessionController 솔루션

`IMKInputSessionController`는 `IMKInputController`의 구체적 서브클래스로, Swift/Objective-C 상호운용성 한계를 해결하기 위해서만 존재합니다.

**문제:**
- `IMKInputController`의 원래 SDK 헤더가 `@MainActor` 격리 없이 API를 노출
- Swift가 이를 비격리로 임포트하여 엄격한 동시성 오류 발생
- 기존 클래스의 헤더를 오버라이드하면 API 충돌 발생

**해결:**
- 동일한 API 표면을 가진 새로운 서브클래스(`IMKInputSessionController`) 생성
- Objective-C에서 `#pragma clang attribute`를 통해 `@MainActor` 격리 적용
- Swift는 적절히 격리된 메서드를 가진 새로운 클래스를 인식

**얻을 수 있는 것:**
- 모든 메서드에 `@MainActor` 격리
- 명시적 null 가능성 주석 (`_Nonnull` / `_Nullable`)
- 순수 `id` 대신 구체적인 Objective-C 타입

컴패니언 Swift 모듈에서 `IMKInputSessionController`는 `IMKInputSessionControllerProtocol`에 준수하도록 확장됩니다. 이는 전체 API 표면을 미러링하는 Swift 네이티브 `@MainActor` 프로토콜입니다.

### API 문서

#### 핵심 프로토콜 — IMKInputSessionControllerProtocol

MainActor 격리 프로토콜로 다음을 포함합니다:
- `IMKStateSetting` — 활성화, 비활성화, 환경설정
- `IMKMouseHandling` — 마우스 이벤트 처리
- `IMKServerInput` — 텍스트 및 이벤트 입력
- 조합 관리 — `updateComposition()`, `commitComposition(_:)` 등

#### 주요 메서드

**상태 관리:**
- `activateServer(_:)` — 입력기 활성화
- `deactivateServer(_:)` — 입력기 비활성화
- `showPreferences(_:)` — 환경설정 대화상자 표시

**텍스트 및 조합:**
- `inputText(_:key:modifiers:client:)` — 상세 매개변수로 키보드 입력 처리
- `inputText(_:client:)` — 키보드 입력 처리 (간소화)
- `handle(_:client:)` — 원시 `NSEvent` 처리
- `updateComposition()` — 현재 조합 업데이트
- `cancelComposition()` — 진행 중인 조합 취소
- `commitComposition(_:)` — 조합 확정

**후보 관리:**
- `candidates(_:)` — 후보 제안 제공
- `candidateSelected(_:)` — 후보 선택 처리
- `candidateSelectionChanged(_:)` — 선택 변경 처리

**마우스 처리:**
- `mouseDown(onCharacterIndex:coordinate:withModifier:continueTracking:client:)`
- `mouseUp(onCharacterIndex:coordinate:withModifier:client:)`
- `mouseMoved(onCharacterIndex:coordinate:withModifier:client:)`

### 원래 InputMethodKit과의 차이점

| 기능 | InputMethodKit | IMKSwift |
|------|----------------|----------|
| **동시성** | 격리 없음 | 완전한 `@MainActor` 격리 |
| **타입 안전성** | 순수 `id` 타입 | 구체적, 명명된 타입 |
| **Null 가능성** | 암묵적 | 명시적 주석 |
| **Swift 지원** | 기본 브리징 | 완전한 Swift 6 통합 |
| **Swift 6 기본 클래스** | `IMKInputController` (고장) | `IMKInputSessionController` (동작) |

### 관련 프로젝트

이 라이브러리는 [vChewing 프로젝트](https://github.com/vChewing)의 일부입니다. 대천(大千) 자음-모음 동시 타격 키스트로크 타이핑 원리와 DAG-DP 문장 형성 기술 기반의 macOS용 가장 빠른 음성학적(phonetic) 중국어 입력기이며, 간체자와 번체자를 모두 네이티브로 지원합니다.

### 라이선스

MIT License (c) 2026 이후 The vChewing Project

---

# 2. 해설 주석 (Annotated Notes)

## InputMethodKit이란?

macOS에서 사용자 정의 입력기(Input Method)를 만들기 위한 Apple의 공식 프레임워크입니다. 한국어, 중국어, 일본어 등 CJK 입력기를 포함하여 모든 종류의 텍스트 입력 엔진을 만들 수 있습니다.

- **왜 중요한가:** macOS에서 서드파티 입력기를 만들려면 반드시 이 프레임워크를 거쳐야 합니다. 그런데 이 프레임워크가 2007년(macOS 10.5) 시절에 만들어져서 현대 Swift와 호환성 문제가 심각합니다.
- **실무 맥락:** 한국의 경우 구름 입력기, 세벌식 입력기 등이 이 프레임워크를 사용합니다.

## `@MainActor` 격리 문제

- **배경 지식:** Swift 6의 엄격한 동시성 모델에서는 모든 데이터 접근의 스레드 안전성을 컴파일 시점에 검증합니다. `@MainActor`는 해당 코드가 메인 스레드에서만 실행됨을 보장하는 주석입니다.
- **왜 중요한가:** InputMethodKit의 Objective-C 헤더에 이 주석이 없어서 Swift 6에서는 컴파일 자체가 되지 않습니다. 이는 Apple이 레거시 프레임워크를 Swift 6에 맞게 업데이트하지 않았기 때문입니다.
- **주의점:** 단순히 `@preconcurrency import`나 `nonisolated(unsafe)`로 우회하면 런타임에 데이터 경쟁이 발생할 수 있습니다. IMKSwift의 서브클래싱 접근법이 근본적인 해결책입니다.

## NSMapTable을 이용한 약한 키 캐시 패턴

- **왜 중요한가:** 입력기 전환이 CapsLock 하나로 이루어지는 환경에서, 매 전환마다 새 컨트롤러 인스턴스가 생성됩니다. 무거운 객체(사전 데이터, 언어 모델 등)를 매번 새로 생성하면 심각한 성능 저하가 발생합니다.
- **실무 맥락:** `NSMapTable.weakToStrongObjects()`는 키가 해제되면 자동으로 항목이 제거되는 캐시를 만듭니다. 클라이언트(텍스트 입력 앱)가 살아있는 동안만 세션이 유지되는 구조입니다.
- **관련 개념:** `WeakReference`, `NSCache`, `NSPointerArray` 등 Apple의 약한 참조 컬렉션 패밀리

## 디버깅 불가능한 입력기

- **왜 중요한가:** 입력기는 시스템 전체의 텍스트 입력을 가로채는 프로세스입니다. 중단점에서 멈추면 모든 앱의 텍스트 입력이 멈추고 데스크톱 전체가 프리즈됩니다.
- **실무 맥락:** 따라서 비즈니스 로직을 별도 라이브러리로 분리하고 단위 테스트로 검증하는 것이 유일하게 실용적인 디버깅 전략입니다. `print` 디버깅이나 `os_log`를 Console.app과 함께 사용하는 것도 보조 수단입니다.

## macOS 26의 LiquidGlass와 메모리 문제

- **배경 지식:** macOS 26 (2025년 WWDC에서 발표)은 LiquidGlass라는 새로운 디자인 언어를 도입하며, 이로 인해 기존 UI 컴포넌트의 렌더링 문제와 메모리 사용량 증가가 보고되고 있습니다.
- **주의점:** `NSWindow` 메모리가 절대 회수되지 않는다는 것은 심각한 이슈입니다. 입력기는 장시간 실행되는 프로세스이므로, 창을 만들었다 닫았다 하면 메모리가 계속 누적됩니다. 반드시 단일 `NSPanel`을 재사용해야 합니다.

## `#pragma clang attribute` 기법

- **배경 지식:** Clang 컴파일러의 어트리뷰트 푸시 기능으로, 특정 범위 내의 모든 선언에 동일한 속성을 일괄 적용할 수 있습니다.
- **실무 맥락:** IMKSwift는 이 기법을 사용하여 `IMKInputSessionController`의 모든 메서드에 `@MainActor`를 한 번에 적용합니다. 개별 메서드마다 수동으로 추가하는 것보다 훨씬 유지보수가 쉽습니다.

---

# 3. 용어 정리표 (Glossary)

| 원문 | 번역 | 설명 |
|------|------|------|
| InputMethodKit | InputMethodKit | macOS 입력기 구축용 Apple 프레임워크 |
| Input Method Engine | 입력기 엔진 | 키 입력을 문자로 변환하는 소프트웨어 |
| `@MainActor` | `@MainActor` | 메인 스레드 실행을 보장하는 Swift 동시성 주석 |
| Actor Isolation | 액터 격리 | 동시성 안전을 위해 데이터 접근을 특정 액터로 제한하는 것 |
| Strict Concurrency | 엄격한 동시성 | Swift 6의 컴파일 시점 동시성 안전 검사 |
| Candidate Panel | 후보 패널 | 입력 중 선택 가능한 문자/단어 목록을 표시하는 UI |
| Composition | 조합 | 아직 확정되지 않은 입력 중인 텍스트 |
| Commit (composition) | 커밋/확정 | 조합 중인 텍스트를 최종 확정하여 삽입 |
| NSConnection | NSConnection | 프로세스 간 통신을 위한 레거시 Objective-C 메커니즘 |
| NSMapTable | NSMapTable | 약한/강한 참조를 유연하게 조합할 수 있는 딕셔너리 |
| Sandboxing | 샌드박싱 | 앱의 시스템 리소스 접근을 제한하는 보안 메커니즘 |
| LiquidGlass | LiquidGlass | macOS 26에 도입된 새로운 UI 디자인 언어 |
| DAG-DP | DAG-DP | 유향 비순환 그래프 + 동적 프로그래밍 기반 문장 조합 알고리즘 |
| re-export | 재내보내기 | 임포트한 모듈을 다시 외부에 공개하는 것 |

---

# 4. 더 알아보기

- **Swift 6 Concurrency**: Swift 6의 엄격한 동시성 모델, `Sendable`, `@MainActor`, 데이터 격리 등의 개념을 깊이 이해하면 IMKSwift의 존재 이유를 더 잘 파악할 수 있습니다.
- **macOS 입력기 개발 가이드**: Apple의 [InputMethodKit 문서](https://developer.apple.com/documentation/inputmethodkit)와 NumberInput 샘플 코드
- **NSMapTable vs NSCache**: 약한 참조 컬렉션의 차이점과 사용 시나리오
- **한국어 입력기 개발**: 이 라이브러리는 중국어 입력기를 위해 만들어졌지만, 한국어 입력기(두벌식/세벌식) 개발에도 동일하게 적용 가능합니다. `handle(_:client:)` 메서드에서 키 이벤트를 받아 한글 조합 로직을 구현하면 됩니다.
- **Clang Attributes**: `#pragma clang attribute push`의 동작 원리와 Swift 상호운용성에서의 활용

---

# 5. 사용법 요약 (How to Use)

### 1단계: 프로젝트 설정

```swift
// Package.swift
let package = Package(
    name: "MyInputMethod",
    platforms: [.macOS(.v13)],
    targets: [
        // 비즈니스 로직 (테스트 가능한 라이브러리)
        .target(name: "MyIMECore"),
        // 입력기 실행 파일 (얇은 래퍼)
        .executableTarget(
            name: "MyInputMethod",
            dependencies: [
                "MyIMECore",
                .product(name: "IMKSwift", package: "IMKSwift"),
            ]
        ),
        .testTarget(name: "MyIMECoreTests", dependencies: ["MyIMECore"]),
    ]
)
```

### 2단계: 컨트롤러 구현

`IMKInputSessionController`를 서브클래싱하여 `handle(_:client:)` 등을 오버라이드합니다. 위 번역문의 "기본 입력기 컨트롤러 설정" 코드를 참고하십시오.

### 3단계: Info.plist 설정

- `InputMethodConnectionName`을 `$(PRODUCT_BUNDLE_IDENTIFIER)_Connection`으로 설정
- 적절한 entitlements 파일 구성 (샌드박스 활성화)

### 4단계: 메인 진입점

```swift
import Cocoa
import IMKSwift

@main
struct MyInputMethodApp {
    static func main() {
        let server = IMKServer(
            name: Bundle.main.infoDictionary!["InputMethodConnectionName"] as! String,
            bundleIdentifier: Bundle.main.bundleIdentifier!
        )
        _ = server  // 서버 유지
        NSApplication.shared.run()
    }
}
```

### 5단계: 빌드 및 설치

빌드된 `.app`을 `~/Library/Input Methods/`에 복사하고 로그아웃/로그인하면 시스템 환경설정의 키보드 > 입력 소스에서 선택할 수 있습니다.
