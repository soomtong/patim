//
//  InputKey.swift
//  Patal
//
//  Created by Earth Shaker on 2024/03/02.
//

import Foundation
import InputMethodKit

#if DEBUG
    @inline(__always)
    private func debugLog(_ message: String) {
        print(message)
    }
#else
    @inline(__always)
    private func debugLog(_ message: String) {}
#endif

/// 조합 처리 후 결과를 담고 있음; 처리 과정의 상태는 preedit 의 상태를 판단하면 됨
enum CommitState {
    case none
    case composing
    case committed
}

/// insertText 와 setMarkedText 호출을 위한 조건 구분
enum InputStrategy {
    case directInsert
    case swapMarked

    // MARK: - Bundle ID 기반 전략 캐시
    // 측정 데이터: misc/client-attributes.md 참조
    // Sok 입력기 참고: https://github.com/kiding/SokIM/blob/main/SokIM/Strategy.swift
    // validAttributesForMarkedText() 호출 없이 바로 전략 결정 → 성능 최적화

    /// 측정 완료된 앱의 전략 맵
    private static let knownApps: [String: InputStrategy] = [
        // 브라우저
        "com.apple.Safari": .directInsert,          // NSTextAlternatives 포함
        "com.google.Chrome": .swapMarked,           // NSMarkedClauseSegment만
        "org.mozilla.firefox": .swapMarked,         // NSMarkedClauseSegment만 (NSFont 없음)
        "com.duckduckgo.macos.browser": .directInsert,  // NSTextAlternatives 포함 (Sok 참고)

        // 개발 도구
        "com.apple.dt.Xcode": .directInsert,        // NSMarkedClauseSegment + NSGlyphInfo
        "com.apple.Terminal": .swapMarked,          // NSMarkedClauseSegment 없음
        "com.googlecode.iterm2": .swapMarked,       // NSMarkedClauseSegment 없음
        "io.alacritty": .swapMarked,                // Sok 참고
        "com.google.android.studio": .swapMarked,   // Sok 참고
        "com.sublimetext.4": .swapMarked,           // Sok 참고
        "com.sublimetext.3": .swapMarked,

        // Apple 텍스트 편집기
        "com.apple.TextEdit": .directInsert,        // NSTextAlternatives + NSGlyphInfo
        "com.apple.Notes": .directInsert,           // NSTextAlternatives + NSGlyphInfo
        "com.apple.Stickies": .directInsert,        // Sok 참고: NSTextAlternatives 포함

        // iWork 앱 (Sok 참고: NSMarkedClauseSegment + NSFont)
        "com.apple.iWork.Pages": .directInsert,
        "com.apple.iWork.Keynote": .directInsert,
        // ⚠️ Numbers는 휴리스틱과 반대로 작동 - overrideApps에서 처리

        // Microsoft Office (Sok 참고)
        "com.microsoft.Word": .directInsert,        // NSFont + NSMarkedClauseSegment
        "com.microsoft.Powerpoint": .directInsert,
        "com.microsoft.Excel": .swapMarked,         // Sok 참고: 예외

        // Electron 기반 앱
        "com.microsoft.VSCode": .swapMarked,        // NSMarkedClauseSegment만 (NSFont 없음)
        "com.tinyspeck.slackmacgap": .swapMarked,
        "com.hnc.Discord": .swapMarked,

        // 메신저/SNS
        "jp.naver.line.mac": .swapMarked,           // Sok 참고

        // 기타
        "org.gimp.gimp-2.10": .swapMarked,          // Sok 참고
    ]

    /// 휴리스틱과 반대로 작동하는 앱 (명시적 오버라이드)
    /// Numbers: NSFont + NSMarkedClauseSegment를 반환하지만 swapMarked가 필요 (Sok 참고)
    private static let overrideApps: [String: InputStrategy] = [
        "com.apple.iWork.Numbers": .swapMarked,
    ]

    /// prefix 기반 매칭이 필요한 앱 (Sok 참고)
    /// 한컴오피스: 한글, 한셀, 한쇼 등 모두 동일 prefix
    private static let prefixRules: [(prefix: String, strategy: InputStrategy)] = [
        ("com.hancom.office.hwp", .swapMarked),
    ]

    // MARK: - 전략 결정

