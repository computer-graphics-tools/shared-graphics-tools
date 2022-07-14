import CoreML

public extension MLMultiArray {
    var dataLength: Int { self.shape.map(\.intValue).reduce(1, *) * self.dataType.stride }
}
