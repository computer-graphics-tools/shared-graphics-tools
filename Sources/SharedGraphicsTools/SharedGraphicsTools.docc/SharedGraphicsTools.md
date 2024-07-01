# ``SharedGraphicsTools``

![SharedGraphicsTools](shared-graphics-tools.png)

Efficiently share graphics memory between different APIs on Apple platforms.

## Overview

SharedGraphicsTools is a powerful library that provides a convenient way to share graphics memory between different APIs on Apple platforms. It's designed to reduce memory traffic in computer vision pipelines and other graphics-intensive applications.

The library introduces the ``GraphicsDataProvider`` protocol, which allows you to reinterpret graphics data in various formats without unnecessary memory copies. It also provides the ``MTLSharedGraphicsBuffer`` class for working with page-aligned memory buffers across multiple graphics APIs.

## Topics

### Essentials

- <doc:WorkingWithSharedGraphicsBuffer>
- <doc:WorkingWithGraphicsDataProvider>

### Core Protocols

- ``GraphicsDataProvider``
- ``MultiplanarPlanarGraphicsDataProvider``

### Main Classes

- ``MTLSharedGraphicsBuffer``
- ``GraphicsData``


SharedGraphicsTools is built on top of [MetalTools](https://github.com/eugenebokhan/metal-tools) and [CoreVideoTools](https://github.com/eugenebokhan/core-video-tools), which provide additional functionality for working with Metal and Core Video respectively.
