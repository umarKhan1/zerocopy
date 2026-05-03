## 0.1.1


* Fix: renamed FFI bridge functions to lowerCamelCase (`getBufferAddress`, `freeBufferAddress`, `lockBuffer`, `unlockBuffer`) using the `symbol:` parameter on `@Native` to preserve C linkage names. Resolves 4 static analysis INFO issues.
* Bump minimum SDK constraint to `^3.6.0` as required by pub.dev for packages using `hook/build.dart` (Dart Native Assets).

## 0.1.0

* Initial release.
* Allocates 64-byte SIMD-aligned native memory buffers from C++ via `aligned_alloc` / `posix_memalign` / `_aligned_malloc`.
* Bridges native memory directly to Dart `Uint8List` via `Pointer.asTypedList()` — zero data copying.
* Provides an atomic spinlock (`std::atomic_flag`) for non-blocking thread safety between Dart and native threads.
* Automatic memory management via `NativeFinalizer` — no leaks even if `dispose()` is not called.
* Cross-platform native compilation via Dart 3 Native Assets (`hook/build.dart`) with `native_toolchain_c`.
* Supports Android, iOS, macOS, Windows, and Linux with no manual build configuration.
* Compiler flags: `-O3 -ffast-math -fPIC` for maximum native performance.
