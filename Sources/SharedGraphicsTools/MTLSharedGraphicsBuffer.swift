#if !targetEnvironment(simulator)

import Accelerate
import CoreVideoTools
import MetalTools

@available(iOS 12.0, macCatalyst 14.0, macOS 11.0, *)
public final class MTLSharedGraphicsBuffer: NSObject {
    // MARK: - Type Definitions

    public enum Error: Swift.Error {
        case allocationFailed
        case cgContextCreationFailed
        case unsupportedPixelFormat
    }

    public enum PixelFormat {
        case r8Unorm
        case r8Unorm_srgb
        case r16Float
        case r32Float
        case rg8Unorm
        case rg8Unorm_srgb
        case rg16Float
        case rg32Float
        case bgra8Unorm
        case bgra8Unorm_srgb
        case rgba8Unorm
        case rgba8Unorm_srgb
        case rgba16Float
        case rgba32Float

        fileprivate var mtlPixelFormat: MTLPixelFormat {
            switch self {
            case .r8Unorm: return .r8Unorm
            case .r8Unorm_srgb: return .r8Unorm_srgb
            case .r16Float: return .r16Float
            case .r32Float: return .r32Float
            case .rg8Unorm: return .rg8Unorm
            case .rg8Unorm_srgb: return .rg8Unorm_srgb
            case .rg16Float: return .rg16Float
            case .rg32Float: return .rg32Float
            case .bgra8Unorm: return .bgra8Unorm
            case .bgra8Unorm_srgb: return .bgra8Unorm_srgb
            case .rgba8Unorm: return .rgba8Unorm
            case .rgba8Unorm_srgb: return .rgba8Unorm_srgb
            case .rgba16Float: return .rgba16Float
            case .rgba32Float: return .rgba32Float
            }
        }
    }

    // MARK: - Internal Properties

    public let allocationPointer: UnsafeMutableRawPointer
    public let bytesPerRow: Int
    public let buffer: MTLBuffer
    public let texture: MTLTexture
    public let vImageBuffer: vImage_Buffer
    public let pixelBuffer: CVPixelBuffer
    public let cgContext: CGContext
    public let colorSpace: CGColorSpace

    public var width: Int { self.texture.width }
    public var height: Int { self.texture.height }
    public var usage: MTLTextureUsage { self.texture.usage }
    public var resourceOptions: MTLResourceOptions { self.texture.resourceOptions }
    public var mtlPixelFormat: MTLPixelFormat { self.texture.pixelFormat }
    public var cvPixelFormat: CVPixelFormat { self.pixelBuffer.cvPixelFormat }
    public var bitmapInfo: CGBitmapInfo { self.cgContext.bitmapInfo }
    public var alfaInfo: CGImageAlphaInfo { self.cgContext.alphaInfo }

    private let allocationAddress: UInt
    private let allocationSize: vm_size_t

    // MARK: - Init

