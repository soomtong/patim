//
//  InputControllerTests.swift
//  PatalTests
//
//  Created by dp on 12/26/24.
//

import Testing

@testable import Patal

// MARK: - ⚠️ 주의: 이 테스트는 실제 InputController를 테스트하지 않습니다.
//
// IMKInputController는 macOS 입력기 시스템 프로세스에서만 정상 동작하며,
// 단위 테스트 환경에서는 다음 이유로 인스턴스화가 불가능합니다:
//   1. getCurrentInputMethodID()가 nil을 반환하여 init이 실패함
//   2. IMKServer/IMKInputController 초기화 시 segmentation fault 발생
//
// 따라서 이 테스트는 InputController의 상태 관리 로직(isControllerActivated, isInstanceSynced)을
// 모방한 ControllerState 구조체를 테스트합니다. 실제 InputController의 동작 검증이 아닌,
// 로직의 정확성만 검증하는 제한적인 테스트입니다.
//
// 실제 InputController 테스트를 위해서는:
//   - 입력기를 시스템에 설치 후 통합 테스트 수행
//   - 또는 상태 로직을 별도 클래스로 분리하여 의존성 주입 방식으로 리팩토링 필요
//
// MARK: - 📚 다른 macOS 입력기 프로젝트의 테스트 패턴 조사 결과 (2026.01)
//
// | 프로젝트     | 핵심 패턴                          | 테스트 가능성                    |
// |-------------|-----------------------------------|--------------------------------|
// | Gureum      | InputReceiver 분리 + Mock 객체     | GureumComposer 단위 테스트       |
// | macSKK      | StateMachine 완전 분리 + Combine   | 200개 이상 상태 머신 테스트        |
// | azooKey     | 직접 결합                          | 실질 테스트 없음                  |
//
// 핵심 인사이트:
//   - 어떤 프로젝트도 IMKInputController를 직접 테스트하지 않음
//   - 핵심 로직을 별도 클래스(StateMachine, InputReceiver)로 분리
//   - IMKTextInput 프로토콜 Mock 사용하여 클라이언트 시뮬레이션
//   - InputController는 얇은 위임(delegation) 계층으로 유지
//
// 권장 아키텍처 (macSKK 스타일):
//   ```swift
//   // 테스트 가능한 순수 상태 머신 (IMK 의존성 없음)
//   class HangulStateMachine {
//       func handle(action: KeyAction, state: ComposingState)
//           -> (newState: ComposingState, output: IMEOutput)
//   }
//
//   // InputController는 오케스트레이션만
//   @objc class InputController: IMKInputController {
//       var stateMachine = HangulStateMachine()
//       // stateMachine.handle() 호출 후 결과를 client에 적용
//   }
//   ```
//
// 현재 프로젝트의 HangulProcessor가 이미 이 방향으로 설계되어 있음.
// HangulProcessor를 직접 테스트하는 것이 올바른 접근임.
//
// 참고:
//   - https://github.com/gureum/gureum
//   - https://github.com/mtgto/macSKK
//   - https://github.com/ensan-hcl/azooKey-Desktop

@Suite("ControllerState Tests")
struct ControllerStateTests {

    // MARK: - ControllerState 모델 테스트

    @Test("초기 상태는 비활성화")
    func testInitialState() {
        let state = ControllerState()
        #expect(state.isActivated == false)
        #expect(state.isSyncing == false)
    }

    @Test("activate 호출 시 isActivated가 true로 변경")
    func testActivate() {
        var state = ControllerState()
        state.activate()
        #expect(state.isActivated == true)
    }

    @Test("deactivate 호출 시 isActivated가 false로 변경")
    func testDeactivate() {
        var state = ControllerState()
        state.activate()
        #expect(state.isActivated == true)

        state.deactivate()
        #expect(state.isActivated == false)
    }

    @Test("activate/deactivate 사이클 테스트")
    func testActivateDeactivateCycle() {
        var state = ControllerState()

        #expect(state.isActivated == false)
        state.activate()
        #expect(state.isActivated == true)
        state.deactivate()
        #expect(state.isActivated == false)
        state.activate()
        #expect(state.isActivated == true)
    }

    // MARK: - 동기화 가드 테스트

    @Test("비활성화 상태에서 syncIfNeeded는 동기화하지 않음")
    func testSyncGuardWhenDeactivated() {
        var state = ControllerState()
        var syncCount = 0

        state.syncIfNeeded { syncCount += 1 }

        #expect(syncCount == 0)
    }

    @Test("활성화 상태에서 syncIfNeeded는 동기화 수행")
    func testSyncWhenActivated() {
        var state = ControllerState()
        state.activate()
        var syncCount = 0

        state.syncIfNeeded { syncCount += 1 }

        #expect(syncCount == 1)
    }

    @Test("동기화 중 중복 호출 방지")
    func testSyncReentrancyGuard() {
        let state = ControllerStateClass()
        state.activate()
        var callOrder: [String] = []

        state.syncIfNeeded {
            callOrder.append("outer-start")
            state.syncIfNeeded {
                callOrder.append("inner")
            }
            callOrder.append("outer-end")
        }

        #expect(callOrder == ["outer-start", "outer-end"])
        #expect(state.isSyncing == false)
    }

    @Test("동기화 완료 후 isSyncing은 false로 복원")
    func testSyncFlagResetAfterCompletion() {
        var state = ControllerState()
        state.activate()

        state.syncIfNeeded {}

        #expect(state.isSyncing == false)
    }
}

// MARK: - ControllerState 구조체 (테스트 가능한 상태 관리)

struct ControllerState {
    var isActivated: Bool = false
    var isSyncing: Bool = false

    mutating func activate() {
        isActivated = true
    }

    mutating func deactivate() {
        isActivated = false
    }

    mutating func syncIfNeeded(_ syncAction: () -> Void) {
        guard isActivated else { return }
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        syncAction()
    }
}

// 중첩 호출 테스트용 클래스 (참조 타입으로 exclusive access 문제 회피)
class ControllerStateClass {
    var isActivated: Bool = false
    var isSyncing: Bool = false

    func activate() {
        isActivated = true
    }

    func deactivate() {
        isActivated = false
    }

    func syncIfNeeded(_ syncAction: () -> Void) {
        guard isActivated else { return }
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        syncAction()
    }
}
