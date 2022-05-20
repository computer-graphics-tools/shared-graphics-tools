import CoreML

#if arch(arm64) // avoid rosetta
@available(iOS 14.0, macCatalyst 14.0, *)
public extension MLMultiArray {
    var dataLength: Int { self.shape.map(\.intValue).reduce(1, *) * self.dataType.stride }
}
#endif
