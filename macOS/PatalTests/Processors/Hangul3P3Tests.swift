//
//  Hangul3P2Tests.swift
//  PatalTests
//
//  Created by dp on 12/25/24.
//

import Testing

@testable import Patal

@Suite("공세벌 P 자판 테스트", .serialized)
struct Hangul3P3Tests {
    let layout = createLayoutInstance(name: LayoutName.HAN3_P3)
    var processor: HangulProcessor!

    init() {
        processor = HangulProcessor(layout: layout)
        processor.hangulLayout.traits = layout.availableTraits
    }

    @Test("유효한 문자만 받기")
    func setKey() {
        var r1 = processor.verifyCombosable("i")
        #expect(r1 == true)

        r1 = processor.verifyCombosable("!")
        #expect(r1 == false)
    }

    @Test("세줄숫자")
    func getComposedChar_세줄숫자() {
        processor.hangulLayout.traits.removeAll()

        processor.rawChar = "N"
        let s0 = processor.한글조합()
        #expect(s0 == CommitState.none)
        let c0 = processor.getComposed()
        #expect(c0 == nil)
        let d0 = processor.getConverted()
        #expect(d0 == "0")

        processor.rawChar = "M"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.none)
        let c1 = processor.getComposed()
        #expect(c1 == nil)
        let d1 = processor.getConverted()
        #expect(d1 == "1")

