#if os(iOS)

import UIKit

extension UIImage: GraphicsDataProvider {
    public func graphicsData() throws -> GraphicsData {
        guard let cgImage = self.cgImage
        else { throw GraphicsDataProviderError.missingData }
        return try cgImage.graphicsData()
    }
}

#endif
