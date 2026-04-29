#include "zerocopy.h"
#include <atomic>
#include <cstdlib>

#if defined(_MSC_VER) || defined(__MINGW32__)
#include <malloc.h>
#endif

// Thread-safe, non-blocking atomic spinlock
std::atomic_flag lock_flag = ATOMIC_FLAG_INIT;

// Helper function for aligned allocation
void* allocate_aligned(size_t alignment, size_t size) {
#if defined(_MSC_VER) || defined(__MINGW32__)
    return _aligned_malloc(size, alignment);
#else
    void* ptr = nullptr;
    if (posix_memalign(&ptr, alignment, size) != 0) {
        return nullptr;
    }
    return ptr;
#endif
}

// Helper function for aligned free
void free_aligned(void* ptr) {
    if (!ptr) return;
#if defined(_MSC_VER) || defined(__MINGW32__)
    _aligned_free(ptr);
#else
    free(ptr);
#endif
}

extern "C" {

DART_EXPORT void* get_buffer_address(size_t size) {
    // We align to 64 bytes for SIMD optimization (fits most cache lines)
    return allocate_aligned(64, size);
}

DART_EXPORT void free_buffer_address(void* ptr) {
    free_aligned(ptr);
}

DART_EXPORT void lock_buffer() {
    // Spin until we acquire the lock
    while (lock_flag.test_and_set(std::memory_order_acquire)) {
        // Optional: yield thread here to prevent 100% CPU usage on contention,
        // but for pure spinlock (zero context switch), we just spin.
    }
}

DART_EXPORT void unlock_buffer() {
    lock_flag.clear(std::memory_order_release);
}

}
