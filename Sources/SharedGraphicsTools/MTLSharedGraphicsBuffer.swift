#if !targetEnvironment(simulator)

import Accelerate
import CoreVideoTools
import MetalTools

public final class MTLSharedGraphicsBuffer: NSObject {
    // MARK: - Type Definitions

    public enum Error: Swift.Error {
        case allocationFailed
        case cgContextCreationFailed
        case unsupportedPixelFormat
    }

    public enum PixelFormat: CaseIterable {
        case r8Unorm
        case r16Float
        case r32Float
        case bgra8Unorm
        case bgra8Unorm_srgb
        case rgba16Float
        case rgba32Float

        fileprivate var mtlPixelFormat: MTLPixelFormat {
            switch self {
            case .r8Unorm: return .r8Unorm
            case .r16Float: return .r16Float
            case .r32Float: return .r32Float
            case .bgra8Unorm: return .bgra8Unorm
            case .bgra8Unorm_srgb: return .bgra8Unorm_srgb
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

    public init(
        device: MTLDevice,
        width: Int,
        height: Int,
        pixelFormat: PixelFormat,
        forceColorSpace: CGColorSpace? = nil,
        usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .renderTarget]
    ) throws {
        let mtlPixelFormat = pixelFormat.mtlPixelFormat
        guard let rawCVPixelFormat = mtlPixelFormat.compatibleCVPixelFormat,
              let bytesPerPixel = mtlPixelFormat.bytesPerPixel,
              let bitsPerComponent = mtlPixelFormat.bitsPerComponent,
              let bitmapInfo = mtlPixelFormat.compatibleBitmapInfo,
              let colorSpace = forceColorSpace ?? mtlPixelFormat.compatibleColorSpace
        else { throw Error.unsupportedPixelFormat }
        let cvPixelFormat = CVPixelFormat(rawValue: rawCVPixelFormat)

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
            device.minimumTextureBufferAlignment(for: mtlPixelFormat),
            device.minimumLinearTextureAlignment(for: mtlPixelFormat)
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
            device.heapTextureSizeAndAlign(descriptor: textureDescriptor).size
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

        guard let buffer = device.makeBuffer(
            bytesNoCopy: allocationPointer,
            length: pageAlignedTextureSize,
            options: resourceOptions,
            deallocator: { _, _ in  }
        )
        else { throw MetalError.MTLDeviceError.bufferCreationFailed }

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
