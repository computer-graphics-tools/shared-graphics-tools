import CoreML

public extension MLMultiArrayDataType {
    var size: Int {
        switch self {
        case .double: return MemoryLayout<Double>.size
        case .float64: return MemoryLayout<Float64>.size
        case .float32: return MemoryLayout<Float32>.size
        case .float16: return MemoryLayout<UInt16>.size
        case .float: return MemoryLayout<Float>.size
        case .int32: return MemoryLayout<Int32>.size
        @unknown default: return 0
        }
    }
    var stride: Int {
        switch self {
        case .double: return MemoryLayout<Double>.stride
        case .float64: return MemoryLayout<Float64>.stride
        case .float32: return MemoryLayout<Float32>.stride
        case .float16: return MemoryLayout<UInt16>.stride
        case .float: return MemoryLayout<Float>.stride
        case .int32: return MemoryLayout<Int32>.stride
        @unknown default: return 0
        }
    }
}
