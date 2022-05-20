import Accelerate
import MetalTools
import CoreVideoTools

@available(iOS 12.0, macCatalyst 14.0, macOS 11.0, *)
final public class MTLSharedGraphicsBuffer {
    
    // MARK: - Type Definitions

    public enum Error: Swift.Error {
        case initializationFailed
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
        case depth32Float
        
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
            case .depth32Float: return .depth32Float
            }
        }
    }
    
    // MARK: - Internal Properties

    public let texture: MTLTexture
    public let pixelBuffer: CVPixelBuffer
    public let buffer: MTLBuffer
    public private(set) var vImageBuffer: vImage_Buffer
    public let mtlPixelFormat: MTLPixelFormat
    public let cvPixelFormat: CVPixelFormat
    private var allocationPointer: UnsafeMutableRawPointer?
    
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
        usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .renderTarget]
    ) throws {
        let pixelFormat = pixelFormat.mtlPixelFormat
        guard let pixelFormatSize = pixelFormat.size,
              let bitsPerComponent = pixelFormat.bitsPerComponent
        else { throw Error.unsupportedPixelFormat }
        
        let cvPixelFormat = pixelFormat.compatibleCVPixelFormat

        let textureDescriptor = MTLTextureDescriptor()
        let bufferStorageMode: MTLResourceOptions
        textureDescriptor.pixelFormat = pixelFormat
        textureDescriptor.usage = usage
        textureDescriptor.width = width
        textureDescriptor.height = height
        #if os(iOS) && !targetEnvironment(macCatalyst)
        textureDescriptor.storageMode = .shared
        bufferStorageMode = .storageModeShared
        #elseif os(macOS) || targetEnvironment(macCatalyst)
        textureDescriptor.storageMode = .managed
        bufferStorageMode = .storageModeManaged
        #endif

        // MARK: - Page align allocation pointer.
        
        /// The size of heap texture created from MTLBuffer.
        let heapTextureSizeAndAlign = context.heapTextureSizeAndAlign(descriptor: textureDescriptor)

        /// Current system's RAM page size.
        let pageSize = Int(getpagesize())

        /// Page aligned texture size.
        ///
        /// Get page aligned texture size.
        /// It might be more than raw texture size, but we'll alloccate memory in reserve.
        let pageAlignedTextureSize = alignUp(
            size: heapTextureSizeAndAlign.size,
            align: pageSize
        )

        /// Allocate `pageAlignedTextureSize` bytes and place the
        /// address of the allocated memory in `self.allocationPointer`.
        /// The address of the allocated memory will be a multiple of `pageSize` which is hardware friendly.
        posix_memalign(
            &self.allocationPointer,
            pageSize,
            heapTextureSizeAndAlign.size
        )

        // MARK: - Calculate bytes per row.
        /// Minimum texture alignment.
        ///
        /// The minimum alignment required when creating a texture buffer from a buffer.
        let textureBufferAlignment = context.minimumTextureBufferAlignment(for: pixelFormat)

        self.vImageBuffer = vImage_Buffer()

        /// Minimum vImage buffer alignment.
        ///
        /// Get the minimum data alignment required for buffer's contents,
        /// by passing `kvImageNoAllocate` to `vImage` constructor.
        let vImageBufferAlignment = vImageBuffer_Init(
            &self.vImageBuffer,
            vImagePixelCount(height),
            vImagePixelCount(width),
            UInt32(bitsPerComponent),
            vImage_Flags(kvImageNoAllocate)
        )

        /// Pixel row alignment.
        ///
        /// Choose the maximum of previosly calculated alignments.
        guard let pixelRowAlignment = [textureBufferAlignment, vImageBufferAlignment].max(),
              let allocationPointer = self.allocationPointer
        else { throw Error.initializationFailed }

        let rowSize = pixelFormatSize * width

        /// Bytes per row.
        ///
        /// Calculate bytes per row by aligning row size with previously calculated `pixelRowAlignment`.
        let bytesPerRow = alignUp(size: rowSize,
                                  align: pixelRowAlignment)

        let pixelBufferAttributes = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ] as CFDictionary

        var trialPixelBuffer: CVPixelBuffer?
        guard let buffer = context.buffer(
            bytesNoCopy: allocationPointer,
            length: pageAlignedTextureSize,
            options: bufferStorageMode,
            deallocator: nil
        ), let texture = buffer.makeTexture(
            descriptor: textureDescriptor,
            offset: 0,
            bytesPerRow: bytesPerRow
        ), kCVReturnSuccess == CVPixelBufferCreateWithBytes(
            nil,
            width,
            height,
            cvPixelFormat.rawValue,
            allocationPointer,
            bytesPerRow,
            nil, nil,
            pixelBufferAttributes,
            &trialPixelBuffer
        ), let pixelBuffer = trialPixelBuffer
        else { throw Error.initializationFailed }

        self.vImageBuffer.rowBytes = bytesPerRow
        self.vImageBuffer.data = self.allocationPointer
        self.buffer = buffer
        self.texture = texture
        self.pixelBuffer = pixelBuffer
        self.mtlPixelFormat = pixelFormat
        self.cvPixelFormat = cvPixelFormat
    }
}
