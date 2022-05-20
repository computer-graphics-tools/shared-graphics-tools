import MetalTools

extension MTLPixelFormat {

    var bitsPerPixel: Int? {
        if self.isOrdinary8Bit {
            return 8
        } else if self.isOrdinary16Bit || self.isPacked16Bit {
            return 16
        } else if self.isOrdinary32Bit || self.isPacked32Bit  {
            return 32
        } else if self.isNormal64Bit  {
            return 64
        } else if self.isNormal128Bit {
            return 128
        }
        return nil
    }

    var bitsPerComponent: Int? {
        guard let bitsPerPixel = self.bitsPerPixel,
              let componentCount = self.componentCount
        else { return nil }
        return bitsPerPixel / componentCount
    }

    var componentCount: Int? {
        switch self {
        case .a8Unorm, .r8Unorm, .r8Unorm_srgb, .r8Snorm,
             .r8Uint, .r8Sint, .r16Unorm, .r16Snorm,
             .r16Uint, .r16Sint, .r16Float, .r32Uint,
             .r32Sint, .r32Float, .depth16Unorm, .stencil8,
             .depth32Float:
            return 1
        case .rg8Unorm, .rg8Unorm_srgb, .rg8Snorm, .rg8Uint,
             .rg8Sint, .rg16Unorm, .rg16Snorm, .rg16Uint,
             .rg16Sint, .rg16Float, .rg32Uint, .rg32Sint,
             .rg32Float, .depth32Float_stencil8:
            return 2
        case .b5g6r5Unorm, .rg11b10Float, .rgb9e5Float, .bgr10_xr,
             .bgr10_xr_srgb:
            return 3
        case .a1bgr5Unorm, .abgr4Unorm, .bgr5A1Unorm, .rgba8Unorm,
             .rgba8Unorm_srgb, .rgba8Snorm, .rgba8Uint, .rgba8Sint,
             .bgra8Unorm, .bgra8Unorm_srgb, .rgb10a2Unorm, .rgb10a2Uint,
             .bgr10a2Unorm, .rgba16Unorm, .rgba16Snorm, .rgba16Uint,
             .rgba16Sint, .rgba16Float, .bgra10_xr, .bgra10_xr_srgb,
             .rgba32Uint, .rgba32Sint, .rgba32Float:
            return 4
        default:
            return nil
        }
    }

}
