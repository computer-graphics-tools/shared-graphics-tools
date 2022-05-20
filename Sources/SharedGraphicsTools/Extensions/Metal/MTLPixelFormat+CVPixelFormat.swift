import MetalTools
import CoreVideoTools

public extension MTLPixelFormat {

    var compatibleCVPixelFormat: CVPixelFormat {
        switch self {
        case .r8Unorm, .r8Unorm_srgb: return .type_OneComponent8
        case .r16Float: return .type_OneComponent16Half
        case .r32Float: return .type_OneComponent32Float

        case .rg8Unorm, .rg8Unorm_srgb: return .type_TwoComponent8
        case .rg16Float: return .type_TwoComponent16Half
        case .rg32Float: return .type_TwoComponent32Float

        case .bgra8Unorm, .bgra8Unorm_srgb: return .type_32BGRA
        case .rgba8Unorm, .rgba8Unorm_srgb: return .type_32RGBA
        case .rgba16Float: return .type_64RGBAHalf
        case .rgba32Float: return .type_128RGBAFloat

        case .depth32Float: return .type_DepthFloat32
        default: return .unknown
        }
    }

}