    /// Shared graphics buffer.
    /// - Parameters:
    ///   - context: metal context.
    ///   - width: texture width.
    ///   - height: texture height.
    ///   - pixelFormat: texture pixel format.
    ///   - usage: texture usage.
    public init(
        context: MTLContext,
        width: Int,
        height: Int,
        pixelFormat: PixelFormat,
        forceColorSpace: CGColorSpace? = nil,
        usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .renderTarget]
    ) throws {
        let mtlPixelFormat = pixelFormat.mtlPixelFormat
        let cvPixelFormat = mtlPixelFormat.compatibleCVPixelFormat
        guard let bytesPerPixel = mtlPixelFormat.bytesPerPixel,
              let bitsPerComponent = mtlPixelFormat.bitsPerComponent,
              let bitmapInfo = mtlPixelFormat.compatibleBitmapInfo,
              let colorSpace = forceColorSpace ?? mtlPixelFormat.compatibleColorSpace
        else { throw Error.unsupportedPixelFormat }

        let resourceOptions: MTLResourceOptions = [.crossPlatformSharedOrManaged]
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = mtlPixelFormat
        textureDescriptor.usage = usage
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.resourceOptions = resourceOptions

        // MARK: - Calculate bytes per row.

        /// Minimum texture alignment.
        ///
        /// The minimum alignment required when creating a texture buffer from a buffer.
        let textureBufferAlignment = max(
            context.minimumTextureBufferAlignment(for: mtlPixelFormat),
            context.minimumLinearTextureAlignment(for: mtlPixelFormat)
        )

        var vImageBuffer = vImage_Buffer()

        /// Minimum vImage buffer alignment.
        ///
        /// Get the minimum data alignment required for buffer's contents,
        /// by passing `kvImageNoAllocate` to `vImage` constructor.
        let vImageBufferAlignment = vImageBuffer_Init(
            &vImageBuffer,
            vImagePixelCount(height),
            vImagePixelCount(width),
            UInt32(bitsPerComponent),
            vImage_Flags(kvImageNoAllocate)
        )

        /// Pixel row alignment.
        ///
        /// Choose the maximum of previosly calculated alignments.
        let pixelRowAlignment = max(textureBufferAlignment, vImageBufferAlignment)

        /// Bytes per row.
        ///
        /// Calculate bytes per row by aligning row size with previously calculated `pixelRowAlignment`.
        let bytesPerRow = alignUp(
            size: bytesPerPixel * width,
            align: pixelRowAlignment
        )

        // MARK: - Page align allocation pointer.

        let alloacationSize = max(
            bytesPerRow * height,
            context.heapTextureSizeAndAlign(descriptor: textureDescriptor).size
        )

        /// Current system's RAM page size.
        let pageSize = Int(getpagesize())

        /// Page aligned texture size.
        ///
        /// Get page aligned texture size.
        /// It might be more than raw texture size, but we'll alloccate memory in reserve.
        let pageAlignedTextureSize = alignUp(
            size: alloacationSize,
            align: pageSize
        )

        var allocationAddress: UInt = 0
        let allocationSize = vm_size_t(pageAlignedTextureSize)
        let status = vm_allocate(
            mach_task_self_,
            &allocationAddress,
            allocationSize,
            VM_FLAGS_ANYWHERE
        )

        guard status == KERN_SUCCESS,
              let allocationPointer = UnsafeMutableRawPointer(bitPattern: allocationAddress)
        else { throw Error.allocationFailed }

        vImageBuffer.rowBytes = bytesPerRow
        vImageBuffer.data = allocationPointer

        let buffer = try context.buffer(
            bytesNoCopy: allocationPointer,
            length: pageAlignedTextureSize,
            options: resourceOptions,
            deallocator: { _, _ in  }
        )

        guard let texture = buffer.makeTexture(
            descriptor: textureDescriptor,
            offset: 0,
            bytesPerRow: bytesPerRow
        )
        else { throw MetalError.MTLBufferError.textureCreationFailed }

        let pixelBuffer = try CVPixelBuffer.create(
            width: width,
            height: height,
            cvPixelFormat: cvPixelFormat,
            baseAddress: allocationPointer,
            bytesPerRow: bytesPerRow,
            pixelBufferAttributes: [
                .cGImageCompatibility: true,
                .cGBitmapContextCompatibility: true,
                .metalCompatibility: true
            ]
        )

        guard let cgContext = CGContext(
            data: allocationPointer,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
        else { throw Error.cgContextCreationFailed }

        self.allocationPointer = allocationPointer
        self.allocationAddress = allocationAddress
        self.allocationSize = allocationSize
        self.bytesPerRow = bytesPerRow
        self.buffer = buffer
        self.texture = texture
        self.vImageBuffer = vImageBuffer
        self.pixelBuffer = pixelBuffer
        self.cgContext = cgContext
        self.colorSpace = colorSpace
    }

    deinit {
        vm_deallocate(mach_task_self_, self.allocationAddress, self.allocationSize)
    }
}

#endif
