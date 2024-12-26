//
//  KeyProcessorTests.swift
//  PatalTests
//
//  Created by dp on 11/23/24.
//

import Testing

@testable import Patal

@Suite("신세벌 PCS 자판 테스트", .serialized)
struct Hangul3ShinPcsTests {
    let layout = bindLayout(layout: .HAN3_SHIN_PCS)
    var processor: HangulProcessor!

    init() {
        processor = HangulProcessor(layout: layout)
    }

    @Test("유효한 문자만 받기")
    func setKey() {
        var r1 = processor.verifyCombosable("i")
        #expect(r1 == true)

        r1 = processor.verifyCombosable("!")
        #expect(r1 == false)
    }

    @Test("ㄲ")
    func getComposedChar_ㄲ() {
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1100}")

        processor.rawChar = "k"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1101}")
    }

    @Test("ㄱㄴ")
    func getComposedChar_ㄱㄴ() {
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1100}")

        processor.rawChar = "h"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1102}")
    }

    @Test("ㄱㄱㄱ")
    func getComposedChar_ㄱㄱㄱ() {
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1100}")

        processor.rawChar = "k"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "ᄁ")

        processor.rawChar = "k"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.committed)
        let c3 = processor.getComposed()
        #expect(c3 == "\u{1100}")
    }

    @Test("ㄴㄷ")
    func getComposedChar_ㄴㄷ() {
        processor.rawChar = "h"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1102}")

        processor.rawChar = "u"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1103}")
    }

    @Test("ㄸ")
    func getComposedChar_ㄸ() {
        processor.rawChar = "u"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1103}")

        processor.rawChar = "u"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1104}")
    }

    @Test("ㅋㅋ")
    func getComposedChar_ㅋㅋ() {
        processor.rawChar = "."
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{110F}")

        processor.rawChar = "."
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{110F}")
    }

    @Test("ㅎㅎ")
    func getComposedChar_ㅎㅎ() {
        processor.rawChar = "m"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1112}")

        processor.rawChar = "m"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1112}")
    }

    @Test("ㅏ")
    func getComposedChar_ㅏ() {
        processor.rawChar = "f"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1161}")
    }

    @Test("ㅏᅡ")
    func getComposedChar_ㅏᅡ() {
        processor.rawChar = "f"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1161}")

        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1161}")
    }

    @Test("ㅏㅓ")
    func getComposedChar_ㅏㅓ() {
        processor.rawChar = "f"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1161}")

        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1165}")
    }

    @Test("ㅗㅏ")
    func getComposedChar_ㅗㅏ() {
        processor.rawChar = "v"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1169}")

        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1161}")
    }

    @Test("ㅜㅓ")
    func getComposedChar_ㅜㅓ() {
        processor.rawChar = "b"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{116E}")

        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1165}")
    }

    @Test("ㅡㅣ")
    func getComposedChar_ㅡㅣ() {
        processor.rawChar = "g"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1173}")

        processor.rawChar = "d"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{1175}")
    }

    @Test("아")
    func getComposedChar_아() {
        processor.rawChar = "f"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1161}")

        processor.rawChar = "j"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "아")
    }

    @Test("ㄱ")
    func getComposedChar_ㄱ() {
        processor.rawChar = "C"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{11A8}")
    }

    @Test("ㄴ")
    func getComposedChar_ㄴ() {
        processor.rawChar = "S"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{11AB}")
    }

    @Test("ㄺ")
    func getComposedChar_ㄺ() {
        processor.rawChar = "W"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{11AF}")

        processor.rawChar = "C"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "\u{11B0}")
    }

    @Test("ㅄ")
    func getComposedChar_ㅄ() {
        processor.rawChar = "S"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{11AB}")
    }

    @Test("가")
    func getComposedChar_가() {
        var r1 = processor.verifyCombosable("k")
        #expect(r1 == true)
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ᄀ")

        r1 = processor.verifyCombosable("f")
        #expect(r1 == true)
        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "가")
    }

    @Test("나")
    func getComposedChar_나() {
        var r1 = processor.verifyCombosable("h")
        #expect(r1 == true)
        processor.rawChar = "h"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ᄂ")

        r1 = processor.verifyCombosable("r")
        #expect(r1 == true)
        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "너")
    }

    @Test("까")
    func getComposedChar_까() {
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ᄀ")

        processor.rawChar = "k"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "ᄁ")

        processor.rawChar = "f"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "까")
    }

    @Test("으ᅵ")
    func getComposedChar_으ᅵ() {
        processor.rawChar = "j"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{110B}")

        processor.rawChar = "i"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "으")

        processor.rawChar = "d"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "의")
    }

    @Test("의")
    func getComposedChar_의() {
        processor.rawChar = "j"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{110B}")

        processor.rawChar = "z"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "의")
    }

    @Test("매")
    func getComposedChar_매() {
        processor.rawChar = "i"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1106}")

        processor.rawChar = "e"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "매")
    }

    @Test("노래")
    func getComposedChar_노래() {
        processor.rawChar = "h"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1102}")

        processor.rawChar = "v"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "노")

        processor.rawChar = "y"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.committed)
        let c3 = processor.getComposed()
        #expect(c3 == "\u{1105}")

        processor.rawChar = "e"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.composing)
        let c4 = processor.getComposed()
        #expect(c4 == "래")
    }

    @Test("뫄")
    func getComposedChar_뫄() {
        processor.rawChar = "i"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1106}")

        processor.rawChar = "p"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "모")

        processor.rawChar = "f"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "뫄")
    }

    @Test("취")
    func getComposedChar_위() {
        processor.rawChar = "o"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{110E}")

        processor.rawChar = "o"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "추")

        processor.rawChar = "d"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "취")
    }

    @Test("강")
    func getComposedChar_강() {
        var r1 = processor.verifyCombosable("k")
        #expect(r1 == true)
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ᄀ")

        r1 = processor.verifyCombosable("f")
        #expect(r1 == true)
        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "가")

        r1 = processor.verifyCombosable("a")
        #expect(r1 == true)
        processor.rawChar = "a"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "강")
    }

    @Test("공부")
    func getComposedChar_공부() {
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ᄀ")

        processor.rawChar = "v"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "고")

        processor.rawChar = "a"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "공")

        processor.rawChar = ";"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.committed)
        let c4 = processor.getComposed()
        #expect(c4 == "\u{1107}")

        processor.rawChar = "b"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.composing)
        let c5 = processor.getComposed()
        #expect(c5 == "부")
    }

    @Test("밖")
    func getComposedChar_밖() {
        // 밖 ;fcc
        var r1 = processor.verifyCombosable(";")
        #expect(r1 == true)
        processor.rawChar = ";"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1107}")

        r1 = processor.verifyCombosable("f")
        #expect(r1 == true)
        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "바")

        r1 = processor.verifyCombosable("c")
        #expect(r1 == true)
        processor.rawChar = "c"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "박")

        processor.rawChar = "c"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.composing)
        let c4 = processor.getComposed()
        #expect(c4 == "밖")
    }

    @Test("세상")
    func getComposedChar_세상() async throws {
        // ncnfa
        processor.rawChar = "n"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1109}")

        processor.rawChar = "c"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "세")

        processor.rawChar = "n"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.committed)
        let c3 = processor.getComposed()
        #expect(c3 == "\u{1109}")

        processor.rawChar = "f"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.composing)
        let c4 = processor.getComposed()
        #expect(c4 == "사")

        processor.rawChar = "a"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.composing)
        let c5 = processor.getComposed()
        #expect(c5 == "상")
    }

    @Test("서쪽")
    func getComposedChar_서쪽() async throws {
        // nrllvc
        processor.rawChar = "n"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1109}")

        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "서")

        processor.rawChar = "l"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.committed)
        let c3 = processor.getComposed()
        #expect(c3 == "\u{110C}")

        processor.rawChar = "l"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.composing)
        let c4 = processor.getComposed()
        #expect(c4 == "\u{110D}")

        processor.rawChar = "v"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.composing)
        let c5 = processor.getComposed()
        #expect(c5 == "쪼")

        processor.rawChar = "c"
        let s6 = processor.한글조합()
        #expect(s6 == CommitState.composing)
        let c6 = processor.getComposed()
        #expect(c6 == "쪽")
    }

    @Test("한때")
    func getComposedChar_한때() async throws {
        // mfsuue
        processor.rawChar = "m"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{1112}")

        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "하")

        processor.rawChar = "s"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "한")

        processor.rawChar = "u"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.committed)
        let c4 = processor.getComposed()
        #expect(c4 == "\u{1103}")

        processor.rawChar = "u"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.composing)
        let c5 = processor.getComposed()
        #expect(c5 == "\u{1104}")

        processor.rawChar = "e"
        let s6 = processor.한글조합()
        #expect(s6 == CommitState.composing)
        let c6 = processor.getComposed()
        #expect(c6 == "때")
    }

    @Test("없다")
    func getComposedChar_없다() async throws {
        // jreqjgz
        processor.rawChar = "j"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{110B}")

        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "어")

        processor.rawChar = "e"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "업")

        processor.rawChar = "q"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.composing)
        let c4 = processor.getComposed()
        #expect(c4 == "없")

        processor.rawChar = "u"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.committed)
        let c5 = processor.getComposed()
        #expect(c5 == "\u{1103}")

        processor.rawChar = "f"
        let s6 = processor.한글조합()
        #expect(s6 == CommitState.composing)
        let c6 = processor.getComposed()
        #expect(c6 == "다")
    }

    @Test("좋아")
    func getComposedChar_좋아() async throws {
        // jreqjgz
        processor.rawChar = "l"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "\u{110C}")

        processor.rawChar = "v"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "조")

        processor.rawChar = "d"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "좋")

        processor.rawChar = "j"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.committed)
        let c5 = processor.getComposed()
        #expect(c5 == "\u{110B}")

        processor.rawChar = "f"
        let s6 = processor.한글조합()
        #expect(s6 == CommitState.composing)
        let c6 = processor.getComposed()
        #expect(c6 == "아")
    }

    @Test("강_", .disabled())
    func getComposedChar_강_남() {
        //
    }

    @Test("강^H", .disabled())
    func getComposedChar_강백스페이스() {
        //
    }
}
