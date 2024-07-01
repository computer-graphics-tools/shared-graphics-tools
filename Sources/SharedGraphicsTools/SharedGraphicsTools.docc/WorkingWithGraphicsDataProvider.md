# Working with GraphicsDataProvider

Learn how to use the `GraphicsDataProvider` protocol to efficiently work with and convert between different graphics data formats.

## Overview

The ``GraphicsDataProvider`` protocol is a core component of SharedGraphicsTools, allowing you to reinterpret graphics data in various formats without unnecessary memory copies. This can significantly improve performance in graphics-intensive applications.

## Conforming Types

By default, the following types conform to ``GraphicsDataProvider``:

- `vImage_Buffer`
- `CGContext`
- `CGImage`
- `CVPixelBuffer`
- `IOSurface`
- `MTLTexture`
- `UIImage` (iOS only)

## Accessing Different Views

Once you have an object conforming to ``GraphicsDataProvider``, you can access its data in various formats:

### vImage Buffer View

```swift
let vImageBuffer: vImage_Buffer = try graphicsDataProvider.vImageBufferView()
```

### CVPixelBuffer View

```swift
let pixelBuffer: CVPixelBuffer = try graphicsDataProvider.cvPixelBufferView(cvPixelFormat: .type_32BGRA)
```

### MLMultiArray View

```swift
let multiArray: MLMultiArray = try graphicsDataProvider.mlMultiArrayView(
    shape: [1, 3, height, width],
    dataType: .float32
)
```

### MTLBuffer View

```swift
let metalBuffer: MTLBuffer = try graphicsDataProvider.mtlBufferView(device: metalDevice)
```

### MTLTexture View

```swift
let metalTexture: MTLTexture = try graphicsDataProvider.mtlTextureView(
    device: metalDevice,
    pixelFormat: .bgra8Unorm,
    usage: [.shaderRead, .shaderWrite]
)
```

## Example: Converting Between Formats

Here's an example of how you can use ``GraphicsDataProvider`` to efficiently convert between different graphics formats:

```swift
let ioSurface: IOSurface = // ... create or obtain an IOSurface

// Convert to vImage_Buffer
let vImageBuffer: vImage_Buffer = try ioSurface.vImageBufferView()

// Convert to CVPixelBuffer
let pixelBuffer: CVPixelBuffer = try vImageBuffer.cvPixelBufferView(cvPixelFormat: .type_32BGRA)

// Convert to MTLTexture
let texture: MTLTexture = try vImageBuffer.mtlTextureView(
    device: metalDevice,
    pixelFormat: .bgra8Unorm,
    usage: [.shaderRead, .shaderWrite]
)
```

In this example, we start with an `IOSurface` and convert it to a `vImage_Buffer`, `CVPixelBuffer`, and `MTLTexture` without any memory copies.\

## Important Considerations

- While GraphicsDataProvider reduces the need for memory copies, be mindful of potential synchronization issues when accessing the data from multiple APIs concurrently.
- Some conversions may have specific requirements or limitations. Always check the documentation for each method and handle potential errors.
- The pixel format or data type should be compatible across different views of the same data.

By leveraging ``GraphicsDataProvider``, you can create more efficient graphics pipelines, especially in scenarios involving multiple graphics APIs.
