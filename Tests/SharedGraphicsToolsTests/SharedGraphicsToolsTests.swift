#if !targetEnvironment(simulator)

import XCTest
import MetalTools
@testable import SharedGraphicsTools

@available(iOS 14.0, *)
final class SharedGraphicsToolsTests: XCTestCase {

    enum Error: Swift.Error {
        case missingResultValues
    }

    func testSharedBuffer() throws {
        let contextSize = CGSize(width: 40, height: 40)
        let rect = CGRect(x: 10, y: 10, width: 20, height: 20)

        let context = try MTLContext()
        let statisticsKernel = MPSImageStatisticsMeanAndVariance(device: context.device)
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

        let resultTexture = try sharedBuffer.texture.matchingTexture()
        let resultBuffer = try context.buffer(
            length: 2 * MemoryLayout<Float>.size,
            options: .storageModeShared
        )

        try context.scheduleAndWait { commandBuffer in
            statisticsKernel(
                source: sharedBuffer.texture,
                destination: resultTexture,
                in: commandBuffer
            )
            commandBuffer.blit { blitEncoder in
                blitEncoder.copy(
                    from: resultTexture,
                    sourceSlice: 0,
                    sourceLevel: 0,
                    sourceOrigin: .zero,
                    sourceSize: MTLSize(width: 2, height: 1, depth: 1),
                    to: resultBuffer,
                    destinationOffset: 0,
                    destinationBytesPerRow: 2 * MemoryLayout<Float>.size,
                    destinationBytesPerImage: 2 * MemoryLayout<Float>.size)
            }
        }

        guard let meanAndVarianceValues = resultBuffer.array(of: Float16.self, count: 2)
        else { throw Error.missingResultValues }

        let expectedMeanValue = Float32((rect.size.width * rect.size.height) / (contextSize.width * contextSize.height))

        XCTAssertEqual(Float32(meanAndVarianceValues[0]), expectedMeanValue, accuracy: 0.0001)
    }
}

#endif
