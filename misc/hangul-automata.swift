import Foundation

enum InputState {
    case initial  // 초기 상태
    case inputConsonant  // 초성 입력 중
    case inputVowel  // 중성 입력 중
    case finalConsonant  // 종성 입력 중
}

class HangulInputFSM {
    private var state: InputState = .initial
    private var buffer: (initial: String?, medial: String?, final: String?) = (nil, nil, nil)

    func handleInput(_ input: String?) -> String? {
        guard let input = input else {
            // 입력 종료 시 미완성 글자 강제 완성
            let result = composeHangul(buffer)
            reset()
            return result.isEmpty ? nil : result
        }

        switch state {
        case .initial:
            if isConsonant(input) {
                buffer.initial = input
                state = .inputConsonant
            } else if isVowel(input) {
                buffer.medial = input
                state = .inputVowel
            }
        case .inputConsonant:
            if isVowel(input) {
                buffer.medial = input
                state = .inputVowel
            } else if isConsonant(input) {
                buffer.final = input
                state = .finalConsonant
            }
        case .inputVowel:
            if isConsonant(input) {
                buffer.final = input
                state = .finalConsonant
            } else if isVowel(input) {
                buffer.medial = combineVowels(buffer.medial, input)
            }
        case .finalConsonant:
            if isConsonant(input) {
                // 현재 글자 완성 후 새 초성으로 이동
                let result = composeHangul(buffer)
                buffer = (initial: input, medial: nil, final: nil)
                state = .inputConsonant
                return result
            } else if isVowel(input) {
                // 종성을 초성으로 이동 후 새로운 글자 시작
                let result = composeHangul(buffer)
                buffer = (initial: buffer.final, medial: input, final: nil)
                state = .inputVowel
                return result
            }
        }
        return nil
    }

    private func isConsonant(_ input: String) -> Bool {
        return ["ㄱ", "ㄴ", "ㄷ", "ㄹ", "ㅁ", "ㅂ", "ㅅ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"].contains(
            input)
    }

    private func isVowel(_ input: String) -> Bool {
        return ["ㅏ", "ㅑ", "ㅓ", "ㅕ", "ㅗ", "ㅛ", "ㅜ", "ㅠ", "ㅡ", "ㅣ", "ㅐ", "ㅔ", "ㅒ", "ㅖ"].contains(
            input)
    }

    private func combineVowels(_ first: String?, _ second: String) -> String? {
        guard let first = first else { return second }
        let combinations: [String: String] = [
            "ㅗㅏ": "ㅘ", "ㅗㅐ": "ㅙ", "ㅗㅣ": "ㅚ",
            "ㅜㅓ": "ㅝ", "ㅜㅔ": "ㅞ", "ㅜㅣ": "ㅟ",
            "ㅡㅣ": "ㅢ",
        ]
        return combinations[first + second] ?? second
    }

    private func composeHangul(_ buffer: (initial: String?, medial: String?, final: String?))
        -> String
    {
        guard let initial = buffer.initial, let medial = buffer.medial else {
            return ""  // 초성이나 중성이 없으면 글자를 완성할 수 없음
        }

        let unicodeBase = 0xAC00
        let initialIndex = initialToIndex(initial)
        let medialIndex = medialToIndex(medial)
        let finalIndex = finalToIndex(buffer.final)

        let unicodeValue = unicodeBase + (initialIndex * 21 * 28) + (medialIndex * 28) + finalIndex
        return String(UnicodeScalar(unicodeValue)!)
    }

    private func initialToIndex(_ initial: String) -> Int {
        let initials = [
            "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ",
            "ㅍ", "ㅎ",
        ]
        return initials.firstIndex(of: initial) ?? 0
    }

    private func medialToIndex(_ medial: String) -> Int {
        let medials = [
            "ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ",
            "ㅠ", "ㅡ", "ㅢ", "ㅣ",
        ]
        return medials.firstIndex(of: medial) ?? 0
    }

    private func finalToIndex(_ final: String?) -> Int {
        let finals = [
            "", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ",
            "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ",
        ]
        return finals.firstIndex(of: final ?? "") ?? 0
    }

    private func reset() {
        state = .initial
        buffer = (nil, nil, nil)
    }
}

let fsm = HangulInputFSM()

let inputs = ["ㄱ", "ㅏ", "ㄴ", "ㄱ", "ㅗ", "ㅏ"]  // 기대 결과: "간", "과"
for input in inputs {
    if let result = fsm.handleInput(input) {
        print("완성된 글자: \(result)")
    }
}

// 입력 종료 시 처리
if let finalResult = fsm.handleInput(nil) {
    print("완성된 글자: \(finalResult)")
}
