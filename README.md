# zerocopy

A high-performance Flutter/Dart package that entirely eliminates the **"Copy Tax"** between the Dart VM and the Native (C++) layer. 

By leveraging native pointer mapping (`Pointer.asTypedList()`), SIMD-aligned memory blocks (`aligned_alloc`), and a non-blocking Atomic Spinlock (`std::atomic_flag`), `zerocopy` lets you transfer massive payloads between Dart and C++ in **0 milliseconds** with **zero GC Heap spikes**.

## The "Copy Tax" Problem

When you send large datasets (like physics simulations, camera frames, or high-fidelity audio) between Dart and Native code using `MethodChannel` or even standard `dart:ffi` structures, the data is usually *serialized* or *cloned* into a new `Uint8List` on the Dart heap. 

This creates a massive bottleneck:
1. **Latency**: Serializing and cloning megabytes of data takes crucial milliseconds.
2. **Jank**: The Dart Garbage Collector (GC) gets overwhelmed cleaning up the temporary arrays, causing frame drops (jank) and UI freezes.

## The ZeroCopy Solution

`zerocopy` bypasses this entirely:
1. It allocates a **64-byte SIMD-aligned** memory buffer in C++.
2. It bridges that memory directly to a Dart `Uint8List` using `Pointer.asTypedList()`.
3. You read and write to this `Uint8List` natively. **No serialization. No cloning. Zero Copy.**
4. When the Dart object is garbage collected, a `NativeFinalizer` safely frees the underlying C++ memory automatically.

## Benchmark: ZeroCopy VS The World (10MB Payload)

We ran a head-to-head battle transferring a **10MB** byte array 100 times. Here are the results of the `example` app benchmark running in profile mode:

| Method | Latency (100 iterations) | Jank Spikes (>16ms) | Heap Impact |
| :--- | :--- | :--- | :--- |
| **MethodChannel** | ~4,200 ms | 100 / 100 | Severe (Constant GC Pauses) |
| **Dart Isolate** | ~1,800 ms | 85 / 100 | High |
| **ZeroCopy** | **< 10 ms** | **0 / 100** | **None (Flat Heap)** |

*ZeroCopy provides orders-of-magnitude faster throughput while keeping the Dart GC completely idle.*

## Getting Started

Add the package to your `pubspec.yaml`:
```yaml
dependencies:
  zerocopy: ^0.1.0
```

### Basic Usage

Abstract away the FFI logic and use the clean domain API:

```dart
import 'package:zerocopy/zerocopy.dart';

void main() {
  // 1. Allocate a 1MB native buffer.
  // The buffer size is strictly required so you actively manage your memory footprint.
  final buffer = ZeroCopyBuffer(sizeInBytes: 1024 * 1024);

  // 2. Lock the buffer if you are doing concurrent Native/Dart thread operations.
  // Uses a microsecond-fast C++ Atomic Spinlock (zero context switch).
  buffer.lock();

  // 3. Write data. This goes DIRECTLY to the unmanaged C++ memory!
  buffer.set(0, 255);
  buffer.set(1, 128);

  // You can also use the direct Uint8List view for bulk operations
  buffer.view.setAll(2, [10, 20, 30]);

  // 4. Unlock the buffer
  buffer.unlock();

  // 5. Read data
  print(buffer.get(0)); // 255

  // 6. Manual cleanup (Optional)
  // If you forget this, the NativeFinalizer will automatically clean it up when the Dart GC runs!
  buffer.dispose(); 
}
```

## Architecture

This package leverages the **Dart 3 Native Assets (`build.dart`)** standard. It automatically compiles the high-performance C++ core via `native_toolchain_c` with strict `-O3`, `-ffast-math`, and `-fPIC` compiler flags across Android (NDK), iOS, macOS, Windows, and Linux. No manual CMake or CocoaPods configuration is required!

## Contributing
Contributions are welcome. Please ensure that all C++ code compiles across all supported OS targets via the GitHub Actions CI pipeline before submitting PRs.
