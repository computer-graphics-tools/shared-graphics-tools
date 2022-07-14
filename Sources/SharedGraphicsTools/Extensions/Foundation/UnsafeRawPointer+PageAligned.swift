import Foundation

public extension UnsafeRawPointer {
    var isPageAligned: Bool {
        Int(bitPattern: self) % Int(getpagesize()) == 0
    }
}

public extension UnsafeMutableRawPointer {
    var isPageAligned: Bool {
        Int(bitPattern: self) % Int(getpagesize()) == 0
    }
}
