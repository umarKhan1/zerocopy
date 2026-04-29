#ifndef ZEROCOPY_H
#define ZEROCOPY_H

#include <stddef.h>
#include <stdint.h>

#if _WIN32
#define DART_EXPORT __declspec(dllexport)
#else
#define DART_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Allocates a 64-byte aligned memory buffer of the given size
DART_EXPORT void* get_buffer_address(size_t size);

// Frees the aligned memory buffer
DART_EXPORT void free_buffer_address(void* ptr);

// Acquires the atomic spinlock
DART_EXPORT void lock_buffer();

// Releases the atomic spinlock
DART_EXPORT void unlock_buffer();

#ifdef __cplusplus
}
#endif

#endif // ZEROCOPY_H
