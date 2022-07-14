import Foundation
import CoreVideoTools
import CoreVideo
import MetalTools
import CoreML
import Accelerate

public enum GraphicsDataProviderError: Error {
    case missingData
    case missingDataOfPlane(Int)
}

public protocol GraphicsDataProvider {
    func graphicsData() throws -> GraphicsData
}

public extension GraphicsDataProvider {
    func vImageBufferView() throws -> vImage_Buffer {
        return try self.graphicsData().vImageBufferView()
    }
    
    func cvPixelBufferView(cvPixelFormat: CVPixelFormat) throws -> CVPixelBuffer {
        return try self.graphicsData().cvPixelBufferView(cvPixelFormat: cvPixelFormat)
    }
    
    #if arch(arm64)
    @available(iOS 14.0, macCatalyst 14.0, *)
    func mlMultiArrayView(
        shape: [Int],
        dataType: MLMultiArrayDataType
    ) throws -> MLMultiArray {
        return try self.graphicsData().mlMultiArrayView(
            shape: shape,
            dataType: dataType
        )
    }
    
    @available(iOS 14.0, macCatalyst 14.0, *)
    func mlMultiArrayView(
        shape: [Int],
        strides: [Int],
        dataType: MLMultiArrayDataType
    ) throws -> MLMultiArray {
        return try self.graphicsData().mlMultiArrayView(
            shape: shape,
            strides: strides,
            dataType: dataType
        )
    }
    
    #if !targetEnvironment(simulator)
    func mtlBufferView(device: MTLDevice) throws -> MTLBuffer {
        return try self.graphicsData().mtlBufferView(device: device)
    }
    
    func mtlTextureView(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        usage: MTLTextureUsage = []
    ) throws -> MTLTexture {
        return try self.graphicsData().mtlTextureView(
            device: device,
            pixelFormat: pixelFormat,
            usage: usage
        )
    }
    #endif // !targetEnvironment(simulator)
    #endif // arch(arm64)
}
