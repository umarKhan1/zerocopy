import 'dart:ffi';
import 'dart:typed_data';
import '../infrastructure/zerocopy_ffi_bridge.dart' as ffi_bridge;

/// A high-performance memory buffer mapped directly to a C++ allocated
/// memory address without any data copying between Dart and Native.
class ZeroCopyBuffer {
  final int sizeInBytes;
  Pointer<Uint8>? _bufferPtr;
  Uint8List? _view;

  /// Creates a [ZeroCopyBuffer] of the requested [sizeInBytes].
  /// By default, a size of 1MB (1048576 bytes) is a good starting point for
  /// real-time data streams without bloating memory.
  ZeroCopyBuffer({required this.sizeInBytes}) {
    if (sizeInBytes <= 0) {
      throw ArgumentError('Buffer size must be greater than 0.');
    }
    
    // Allocate 64-byte aligned SIMD memory in C++
    final rawPtr = ffi_bridge.get_buffer_address(sizeInBytes);
    if (rawPtr.address == 0) {
      throw OutOfMemoryError();
    }
    
    _bufferPtr = rawPtr.cast<Uint8>();
    
    // Create a direct memory view into the C++ buffer.
    // STRICT REQUIREMENT: No data is cloned here. This is a zero-copy pointer view.
    _view = _bufferPtr!.asTypedList(sizeInBytes);
  }

  /// Returns a direct [Uint8List] view into the native memory buffer.
  /// Use this for zero-copy read/write operations.
  Uint8List get view {
    if (_view == null) {
      throw StateError('ZeroCopyBuffer has been disposed.');
    }
    return _view!;
  }

  /// Acquires the atomic spinlock from the C++ layer.
  /// Blocks the current thread (spinning) until the lock is available.
  /// Extremely fast for short lock durations (zero context switch).
  void lock() {
    ffi_bridge.lock_buffer();
  }

  /// Releases the atomic spinlock.
  void unlock() {
    ffi_bridge.unlock_buffer();
  }

  /// Frees the underlying C++ aligned memory.
  /// After calling dispose, the [view] will no longer be accessible and will throw.
  void dispose() {
    if (_bufferPtr != null) {
      ffi_bridge.free_buffer_address(_bufferPtr!.cast<Void>());
      _bufferPtr = null;
      _view = null;
    }
  }
}
