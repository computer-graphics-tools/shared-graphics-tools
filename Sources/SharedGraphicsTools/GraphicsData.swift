import CoreVideoTools
import MetalTools
import Accelerate
import CoreML

public struct GraphicsData {
    
    public enum Error: Swift.Error {
        case outOfBounds
    }
    
    public let width: UInt
    public let height: UInt
    public let baseAddress: UnsafeMutableRawPointer
    public let bytesPerRow: UInt
    public var dataLength: UInt { self.bytesPerRow * self.height }
    
    public func vImageBufferView() -> vImage_Buffer {
        return .init(
            data: self.baseAddress,
            height: vImagePixelCount(self.height),
            width: vImagePixelCount(self.width),
            rowBytes: Int(self.bytesPerRow)
        )
    }
    
    public func cvPixelBufferView(cvPixelFormat: CVPixelFormat) throws -> CVPixelBuffer {
        return try .create(
            width: Int(self.width),
            height: Int(self.height),
            cvPixelFormat: cvPixelFormat,
            baseAddress: self.baseAddress,
            bytesPerRow: Int(self.bytesPerRow)
        )
    }
    
    #if arch(arm64)
    @available(iOS 14.0, macCatalyst 14.0, *)
    public func mlMultiArrayView(
        shape: [Int],
        dataType: MLMultiArrayDataType
    ) throws -> MLMultiArray {
        var reversedStrides = Array(repeating: 1, count: shape.count)
        let reversedShape = Array(shape.reversed())
        for i in 1 ..< reversedStrides.count {
            reversedStrides[i] = reversedStrides[i - 1] * reversedShape[i - 1]
        }
        let strides = Array(reversedStrides.reversed())
        
        return try MLMultiArray(
            dataPointer: self.baseAddress,
            shape: shape.map(NSNumber.init(value:)),
            dataType: dataType,
            strides: strides.map(NSNumber.init(value:))
        )
    }
    
    @available(iOS 14.0, macCatalyst 14.0, *)
    public func mlMultiArrayView(
        shape: [Int],
        strides: [Int],
        dataType: MLMultiArrayDataType
    ) throws -> MLMultiArray {
        let dataLength = shape.reduce(1, *) * dataType.stride
        guard dataLength <= self.dataLength else { throw Error.outOfBounds }
        
        return try MLMultiArray(
            dataPointer: self.baseAddress,
            shape: shape.map(NSNumber.init(value:)),
            dataType: dataType,
            strides: strides.map(NSNumber.init(value:))
        )
    }
    
    #if !targetEnvironment(simulator)
    public func mtlBufferView(device: MTLDevice) throws -> MTLBuffer {
        guard let buffer = device.makeBuffer(
            bytesNoCopy: self.baseAddress,
            length: Int(self.bytesPerRow * self.height),
            options: .storageModeShared,
            deallocator: nil
        ) else { throw MetalError.MTLDeviceError.bufferCreationFailed }
        
        return buffer
    }
    
    public func mtlTextureView(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        usage: MTLTextureUsage = []
    ) throws -> MTLTexture {
        let buffer = try self.mtlBufferView(device: device)
        
        let descriptor = MTLTextureDescriptor()
        descriptor.width = Int(self.width)
        descriptor.height = Int(self.height)
        descriptor.pixelFormat = pixelFormat
        descriptor.usage = usage
        descriptor.storageMode = .shared
        
        guard let texture = buffer.makeTexture(
            descriptor: descriptor,
            offset: 0,
            bytesPerRow: Int(self.bytesPerRow)
        ) else { throw MetalError.MTLDeviceError.textureCreationFailed }
        
        return texture
    }
    #endif // !targetEnvironment(simulator)
    #endif // arch(arm64)
}