        processor.rawChar = "O"
        let s9 = processor.한글조합()
        #expect(s9 == CommitState.none)
        let c9 = processor.getComposed()
        #expect(c9 == nil)
        let d9 = processor.getConverted()
        #expect(d9 == "9")
    }

    @Test("두줄숫자")
    func getComposedChar_두줄숫자() {
        processor.hangulLayout.traits.insert(LayoutTrait.두줄숫자)

        processor.rawChar = "H"
        let s0 = processor.한글조합()
        #expect(s0 == CommitState.none)
        let c0 = processor.getComposed()
        #expect(c0 == nil)
        let d0 = processor.getConverted()
        #expect(d0 == "0")

        processor.rawChar = "J"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.none)
        let c1 = processor.getComposed()
        #expect(c1 == nil)
        let d1 = processor.getConverted()
        #expect(d1 == "1")

        processor.rawChar = "P"
        let s9 = processor.한글조합()
        #expect(s9 == CommitState.none)
        let c9 = processor.getComposed()
        #expect(c9 == nil)
        let d9 = processor.getConverted()
        #expect(d9 == "9")
    }

    @Test("느슨한조합")
    func availableTraits() {
        print(processor.hangulLayout.availableTraits)
        print(processor.hangulLayout.traits)
        #expect(processor.hangulLayout.traits.contains(LayoutTrait.모아주기) == true)
    }

    @Test("ㄲ")
    func getComposedChar_ㄲ() {
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄱ")

        processor.rawChar = "k"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "ㄲ")
    }

    @Test("ㄱㄴ")
    func getComposedChar_ㄱㄴ() {
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄱ")

        processor.rawChar = "h"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "ㄴ")
    }

    @Test("ㄱㄱㄱ")
    func getComposedChar_ㄱㄱㄱ() {
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄱ")

        processor.rawChar = "k"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "ㄲ")

        processor.rawChar = "k"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.committed)
        let c3 = processor.getComposed()
        #expect(c3 == "ㄱ")
    }

    @Test("ㄴㄷ")
    func getComposedChar_ㄴㄷ() {
        processor.rawChar = "h"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄴ")

        processor.rawChar = "u"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "ㄷ")
    }

    @Test("ㄸ")
    func getComposedChar_ㄸ() {
        processor.rawChar = "u"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄷ")

        processor.rawChar = "u"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "ㄸ")
    }

    @Test("ㅋㅋ")
    func getComposedChar_ㅋㅋ() {
        processor.rawChar = "0"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅋ")

        processor.rawChar = "/"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "코")
    }

    @Test("ㅎㅎ")
    func getComposedChar_ㅎㅎ() {
        processor.rawChar = "m"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅎ")

        processor.rawChar = "m"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "ㅎ")
    }

    @Test("ㅏ")
    func getComposedChar_ㅏ() {
        processor.rawChar = "f"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅏ")
    }

    @Test("ㅏㅍ")
    func getComposedChar_ㅏㅍ() {
        processor.rawChar = "f"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅏ")

        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "�")
        // 중성과 종성이 조합 중인 상태
        let e2 = processor.composing.count
        #expect(e2 == 1)
    }

    @Test("ㅏㅌ")
    func getComposedChar_ㅏㅌ() {
        processor.rawChar = "f"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅏ")

        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        // 중성과 종성이 조합 중인 상태
        let e2 = processor.composing.count
        #expect(e2 == 1)
    }

    @Test("ㅗᄒ")
    func getComposedChar_ㅗᄒ() {
        processor.rawChar = "/"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅗ")

        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        #expect(processor.preedit.chosung == nil)
        #expect(processor.preedit.jungsung?.rawValue == 0x1169)
        #expect(processor.preedit.jongsung?.rawValue == 0x11C1)
    }

    @Test("ㅜᄎ")
    func getComposedChar_ㅜᄎ() {
        processor.rawChar = "9"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅜ")

        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        #expect(processor.preedit.chosung == nil)
        #expect(processor.preedit.jungsung?.rawValue == 0x116E)
        #expect(processor.preedit.jongsung?.rawValue == 0x11BE)
    }

    @Test("ㅡᄒ")
    func getComposedChar_ㅡᄒ() {
        processor.rawChar = "g"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅡ")

        processor.rawChar = "d"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "�")
        #expect(processor.preedit.chosung == nil)
        #expect(processor.preedit.jungsung?.rawValue == 0x1173)
        #expect(processor.preedit.jongsung?.rawValue == 0x11C2)
    }

    @Test("아")
    func getComposedChar_아() {
        processor.rawChar = "f"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅏ")

        processor.rawChar = "j"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "아")
    }

    @Test("ㄱ")
    func getComposedChar_ㄱ() {
        processor.rawChar = "x"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄱ")
    }

    @Test("ㄴ")
    func getComposedChar_ㄴ() {
        processor.rawChar = "s"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄴ")
    }

    @Test("ㄺ")
    func getComposedChar_ㄺ() {
        processor.rawChar = "w"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄹ")

        processor.rawChar = "x"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "ㄺ")
    }

    @Test("ㅄ")
    func getComposedChar_ㅄ() {
        processor.rawChar = "A"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅄ")
    }

    @Test("가")
    func getComposedChar_가() {
        var r1 = processor.verifyCombosable("k")
        #expect(r1 == true)
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄱ")

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
        #expect(c1 == "ㄴ")

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
        #expect(c1 == "ㄱ")

        processor.rawChar = "k"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "ㄲ")

        processor.rawChar = "f"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "까")
    }

    @Test("의")
    func getComposedChar_의() {
        processor.rawChar = "j"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅇ")

        processor.rawChar = "8"
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

    @Test("매")
    func getComposedChar_매() {
        processor.rawChar = "i"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅁ")

        processor.rawChar = "t"
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
        #expect(c1 == "ㄴ")

        processor.rawChar = "v"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "노")

        processor.rawChar = "y"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.committed)
        let c3 = processor.getComposed()
        #expect(c3 == "ㄹ")

        processor.rawChar = "t"
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
        #expect(c1 == "ㅁ")

        processor.rawChar = "/"
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
        #expect(c1 == "ㅊ")

        processor.rawChar = "9"
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
        #expect(c1 == "ㄱ")

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
        #expect(c1 == "ㄱ")

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
        #expect(c4 == "ㅂ")

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
        #expect(c1 == "ㅂ")

        r1 = processor.verifyCombosable("f")
        #expect(r1 == true)
        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "바")

        r1 = processor.verifyCombosable("x")
        #expect(r1 == true)
        processor.rawChar = "x"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "박")

        processor.rawChar = "x"
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
        #expect(c1 == "ㅅ")

        processor.rawChar = "c"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "세")

        processor.rawChar = "n"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.committed)
        let c3 = processor.getComposed()
        #expect(c3 == "ㅅ")

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
        #expect(c1 == "ㅅ")

        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "서")

        processor.rawChar = "l"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.committed)
        let c3 = processor.getComposed()
        #expect(c3 == "ㅈ")

        processor.rawChar = "l"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.composing)
        let c4 = processor.getComposed()
        #expect(c4 == "ㅉ")

        processor.rawChar = "v"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.composing)
        let c5 = processor.getComposed()
        #expect(c5 == "쪼")

        processor.rawChar = "x"
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
        #expect(c1 == "ㅎ")

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
        #expect(c4 == "ㄷ")

        processor.rawChar = "u"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.composing)
        let c5 = processor.getComposed()
        #expect(c5 == "ㄸ")

        processor.rawChar = "t"
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
        #expect(c1 == "ㅇ")

        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "어")

        processor.rawChar = "A"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "없")

        processor.rawChar = "u"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.committed)
        let c5 = processor.getComposed()
        #expect(c5 == "ㄷ")

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
        #expect(c1 == "ㅈ")

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
        #expect(c5 == "ㅇ")

        processor.rawChar = "f"
        let s6 = processor.한글조합()
        #expect(s6 == CommitState.composing)
        let c6 = processor.getComposed()
        #expect(c6 == "아")
    }

    @Test("가←네")
    func getComposedChar_가백스페이스네() {
        var r1 = processor.verifyCombosable("k")
        #expect(r1 == true)
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄱ")

        r1 = processor.verifyCombosable("f")
        #expect(r1 == true)
        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "가")

        let countComposable = processor.applyBackspace()
        #expect(countComposable == 1)
        #expect(processor.composing == ["k"])

        processor.rawChar = "h"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.committed)
        let c3 = processor.getComposed()
        #expect(c3 == "ㄴ")

        processor.rawChar = "c"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.composing)
        let c4 = processor.getComposed()
        #expect(c4 == "네")
    }
    @Test("한←글")
    func getComposedChar_한백스페이스백스페이스네() {
        var r = processor.verifyCombosable("m")
        #expect(r == true)
        processor.rawChar = "m"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅎ")

        r = processor.verifyCombosable("f")
        #expect(r == true)
        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "하")

        r = processor.verifyCombosable("s")
        #expect(r == true)
        processor.rawChar = "s"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "한")

        var countComposable = processor.applyBackspace()
        #expect(countComposable == 2)
        #expect(processor.composing == ["f"])

        countComposable = processor.applyBackspace()
        #expect(countComposable == 1)
        #expect(processor.composing == ["m"])

        processor.rawChar = "u"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.committed)
        let c4 = processor.getComposed()
        #expect(c4 == "ㄷ")

        processor.rawChar = "f"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.composing)
        let c5 = processor.getComposed()
        #expect(c5 == "다")
    }
    @Test("인←사")
    func getComposedChar_인백스페이스사() {
        processor.rawChar = "j"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅇ")

        processor.rawChar = "d"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "이")

        processor.rawChar = "s"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "인")

        var countComposable = processor.applyBackspace()
        #expect(countComposable == 2)
        #expect(processor.composing == ["d"])

        countComposable = processor.applyBackspace()
        #expect(countComposable == 1)
        #expect(processor.composing == ["j"])

        processor.rawChar = "n"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.committed)
        let c4 = processor.getComposed()
        #expect(c4 == "ㅅ")

        processor.rawChar = "f"
        let s5 = processor.한글조합()
        #expect(s5 == CommitState.composing)
        let c5 = processor.getComposed()
        #expect(c5 == "사")
    }

    @Test("ㄱ+종성ㄴ - 모아주기 비활성")
    func getComposedChar_초성종성_모아주기비활성() {
        processor.hangulLayout.traits.remove(LayoutTrait.모아주기)

        // 초성 ㄱ (k)
        processor.rawChar = "k"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        #expect(processor.getComposed() == "ㄱ")

        // 종성 ㄴ (s) → ㄱ 커밋, 새 초성 ㄴ
        processor.rawChar = "s"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        #expect(processor.완성 == "ㄱ")
        #expect(processor.getComposed() == "ㄴ")
    }

    @Test("ㄴ+종성ㄹ - 모아주기 비활성")
    func getComposedChar_초성종성_ㄴㄹ_모아주기비활성() {
        processor.hangulLayout.traits.remove(LayoutTrait.모아주기)

        // 초성 ㄴ (h)
        processor.rawChar = "h"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        #expect(processor.getComposed() == "ㄴ")

        // 종성 ㄹ (w) → ㄴ 커밋, 새 초성 ㄹ
        processor.rawChar = "w"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        #expect(processor.완성 == "ㄴ")
        #expect(processor.getComposed() == "ㄹ")
    }

    @Test("ㅎ+종성ㄱ - 모아주기 비활성")
    func getComposedChar_초성종성_ㅎㄱ_모아주기비활성() {
        processor.hangulLayout.traits.remove(LayoutTrait.모아주기)

        // 초성 ㅎ (m)
        processor.rawChar = "m"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        #expect(processor.getComposed() == "ㅎ")

        // 종성 ㄱ (x) → ㅎ 커밋, 새 초성 ㄱ
        processor.rawChar = "x"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        #expect(processor.완성 == "ㅎ")
        #expect(processor.getComposed() == "ㄱ")
    }
}
