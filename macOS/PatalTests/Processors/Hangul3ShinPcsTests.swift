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
    let layout = createLayoutInstance(name: LayoutName.HAN3_SHIN_PCS)
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

    @Test("자판 특성")
    func availableTraits() {
        print(processor.hangulLayout.availableTraits)
        print(processor.hangulLayout.traits)
        #expect(processor.hangulLayout.traits.contains(LayoutTrait.화살표) == true)
        // #expect(processor.hangulLayout.traits.contains(LayoutTrait.모아치기) == true)
        #expect(processor.hangulLayout.traits.contains(LayoutTrait.글자단위삭제) == true)
    }

    @Test("쉬운 화살표")
    func 화살표() {
        processor.hangulLayout.traits.removeAll()

        processor.rawChar = "M"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.none)
        let c1 = processor.getConverted()
        #expect(c1 == ")")

        processor.rawChar = "N"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.none)
        let c2 = processor.getConverted()
        #expect(c2 == "(")

        processor.hangulLayout.traits = processor.hangulLayout.availableTraits

        processor.rawChar = "N"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.none)
        let c3 = processor.getConverted()
        #expect(c3 == "←")

        processor.rawChar = "M"
        let s4 = processor.한글조합()
        #expect(s4 == CommitState.none)
        let c4 = processor.getConverted()
        #expect(c4 == "→")
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
        processor.rawChar = "."
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅋ")

        processor.rawChar = "."
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "ㅋ")
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

    @Test("ㅏᅡ")
    func getComposedChar_ㅏᅡ() {
        processor.hangulLayout.traits.insert(LayoutTrait.모아치기)

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
    }

    @Test("ㅏㅓ")
    func getComposedChar_ㅏㅓ() {
        processor.hangulLayout.traits.insert(LayoutTrait.모아치기)

        processor.rawChar = "f"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅏ")

        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "�")
    }

    @Test("ㅗㅏ")
    func getComposedChar_ㅗㅏ() {
        processor.hangulLayout.traits.insert(LayoutTrait.모아치기)

        processor.rawChar = "v"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅗ")

        processor.rawChar = "f"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "�")
    }

    @Test("ㅜㅓ")
    func getComposedChar_ㅜㅓ() {
        processor.hangulLayout.traits.insert(LayoutTrait.모아치기)

        processor.rawChar = "b"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅜ")

        processor.rawChar = "r"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "�")
    }

    @Test("ㅡㅣ")
    func getComposedChar_ㅡㅣ() {
        processor.hangulLayout.traits.insert(LayoutTrait.모아치기)

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
    }

    @Test("ㅇㅡㅎ")
    func getComposedChar_ㅇ흐() {
        processor.hangulLayout.traits.removeAll()

        processor.rawChar = "A"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅇ")

        processor.rawChar = "m"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.committed)
        let c2 = processor.getComposed()
        #expect(c2 == "ㅎ")

        processor.rawChar = "g"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "흐")
    }

    @Test("ㅇㅡㅎ - 모아치기")
    func getComposedChar_으흥() {
        processor.hangulLayout.traits.insert(LayoutTrait.모아치기)

        processor.rawChar = "A"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅇ")

        processor.rawChar = "m"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "�")

        processor.rawChar = "g"
        let s3 = processor.한글조합()
        #expect(s3 == CommitState.composing)
        let c3 = processor.getComposed()
        #expect(c3 == "흥")
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
        processor.rawChar = "C"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄱ")
    }

    @Test("ㄴ")
    func getComposedChar_ㄴ() {
        processor.rawChar = "S"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄴ")
    }

    @Test("ㄺ")
    func getComposedChar_ㄺ() {
        processor.rawChar = "W"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄹ")

        processor.rawChar = "C"
        let s2 = processor.한글조합()
        #expect(s2 == CommitState.composing)
        let c2 = processor.getComposed()
        #expect(c2 == "ㄺ")
    }

    @Test("ㅄ")
    func getComposedChar_ㅄ() {
        processor.rawChar = "S"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㄴ")
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

    @Test("으ᅵ")
    func getComposedChar_으ᅵ() {
        processor.rawChar = "j"
        let s1 = processor.한글조합()
        #expect(s1 == CommitState.composing)
        let c1 = processor.getComposed()
        #expect(c1 == "ㅇ")

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
        #expect(c1 == "ㅇ")

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
        #expect(c1 == "ㅁ")

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
        #expect(c1 == "ㅁ")

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
        #expect(c1 == "ㅊ")

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
        #expect(c1 == "ㅇ")

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

    @Test("강_", .disabled())
    func getComposedChar_강_남() {
        //
    }

    @Test("강^H", .disabled())
    func getComposedChar_강백스페이스() {
        //
    }
}
