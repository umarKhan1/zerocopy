/// A high-performance Flutter/Dart package that eliminates the "Copy Tax"
/// between the Dart VM and the Native (C++) layer.
///
/// `zerocopy` allocates memory in C++ using a 64-byte SIMD-aligned allocator
/// and bridges that memory directly to a Dart [Uint8List] via
/// `Pointer.asTypedList()`. No serialization. No cloning. Zero copy.
///
/// ## Usage
///
/// ```dart
/// import 'package:zerocopy/zerocopy.dart';
///
/// final buffer = ZeroCopyBuffer(sizeInBytes: 1024 * 1024);
/// buffer.set(0, 255);
/// print(buffer.get(0)); // 255
/// buffer.dispose();
/// ```
///
/// See [ZeroCopyBuffer] for the full API.
library zerocopy;

export 'src/domain/zerocopy_buffer.dart';
