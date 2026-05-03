import 'dart:ffi';
import 'dart:typed_data';
import '../infrastructure/zerocopy_ffi_bridge.dart' as ffi_bridge;

/// A high-performance native memory buffer that provides **zero-copy** data
/// sharing between Dart and C++.
///
/// Unlike standard Dart `Uint8List` allocations or data transferred via
/// `MethodChannel`, a [ZeroCopyBuffer] allocates memory **directly in C++**
/// using a 64-byte SIMD-aligned allocator (`aligned_alloc` / `posix_memalign`).
/// The Dart [view] is a raw pointer into this native memory — no serialization
/// or cloning ever occurs.
///
/// ## Memory Safety
///
/// [ZeroCopyBuffer] implements [Finalizable] and attaches a [NativeFinalizer]
/// to the underlying allocation. Even if you forget to call [dispose], the
/// C++ memory will be freed automatically when this object is garbage collected.
/// To free memory immediately and deterministically, call [dispose].
///
/// ## Thread Safety
///
/// The buffer includes an **atomic spinlock** backed by `std::atomic_flag`.
/// Use [lock] and [unlock] (ideally inside a `try/finally`) when a native
/// thread and the Dart isolate access the buffer concurrently. The spinlock has
/// **zero context-switch overhead** and is suited for microsecond-duration
/// critical sections only.
///
/// ## Example
///
/// ```dart
/// import 'package:zerocopy/zerocopy.dart';
///
/// void main() {
///   final buffer = ZeroCopyBuffer(sizeInBytes: 1024 * 1024); // 1 MB
///
///   buffer.lock();
///   try {
///     buffer.set(0, 255);
///     buffer.view.setAll(1, [10, 20, 30]);
///   } finally {
///     buffer.unlock();
///   }
///
///   print(buffer.get(0)); // 255
///
///   buffer.dispose();
/// }
/// ```
class ZeroCopyBuffer implements Finalizable {
  static final NativeFinalizer _finalizer =
      NativeFinalizer(ffi_bridge.freeBufferAddressPtr);

  /// The size of this buffer in bytes, as requested at construction time.
  final int sizeInBytes;

  Pointer<Uint8>? _bufferPtr;
  Uint8List? _view;
  bool _isDisposed = false;

  /// Creates a [ZeroCopyBuffer] of [sizeInBytes] bytes.
  ///
  /// Memory is allocated in C++ using a 64-byte SIMD-aligned allocator,
  /// completely outside the Dart GC heap.
  ///
  /// - Throws [ArgumentError] if [sizeInBytes] is ≤ 0.
  /// - Throws [OutOfMemoryError] if the native allocation fails.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Allocate a 4 MB buffer
  /// final buffer = ZeroCopyBuffer(sizeInBytes: 4 * 1024 * 1024);
  /// ```
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

  /// A zero-copy [Uint8List] view directly into the native C++ memory buffer.
  ///
  /// Reading from or writing to this list operates **directly on the C++
  /// allocation** — no data is copied to or from the Dart heap.
  ///
  /// Use this for bulk operations (e.g., `setAll`, `sublist`, `buffer`):
  ///
  /// ```dart
  /// // Bulk write
  /// buffer.view.setAll(0, myLargeByteArray);
  ///
  /// // Bulk read
  /// final snapshot = buffer.view.sublist(0, 512);
  /// ```
  ///
  /// Throws a [StateError] if the buffer has already been [dispose]d.
  Uint8List get view {
    if (_isDisposed || _view == null) {
      throw StateError('ZeroCopyBuffer has been disposed.');
    }
    return _view!;
  }

  /// Writes an 8-bit [value] at the given [index] in the native buffer.
  ///
  /// This is equivalent to `view[index] = value` but provides a named,
  /// expressive API for single-byte mutations.
  ///
  /// Throws a [StateError] if the buffer has been [dispose]d.
  /// Throws a [RangeError] if [index] is out of bounds.
  void set(int index, int value) {
    view[index] = value;
  }

  /// Returns the 8-bit value at the given [index] in the native buffer.
  ///
  /// This is equivalent to `view[index]` but provides a named,
  /// expressive API for single-byte reads.
  ///
  /// Throws a [StateError] if the buffer has been [dispose]d.
  /// Throws a [RangeError] if [index] is out of bounds.
  int get(int index) {
    return view[index];
  }

  /// Acquires the C++ atomic spinlock.
  ///
  /// Blocks the calling thread by **spinning** (busy-waiting) until the lock
  /// is available. This has **zero context-switch overhead**, making it ideal
  /// for extremely short critical sections (sub-microsecond to a few
  /// microseconds).
  ///
  /// Always pair with [unlock] inside a `try/finally` block to prevent
  /// deadlocks:
  ///
  /// ```dart
  /// buffer.lock();
  /// try {
  ///   buffer.set(0, 42);
  /// } finally {
  ///   buffer.unlock();
  /// }
  /// ```
  ///
  /// > ⚠️ **Warning:** Do not hold this lock for more than a few microseconds.
  /// > For long-running operations, use Dart [Isolate] message passing instead.
  void lock() {
    ffi_bridge.lock_buffer();
  }

  /// Releases the C++ atomic spinlock.
  ///
  /// Must be called exactly once after each successful [lock] call.
  /// Prefer using a `try/finally` block to guarantee release even on errors.
  void unlock() {
    ffi_bridge.unlock_buffer();
  }

  /// Frees the underlying C++ memory immediately and marks this buffer as
  /// disposed.
  ///
  /// After [dispose] is called:
  /// - Accessing [view], [get], or [set] will throw a [StateError].
  /// - Calling [dispose] again is a no-op (safe to call multiple times).
  ///
  /// If [dispose] is **not** called, the [NativeFinalizer] attached at
  /// construction will free the native memory automatically when this
  /// [ZeroCopyBuffer] object is garbage collected by the Dart VM.
  ///
  /// For deterministic, immediate memory reclamation, always call [dispose]
  /// when you are done with the buffer.
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
