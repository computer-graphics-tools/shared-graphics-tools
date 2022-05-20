import Metal
import CoreVideoTools

public extension CVPixelFormat {
    
    var compatibleMTLPixelFormat: MTLPixelFormat? {
        switch self {
        case .type_OneComponent8: return .r8Unorm
        case .type_OneComponent16Half: return .r16Float
        case .type_OneComponent32Float: return .r32Float
            
        case .type_TwoComponent8: return .rg8Unorm
        case .type_TwoComponent16Half: return .rg16Float
        case .type_TwoComponent32Float: return .rg32Float
            
        case .type_32BGRA: return .bgra8Unorm
        case .type_32RGBA: return .rgba8Unorm
        case .type_64RGBAHalf: return .rgba16Float
        case .type_128RGBAFloat: return .rgba32Float
            
        case .type_DepthFloat32: return .depth32Float
        default: return nil
        }
    }
    
}
