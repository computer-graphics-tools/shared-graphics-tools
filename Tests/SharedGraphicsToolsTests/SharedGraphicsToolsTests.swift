#if !targetEnvironment(simulator)

import XCTest
import MetalComputeTools
@testable import SharedGraphicsTools

final class SharedGraphicsToolsTests: XCTestCase {

    func testSharedBuffer() throws {
        let contextSize = CGSize(width: 40, height: 40)
        let rect = CGRect(x: 10, y: 10, width: 20, height: 20)

        let context = try MTLContext()
        let textureMean = try TextureMean(context: context, scalarType: .half)
        let sharedBuffer = try MTLSharedGraphicsBuffer(
            device: context.device,
            width: Int(contextSize.width),
            height: Int(contextSize.height),
            pixelFormat: .r16Float
        )

        sharedBuffer.cgContext.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        sharedBuffer.cgContext.fill(CGRect(origin: .zero, size: contextSize))
        sharedBuffer.cgContext.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        sharedBuffer.cgContext.fill(rect)
        
        let bufferElementCount = sharedBuffer.bytesPerRow * sharedBuffer.height / MemoryLayout<Float16>.stride
        let values = sharedBuffer.buffer.array(of: Float16.self, count: bufferElementCount) ?? []
        let valuesSum = values.map(Double.init).reduce(0, +)
        let expectedSum = rect.width * rect.height

        XCTAssertEqual(valuesSum, expectedSum)

        let meanBuffer = try context.buffer(with: SIMD4<Float32>.zero)

        try context.scheduleAndWait {
            textureMean(source: sharedBuffer.texture, result: meanBuffer, in: $0)
        }

        let meanValue = (meanBuffer.pointer(of: SIMD4<Float32>.self)?.pointee ?? .zero).x
        let expectedMeanValue = Float32((rect.size.width * rect.size.height) / (contextSize.width * contextSize.width))

        XCTAssertEqual(meanValue, expectedMeanValue)
    }

}

#endif
