//
//  Test.swift
//  PatalTests
//
//  Created by dp on 12/26/24.
//

import InputMethodKit
import Testing

@testable import Patal

@Suite("Input Controller Tests", .serialized, .disabled())
struct InputControllerTests {
    var inputController: InputController!
    var mockClient: MockIMKClient!
    var mockServer: MockIMKServer!

    init() {
        mockServer = MockIMKServer(name: "MockServer", bundleIdentifier: "com.example.MockServer")
        mockClient = MockIMKClient()
        inputController = InputController(server: mockServer, delegate: nil, client: mockClient)
    }

    @Test("Activate Server")
    func testActivateServer() {
        inputController.activateServer(nil)
        // Add assertions to verify the server activation if needed
    }

    @Test("Deactivate Server")
    func testDeactivateServer() {
        inputController.deactivateServer(nil)
        // Add assertions to verify the server deactivation if needed
    }

    @Test("Input Text - Processable Character")
    func testInputTextProcessable() {
        let result = inputController.inputText("k", client: mockClient)
        #expect(result == true)
        // Add assertions to verify the behavior when a processable character is input
    }

    @Test("Input Text - Non-Processable Character")
    func testInputTextNonProcessable() {
        let result = inputController.inputText("!", client: mockClient)
        #expect(result == false)
        // Add assertions to verify the behavior when a non-processable character is input
    }

    @Test("Commit Composition")
    func testCommitComposition() {
        inputController.commitComposition(nil)
        // Add assertions to verify the behavior when committing composition
    }

    // Add more tests as needed to cover other functionalities of InputController
}

// Mock class for IMKTextInput
class MockIMKClient: IMKInputController {
    func insertText(_ string: Any, replacementRange: NSRange) {}
    func setMarkedText(_ string: Any, selectionRange: NSRange, replacementRange: NSRange) {}
    func unmarkText() {}
    func selectedRange() -> NSRange { return NSRange(location: 0, length: 0) }
    func markedRange() -> NSRange { return NSRange(location: 0, length: 0) }
    func hasMarkedText() -> Bool { return false }
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?)
        -> NSAttributedString?
    { return nil }
    func validAttributesForMarkedText() -> [NSAttributedString.Key] { return [] }
    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        return NSRect.zero
    }
    func characterIndex(for point: NSPoint) -> Int { return 0 }
    func attributedString() -> NSAttributedString? { return nil }
    func baselineDelta() -> CGFloat { return 0.0 }
    func windowLevel() -> Int { return 0 }
    func supportsUnicode() -> Bool { return true }
    func string() -> String { return "" }
    func length() -> Int { return 0 }
    func substring(from: Int, length: Int) -> String { return "" }
    func substringWithRange(_ range: NSRange) -> String { return "" }
    func markedText() -> NSAttributedString? { return nil }
}

// Mock class for IMKServer
class MockIMKServer: IMKServer {
    override init!(name: String!, bundleIdentifier: String!) {
        super.init(name: name, bundleIdentifier: bundleIdentifier)
    }
}
