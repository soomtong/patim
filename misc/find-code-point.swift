func getCodePoint(_ char: Character) -> String {
    let scalar = String(char).unicodeScalars.first!
    return String(scalar.value, radix: 16, uppercase: true)
}

func printAllUnicodeInfo(_ text: String) {
    text.forEach { char in
        print("\nCharacter: \(char)")
        String(char).unicodeScalars.forEach { scalar in
            print("  Unicode: U+\(String(scalar.value, radix: 16, uppercase: true))")
            print("  Name: \(scalar.properties.name ?? "Unknown")")
            print("  Category: \(scalar.properties.generalCategory)")
            print("  Numeric Value: \(scalar.properties.numericValue ?? -1)")
            print("  Canonical Combining Class: \(scalar.properties.canonicalCombiningClass)")
        }
    }
}

//// 사용 예시
printAllUnicodeInfo("ᆞ가")
printAllUnicodeInfo("ᄀᆞᆼ")

var decomposed: Character = "\u{1112}\u{1161}\u{11AB}"  // ᄒ, ᅡ, ᆫ
print(decomposed)

decomposed = "\u{1112}\u{119E}\u{11AB}"
print(decomposed)

var unicodeScalars = String.UnicodeScalarView()
print(unicodeScalars.count)
unicodeScalars.append(UnicodeScalar("A"))
print(unicodeScalars.count)
unicodeScalars.append(UnicodeScalar("B"))
print(unicodeScalars.count)
// string is "AB"
