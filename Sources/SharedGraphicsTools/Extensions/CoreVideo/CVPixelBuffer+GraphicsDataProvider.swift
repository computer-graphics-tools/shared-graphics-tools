import CoreVideoTools

extension CVPixelBuffer: GraphicsDataProvider {
    public func graphicsData() throws -> GraphicsData {
        let width = self.width
        let height = self.height
        let bytesPerRow = self.bytesPerRow
        guard let baseAddress = self.baseAddress,
              width > 0, height > 0, bytesPerRow > 0
        else { throw GraphicsDataProviderError.missingData }
        return .init(
            width: UInt(width),
            height: UInt(height),
            baseAddress: baseAddress,
            bytesPerRow: UInt(bytesPerRow)
        )
    }
}

extension CVPixelBuffer: MultiplanarPlanarGraphicsDataProvider {
    public func graphicsData(of planeIndex: Int) throws -> GraphicsData {
        guard planeIndex < self.planeCount
        else { throw GraphicsDataProviderError.missingDataOfPlane(planeIndex) }
        
        let width = self.width(of: planeIndex)
        let height = self.height(of: planeIndex)
        let bytesPerRow = self.bytesPerRow(of: planeIndex)
        guard let baseAddress = self.baseAddress(of: planeIndex),
              width > 0, height > 0, bytesPerRow > 0
        else { throw GraphicsDataProviderError.missingDataOfPlane(planeIndex) }
        return .init(
            width: UInt(width),
            height: UInt(height),
            baseAddress: baseAddress,
            bytesPerRow: UInt(bytesPerRow)
        )
    }
}