    /// Bundle ID로 전략 결정 (측정된 앱은 빠른 경로)
    @inline(__always)
    static func determineFast(bundleId: String) -> InputStrategy? {
        // 1. 오버라이드 앱 (휴리스틱과 반대로 작동하는 앱)
        if let override = overrideApps[bundleId] {
            return override
        }

        // 2. prefix 규칙 확인 (한컴오피스 등)
        for rule in prefixRules {
            if bundleId.hasPrefix(rule.prefix) {
                return rule.strategy
            }
        }

        // 3. 측정된 앱 캐시
        return knownApps[bundleId]
    }

    /// Bundle ID와 validAttributesForMarkedText 결과로 입력 전략을 결정
    static func determine(bundleId: String, attributes: [String]) -> InputStrategy {
        // 1. 빠른 경로 (오버라이드/prefix/캐시)
        if let fast = determineFast(bundleId: bundleId) {
            return fast
        }

        // 2. 미측정 앱은 휴리스틱 적용
        return determineFromAttributes(attributes)
    }

    /// validAttributesForMarkedText 결과만으로 전략 결정 (하위 호환성)
    static func determine(from attributes: [String]) -> InputStrategy {
        return determineFromAttributes(attributes)
    }

    /// 속성 기반 휴리스틱 (Sok 입력기 참고)
    private static func determineFromAttributes(_ attributes: [String]) -> InputStrategy {
        // - NSTextAlternatives: 대체 텍스트 지원 → 네이티브 텍스트 시스템
        // - NSMarkedClauseSegment + NSFont/NSGlyphInfo: 풍부한 조합 문자 렌더링 지원
        if attributes.contains("NSTextAlternatives")
            || attributes.contains("NSMarkedClauseSegment") && attributes.contains("NSFont")
            || attributes.contains("NSMarkedClauseSegment") && attributes.contains("NSGlyphInfo")
        {
            return .directInsert
        }
        return .swapMarked
    }
}

class HangulProcessor {
    internal let logger = CustomLogger(category: "InputTextKey")
    let layoutName: String

    /// OS 에서 제공하는 문자
    var rawChar: String

    /// preedit 에 처리중인 rawChar 배열: 겹낱자나 느슨한 조합을 위한 버퍼
    var composing: [String] {
        get { stateMachine.buffer.composingKeys }
        set {
            var newBuffer = stateMachine.buffer
            newBuffer.composingKeys = newValue
            stateMachine.setBuffer(newBuffer)
        }
    }
    /// 키 입력 히스토리: 백스페이스 시 정확한 복원을 위해 키 1회 입력 = 1원소
    var keyHistory: [String] {
        get { stateMachine.buffer.keyHistory }
        set {
            var newBuffer = stateMachine.buffer
            newBuffer.keyHistory = newValue
            stateMachine.setBuffer(newBuffer)
        }
    }
    /// previous 를 한글 처리된 문자
    var preedit: 조합자 {
        get { stateMachine.buffer.to조합자() }
        set {
            var newBuffer = SyllableBuffer(from: newValue)
            newBuffer.composingKeys = stateMachine.buffer.composingKeys
            newBuffer.keyHistory = stateMachine.buffer.keyHistory
            stateMachine.setBuffer(newBuffer)
        }
    }
    /// 조합 종료된 한글
    var 완성: String?

    var hangulLayout: HangulAutomata {
        didSet {
            recreateStateMachinePreservingBuffer()
        }
    }

    /// StateMachine 인스턴스
    private var stateMachine: CompositionStateMachine

    /// traits 변경 시 StateMachine을 재생성하면서 버퍼 상태 보존
    private func recreateStateMachinePreservingBuffer() {
        let savedBuffer = stateMachine.buffer
        stateMachine = CompositionStateMachine(layout: hangulLayout)
        stateMachine.setBuffer(savedBuffer)
    }

    let managableModifiers = [ModifierCode.NONE.rawValue, ModifierCode.SHIFT.rawValue]

    init(layout: HangulAutomata) {
        layoutName = String(describing: type(of: layout))
        hangulLayout = layout
        stateMachine = CompositionStateMachine(layout: layout)

        logger.debug("입력키 처리 클래스 초기화: \(layoutName)")

        rawChar = ""
    }

