# Working with SharedGraphicsBuffer

Learn how to use `MTLSharedGraphicsBuffer` to efficiently share graphics memory between different APIs.

## Overview

``MTLSharedGraphicsBuffer`` is a powerful tool in the SharedGraphicsTools library that allows you to work with graphics data across multiple APIs without unnecessary memory copies. It provides a page-aligned memory buffer that can be accessed by Metal, Core Graphics, vImage, and Core Video simultaneously.

## Creating a SharedGraphicsBuffer

To create a `MTLSharedGraphicsBuffer`, you need to specify the dimensions, pixel format, and Metal device:

```swift
import SharedGraphicsTools
import MetalTools

let context = try MTLContext()

let sharedBuffer = try MTLSharedGraphicsBuffer(
    device: context.device,
    width: 600,
    height: 600,
    pixelFormat: .bgra8Unorm
)
```

## Accessing Different Views of the Buffer

Once you've created a ``MTLSharedGraphicsBuffer``, you can access its contents through various APIs:

### Metal Texture

```swift
let metalTexture: MTLTexture = sharedBuffer.texture
```

### Core Graphics Context

```swift
let cgContext: CGContext = sharedBuffer.cgContext
```

### vImage Buffer

```swift
let vImageBuffer: vImage_Buffer = sharedBuffer.vImageBuffer
```

### Core Video Pixel Buffer

```swift
let pixelBuffer: CVPixelBuffer = sharedBuffer.pixelBuffer
```

## Example: Combining Core Graphics and Metal

Here's an example of how you can use ``MTLSharedGraphicsBuffer`` to combine Core Graphics drawing with Metal processing without any memory transfers:

```swift
// Draw a white rectangle using Core Graphics
let rect = CGRect(x: 125, y: 125, width: 300, height: 300)
let whiteColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
sharedBuffer.cgContext.setFillColor(whiteColor)
sharedBuffer.cgContext.fill(rect)

// Process the result using Metal
try context.schedule { commandBuffer in
    someFancyMetalFilter.encode(
        source: sharedBuffer.texture,
        destination: resultTexture,
        in: commandBuffer
    )
}
```

## Important Considerations

- The memory used by ``MTLSharedGraphicsBuffer`` is page-aligned, which is required for certain operations in Metal.
- While ``MTLSharedGraphicsBuffer`` reduces the need for memory copies, be mindful of potential synchronization issues when accessing the buffer from multiple APIs concurrently.
The pixel format specified when creating the buffer should be compatible with all the APIs you intend to use.

By leveraging ``MTLSharedGraphicsBuffer``, you can create more efficient graphics pipelines, especially in scenarios involving multiple graphics APIs.
