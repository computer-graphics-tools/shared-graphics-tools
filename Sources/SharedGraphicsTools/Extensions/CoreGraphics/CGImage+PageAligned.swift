import Foundation
import CoreGraphics

extension CGImage {
    
    public func pageAlignedCGImage() throws -> CGImage {
        guard let dataProvider = self.dataProvider,
              let data = dataProvider.data,
              let readOnlyBaseAddress = CFDataGetBytePtr(data)
        else { throw GraphicsDataProviderError.missingData }
        
        let dataLength = CFDataGetLength(data)
        var allocationPointer: UnsafeMutableRawPointer?
        let pageSize = Int(getpagesize())
        posix_memalign(
            &allocationPointer,
            pageSize,
            dataLength
        )
        
        guard let allignedPointer = allocationPointer
        else { throw GraphicsDataProviderError.missingData }
        allignedPointer.copyMemory(from: readOnlyBaseAddress, byteCount: dataLength)
        
        guard let data = CFDataCreateWithBytesNoCopy(nil, allignedPointer, dataLength, nil),
              let dataProvider = CGDataProvider(data: data),
              let colorSpace = self.colorSpace,
              let cgImage = CGImage(
                width: self.width,
                height: self.height,
                bitsPerComponent: self.bitsPerComponent,
                bitsPerPixel: self.bitsPerPixel,
                bytesPerRow: self.bytesPerRow,
                space: colorSpace,
                bitmapInfo: self.bitmapInfo,
                provider: dataProvider,
                decode: self.decode,
                shouldInterpolate: self.shouldInterpolate,
                intent: self.renderingIntent
              )
        else { throw GraphicsDataProviderError.missingData }
        
        return cgImage
    }
    
}