    deinit {
        logger.debug("입력키 처리 클래스 해제: \(layoutName)")
    }

    /// 조합중인 낱자가 있는지 검사
    func countComposable() -> Int {
        var count = 0
        if preedit.chosung != nil { count += 1 }
        if preedit.jungsung != nil { count += 1 }
        if preedit.jongsung != nil { count += 1 }
        return count
    }

    /// 클라이언트에 적합한 입력 전략 결정
    /// - setMarkedText의 replacementRange 처리 방식에 따라 directInsert/swapMarked 구분
    /// - 측정된 앱(knownApps)은 validAttributesForMarkedText 호출 없이 바로 결정 (성능 최적화)
    @inline(__always)
    func getInputStrategy(client: IMKTextInput) -> InputStrategy {
        let bundleId = client.bundleIdentifier() ?? "unknown"

        // 측정된 앱은 빠른 경로 (validAttributesForMarkedText 호출 생략)
        if let strategy = InputStrategy.determineFast(bundleId: bundleId) {
            logger.debug("[\(bundleId)] 전략: \(strategy) (캐시)")
            return strategy
        }

        // 미측정 앱은 휴리스틱 적용
        let attributes = client.validAttributesForMarkedText() as? [String] ?? []
        logger.debug("[\(bundleId)] validAttributes: \(attributes)")
        return InputStrategy.determine(bundleId: bundleId, attributes: attributes)
    }

    /// 처리 가능한 입력인지 검증한다.
    /// - 백스페이스는 별도 처리해야 함
    /// - 모디파이어가 있는 경우는 비한글 처리해야 함
    /// OS 에게 처리 절차를 바로 넘기는 조건
    /// - 백스페이스 + 글자단위 삭제 특성이 활성화 된 경우
    /// - command, option 키와 함께 사용되는 경우
    /// - 한글 레이아웃 자판 맵에 등록되지 않은 키코드 인 경우
    func verifyProcessable(_ s: String, keyCode: Int = 0, modifierCode: Int = 0) -> Bool {
        logger.debug(" => \(s), \(keyCode), \(modifierCode)")

        if !managableModifiers.contains(modifierCode) { return false }

        // 자소단위 삭제(글자단위 삭제가 아닌 경우)인 경우는 composer 로 넘겨야 함(true 반환)
        let composableBackspace =
            !hangulLayout.can글자단위삭제
            && (keyCode == KeyCode.BACKSPACE.rawValue && modifierCode == 0)
        if composableBackspace { return true }

        // 키코드 기반 검증 우선 적용 (라틴 자판 독립적)
        if let hangulChar = KeyCodeMapper.mapKeyCodeToHangulChar(keyCode: keyCode, modifiers: modifierCode) {
            return hangulLayout.chosungMap[hangulChar] != nil
                || hangulLayout.jungsungMap[hangulChar] != nil
                || hangulLayout.jongsungMap[hangulChar] != nil
                || hangulLayout.nonSyllableMap[hangulChar] != nil
        }

        // 키코드 매핑이 없는 경우 기존 문자열 기반 검증 (하위 호환성)
        return hangulLayout.chosungMap[s] != nil
            || hangulLayout.jungsungMap[s] != nil
            || hangulLayout.jongsungMap[s] != nil
            || hangulLayout.nonSyllableMap[s] != nil
    }

    /// 한글 조합 가능한 입력인지 검증한다.
    func verifyCombosable(_ s: String) -> Bool {
        return hangulLayout.chosungMap[s] != nil
            || hangulLayout.jungsungMap[s] != nil
            || hangulLayout.jongsungMap[s] != nil
    }

    /// 키코드를 한글 입력용 문자로 변환하고 rawChar에 설정
    /// - Parameters:
    ///   - keyCode: 물리적 키코드
    ///   - modifiers: 수정자 키 플래그
    /// - Returns: 변환된 문자 (라틴 자판 독립적)
    func processKeyCodeInput(keyCode: Int, modifiers: Int) -> String? {
        if let hangulChar = KeyCodeMapper.mapKeyCodeToHangulChar(keyCode: keyCode, modifiers: modifiers) {
            rawChar = hangulChar
            logger.debug(
                "키코드 변환: \(KeyCodeMapper.debugKeyInfo(keyCode: keyCode, modifiers: modifiers)) -> '\(hangulChar)'")
            return hangulChar
        }
        return nil
    }

