import Foundation
import Accelerate
import CoreVideoTools
import CoreML

public protocol MultiplanarPlanarGraphicsDataProvider {
    func graphicsData(of planeIndex: Int) throws -> GraphicsData
}

public extension MultiplanarPlanarGraphicsDataProvider {
    func vImageBufferView(planeIndex: Int) throws -> vImage_Buffer {
        return try self.graphicsData(of: planeIndex).vImageBufferView()
    }
    
    func cvPixelBufferView(
        planeIndex: Int,
        cvPixelFormat: CVPixelFormat
    ) throws -> CVPixelBuffer {
        return try self.graphicsData(of: planeIndex).cvPixelBufferView(cvPixelFormat: cvPixelFormat)
    }
    
    #if arch(arm64)
    @available(iOS 14.0, macCatalyst 14.0, *)
    func mlMultiArrayView(
        planeIndex: Int,
        shape: [Int],
        dataType: MLMultiArrayDataType
    ) throws -> MLMultiArray {
        return try self.graphicsData(of: planeIndex).mlMultiArrayView(
            shape: shape,
            dataType: dataType
        )
    }
    
    @available(iOS 14.0, macCatalyst 14.0, *)
    func mlMultiArrayView(
        planeIndex: Int,
        shape: [Int],
        strides: [Int],
        dataType: MLMultiArrayDataType
    ) throws -> MLMultiArray {
        return try self.graphicsData(of: planeIndex).mlMultiArrayView(
            shape: shape,
            strides: strides,
            dataType: dataType
        )
    }
    #endif
    
    #if !targetEnvironment(simulator)
    func mtlBufferView(
        planeIndex: Int,
        device: MTLDevice
    ) throws -> MTLBuffer {
        return try self.graphicsData(of: planeIndex).mtlBufferView(device: device)
    }
    
    func mtlTextureView(
        planeIndex: Int,
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        usage: MTLTextureUsage = []
    ) throws -> MTLTexture {
        return try self.graphicsData(of: planeIndex).mtlTextureView(
            device: device,
            pixelFormat: pixelFormat,
            usage: usage
        )
    }
    #endif
}
