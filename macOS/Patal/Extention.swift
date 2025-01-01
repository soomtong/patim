//
//  Extention.swift
//  Patal
//
//  Created by dp on 12/22/24.
//

import Foundation

extension NSRange {
    static var notFoundRange: NSRange {
        NSRange(location: NSNotFound, length: NSNotFound)
    }
    static var defaultRange: NSRange {
        NSRange(location: NSNotFound, length: 0)
    }
}
