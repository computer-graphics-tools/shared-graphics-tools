import CoreGraphics
import Foundation

extension CGContext: GraphicsDataProvider {
    public func graphicsData() throws -> GraphicsData {
        guard let baseAddress = self.data
        else { throw GraphicsDataProviderError.missingData }
        return .init(
            width: UInt(self.width),
            height: UInt(self.height),
            baseAddress: baseAddress,
            bytesPerRow: UInt(self.bytesPerRow)
        )
    }
}

extension CGImage: GraphicsDataProvider {
    public func graphicsData() throws -> GraphicsData {
        guard let dataProvider = self.dataProvider,
              let data = dataProvider.data,
              let readOnlyBaseAddress = CFDataGetBytePtr(data)
        else { throw GraphicsDataProviderError.missingData }
        
        let mutableBaseAddress = UnsafeMutablePointer<UInt8>(mutating: readOnlyBaseAddress)
        
        return .init(
            width: UInt(self.width),
            height: UInt(self.height),
            baseAddress: mutableBaseAddress,
            bytesPerRow: UInt(self.bytesPerRow)
        )
    }
}
