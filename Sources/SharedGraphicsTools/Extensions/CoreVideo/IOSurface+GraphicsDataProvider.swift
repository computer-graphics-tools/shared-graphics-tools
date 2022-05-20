import CoreVideoTools

extension IOSurface: GraphicsDataProvider {
    public func graphicsData() throws -> GraphicsData {
        let width = self.width
        let height = self.height
        let baseAddress = self.baseAddress
        let bytesPerRow = self.bytesPerRow
        let bytesPerElement = self.bytesPerElement
        guard width > 0, height > 0, bytesPerRow > 0, bytesPerElement > 0
        else { throw GraphicsDataProviderError.missingData }
        return .init(
            width: UInt(width),
            height: UInt(height),
            baseAddress: baseAddress,
            bytesPerRow: UInt(bytesPerRow)
        )
    }
}
extension IOSurface: MultiplanarPlanarGraphicsDataProvider {
    public func graphicsData(of planeIndex: Int) throws -> GraphicsData {
        guard planeIndex < self.planeCount
        else { throw GraphicsDataProviderError.missingDataOfPlane(planeIndex) }
        
        let width = self.widthOfPlane(at: planeIndex)
        let height = self.heightOfPlane(at: planeIndex)
        let baseAddress = self.baseAddressOfPlane(at: planeIndex)
        let bytesPerRow = self.bytesPerRowOfPlane(at: planeIndex)
        let bytesPerElement = self.bytesPerElementOfPlane(at: planeIndex)
        guard width > 0, height > 0, bytesPerRow > 0, bytesPerElement > 0
        else { throw GraphicsDataProviderError.missingDataOfPlane(planeIndex) }
        return .init(
            width: UInt(width),
            height: UInt(height),
            baseAddress: baseAddress,
            bytesPerRow: UInt(bytesPerRow)
        )
    }
}
