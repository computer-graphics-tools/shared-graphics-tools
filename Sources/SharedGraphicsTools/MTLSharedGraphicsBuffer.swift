import Accelerate
import MetalTools
import CoreVideoTools

@available(iOS 12.0, macCatalyst 14.0, macOS 11.0, *)
final public class MTLSharedGraphicsBuffer: NSObject {

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
    public let vImageBuffer: vImage_Buffer
    public let mtlPixelFormat: MTLPixelFormat
    public let cvPixelFormat: CVPixelFormat
    public let baseAddress: UnsafeMutableRawPointer
    public let bytesPerRow: Int
    public var width: Int { self.texture.width }
    public var height: Int { self.texture.height }
    public var label: String?

    // MARK: - Init
    
    /// Shared graphics buffer.
    /// - Parameters:
    ///   - context: metal context.
    ///   - width: texture width.
    ///   - height: texture height.
    ///   - pixelFormat: texture pixel format.
    ///   - storageMode: texture storage mode.
    ///   - usage: texture usage.
    public init(
        context: MTLContext,
        width: Int,
        height: Int,
        pixelFormat: PixelFormat,
        storageMode: MTLStorageMode,
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
        textureDescriptor.storageMode = storageMode
        switch storageMode {
        case .shared: bufferStorageMode = .storageModeShared
        case .private: bufferStorageMode = .storageModePrivate
        case .memoryless: bufferStorageMode = .storageModeMemoryless
        #if os(macOS) || targetEnvironment(macCatalyst)
        case .managed: bufferStorageMode = .storageModeManaged
        #endif
        @unknown default: bufferStorageMode = .storageModeShared
        }

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

        var optionalAllocationPointer: UnsafeMutableRawPointer?
        
        /// Allocate `pageAlignedTextureSize` bytes and place the
        /// address of the allocated memory in `self.allocationPointer`.
        /// The address of the allocated memory will be a multiple of `pageSize` which is hardware friendly.
        posix_memalign(
            &optionalAllocationPointer,
            pageSize,
            pageAlignedTextureSize
        )
        
        guard let allocationPointer = optionalAllocationPointer
        else { throw Error.initializationFailed }

        // MARK: - Calculate bytes per row.
        /// Minimum texture alignment.
        ///
        /// The minimum alignment required when creating a texture buffer from a buffer.
        let textureBufferAlignment = context.minimumTextureBufferAlignment(for: pixelFormat)

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

        let rowSize = pixelFormatSize * width

        /// Bytes per row.
        ///
        /// Calculate bytes per row by aligning row size with previously calculated `pixelRowAlignment`.
        let bytesPerRow = alignUp(size: rowSize,
                                  align: pixelRowAlignment)
        
        vImageBuffer.rowBytes = bytesPerRow
        vImageBuffer.data = allocationPointer

        guard let buffer = context.buffer(
            bytesNoCopy: allocationPointer,
            length: pageAlignedTextureSize,
            options: bufferStorageMode,
            deallocator: { pointer, _ in pointer.deallocate() }
        ), let texture = buffer.makeTexture(
            descriptor: textureDescriptor,
            offset: 0,
            bytesPerRow: bytesPerRow
        )
        else { throw Error.initializationFailed }
        
        self.pixelBuffer = try .create(
            width: width,
            height: height,
            cvPixelFormat: cvPixelFormat,
            baseAddress: allocationPointer,
            bytesPerRow: bytesPerRow,
            releaseCallback: nil,
            releaseRefCon: nil,
            pixelBufferAttributes: [
                .cGImageCompatibility: true,
                .cGBitmapContextCompatibility: true,
                .metalCompatibility: true
            ],
            allocator: nil
        )
        
        self.baseAddress = allocationPointer
        self.bytesPerRow = bytesPerRow
        self.vImageBuffer = vImageBuffer
        self.buffer = buffer
        self.texture = texture
        self.mtlPixelFormat = pixelFormat
        self.cvPixelFormat = cvPixelFormat
    }
}

@available(iOS 13.0, *)
extension MTLSharedGraphicsBuffer: MTLResource {
    public var device: MTLDevice { self.texture.device }
    public var cpuCacheMode: MTLCPUCacheMode { self.texture.cpuCacheMode }
    public var storageMode: MTLStorageMode { self.texture.storageMode }
    public var hazardTrackingMode: MTLHazardTrackingMode { self.texture.hazardTrackingMode }
    public var resourceOptions: MTLResourceOptions { self.texture.resourceOptions }
    public var heap: MTLHeap? { self.texture.heap }
    public var heapOffset: Int { self.texture.heapOffset }
    public var allocatedSize: Int { self.texture.allocatedSize }
    public func makeAliasable() { self.texture.makeAliasable() }
    public func isAliasable() -> Bool { self.texture.isAliasable() }
    public func setPurgeableState(_ state: MTLPurgeableState) -> MTLPurgeableState { self.texture.setPurgeableState(state) }
}
