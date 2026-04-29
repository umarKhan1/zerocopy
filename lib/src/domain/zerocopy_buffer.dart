import 'dart:ffi';
import 'dart:typed_data';
import '../infrastructure/zerocopy_ffi_bridge.dart' as ffi_bridge;

/// A high-performance memory buffer mapped directly to a C++ allocated
/// memory address without any data copying between Dart and Native.
class ZeroCopyBuffer implements Finalizable {
  static final NativeFinalizer _finalizer =
      NativeFinalizer(ffi_bridge.freeBufferAddressPtr);

  final int sizeInBytes;
  Pointer<Uint8>? _bufferPtr;
  Uint8List? _view;
  bool _isDisposed = false;

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

    // Attach native finalizer for memory safety
    _finalizer.attach(this, rawPtr, detach: this);
  }

  /// Returns a direct [Uint8List] view into the native memory buffer.
  /// Use this for zero-copy read/write operations.
  Uint8List get view {
    if (_isDisposed || _view == null) {
      throw StateError('ZeroCopyBuffer has been disposed.');
    }
    return _view!;
  }

  /// Sets the 8-bit [value] at the specified [index] in the native buffer.
  void set(int index, int value) {
    view[index] = value;
  }

  /// Gets the 8-bit value at the specified [index] from the native buffer.
  int get(int index) {
    return view[index];
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

  /// Frees the underlying C++ aligned memory immediately.
  /// After calling dispose, the buffer will no longer be accessible and will throw.
  void dispose() {
    if (!_isDisposed && _bufferPtr != null) {
      _isDisposed = true;
      _finalizer.detach(this); // Prevent double-free
      ffi_bridge.free_buffer_address(_bufferPtr!.cast<Void>());
      _bufferPtr = null;
      _view = null;
    }
  }
}
