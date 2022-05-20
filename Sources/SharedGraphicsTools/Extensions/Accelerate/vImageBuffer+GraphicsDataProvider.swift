import Accelerate

extension vImage_Buffer: GraphicsDataProvider {
    public func graphicsData() throws -> GraphicsData {
        return .init(
            width: self.width,
            height: self.height,
            baseAddress: self.data,
            bytesPerRow: UInt(self.rowBytes)
        )
    }
}