    /// 조합 가능한 문자가 들어온다. 다시 검수할 필요는 없음. 겹자음/겹모음이 있을 수 있기 때문에 previous 를 기준으로 운영.
    /// previous=raw char 조합, preedit=조합중인 한글, commit=조합된 한글
    @_optimize(speed)
    @inline(__always)
    func 한글조합() -> CommitState {
        let result = stateMachine.processInput(rawChar)

        switch result {
        case .composing:
            return .composing
        case .commit(let committed, _):
            완성 = committed
            return .committed
        case .invalid:
            return .none
        }
    }

    /// 준비된 조합자를 한글 글자로 변환
    func getComposed() -> String? {
        if let hangulComposer = HangulComposer(
            chosungPoint: preedit.chosung,
            jungsungPoint: preedit.jungsung,
            jongsungPoint: preedit.jongsung
        ) {
            if let char = hangulComposer.getSyllable() {
                return String(char)
            }
        }
        // 현대한글 조합을 못하면 옛한글 시도
        if let char = getComposedAlternative(preedit: preedit) {
            return String(char)
        }

        return nil
    }

    /// 현대한글로 전환하지 못한 경우 NFD 로 제공
    func getComposedAlternative(preedit: 조합자) -> Character? {
        var unicodeScalars = String.UnicodeScalarView()

        if let codePoint = preedit.chosung {
            let scala = UnicodeScalar(codePoint.rawValue)!
            unicodeScalars.append(UnicodeScalar(scala))
        }
        if let codePoint = preedit.jungsung {
            let scala = UnicodeScalar(codePoint.rawValue)!
            unicodeScalars.append(UnicodeScalar(scala))
        }
        if let codePoint = preedit.jongsung {
            let scala = UnicodeScalar(codePoint.rawValue)!
            unicodeScalars.append(UnicodeScalar(scala))
        }

        if unicodeScalars.count > 0 {
            return Character(UnicodeScalarType(unicodeScalars))
        }

        return nil
    }

    /// 한글이 아닌 문자가 들어오는 경우
    func getConverted() -> String? {
        if let nonSyllable = hangulLayout.pickNonSyllable(by: rawChar) {
            return nonSyllable
        }

        return nil
    }

    /// 백스페이스가 들어오면 키 히스토리에서 마지막 입력을 제거하고 재조합
    func applyBackspace() -> Int {
        let result = stateMachine.applyBackspace()

        switch result {
        case .composing(let buffer):
            return buffer.composableCount
        default:
            return 0
        }
    }

    func resetComposing(_ s: String) {
        stateMachine.resetComposingKeys(s)
    }

    func clearPreedit() {
        stateMachine.reset()
    }

    func clearBuffers() {
        rawChar = ""
        완성 = nil
    }

    func composeCommitToUpdate() -> String? {
        if let syllable = getComposed() {
            logger.debug("조합이 가능함: \(String(describing: syllable))")
            return syllable
        }
        /// 조합이 불가능한 경우 대체 문자를 제공
        if composing.count > 0 {
            logger.debug("조합이 불가능함: \(String(describing: composing))")
            return String(UnicodeScalar(그외.대체문자.rawValue)!)
        }
        return nil
    }

    /// 버퍼에 있는 커밋이나 조합 중인 글자를 내보내기
    func flushCommit() -> [String] {
        var buffers: [String] = []

        // 남은 완성 글자가 있는 경우 (드문 케이스)
        if let commit = 완성 {
            logger.debug("남은 완성 글자 내보내기: \(String(describing: commit))")
            buffers.append(commit)
        }

        // StateMachine flush로 조합 중인 글자 처리
        if let flushed = stateMachine.processFlush() {
            logger.debug("StateMachine flush 결과: \(flushed)")
            buffers.append(flushed)
        }

        // 비조합 문자 처리 (nonSyllable)
        if let nonSyllable = getConverted() {
            logger.debug("조합 불가한 글자 내보내기: \(String(describing: nonSyllable))")
            buffers.append(nonSyllable)
        }

        clearBuffers()

        return buffers
    }
}
