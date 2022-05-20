import MetalTools
import Accelerate
import CoreVideoTools
import CoreML

public extension MTLTexture {
    func graphicsData() throws -> GraphicsData {
        guard let buffer = self.buffer
        else { throw GraphicsDataProviderError.missingData }
        
        return .init(
            width: UInt(self.width),
            height: UInt(self.height),
            baseAddress: buffer.contents(),
            bytesPerRow: UInt(self.bufferBytesPerRow)
        )
    }
    
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
    #endif

}
