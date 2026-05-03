# Contributing to zerocopy

Thank you for your interest in contributing to `zerocopy`! This guide will help you get set up and ensure your contribution lands smoothly.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Making Changes](#making-changes)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Support](#support)

---

## Code of Conduct

Be respectful and constructive. All contributors are expected to adhere to basic standards of courtesy. Harassment of any kind will not be tolerated.

---

## Getting Started

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally:
   ```sh
   git clone https://github.com/<your-username>/zerocopy.git
   cd zerocopy
   ```
3. **Install dependencies**:
   ```sh
   dart pub get
   cd example && flutter pub get && cd ..
   ```

---

## Development Setup

### Prerequisites

| Tool | Minimum Version | Notes |
| :--- | :--- | :--- |
| Dart SDK | 3.4.0 | Required for Native Assets support |
| Flutter SDK | 3.22.0 | Required for example app |
| C++ compiler | Any modern | Clang/GCC/MSVC — handled automatically by `native_toolchain_c` |

### Verify Your Setup

```sh
dart analyze        # Must pass with zero issues
dart format .       # Must produce no changes
dart test           # Must pass all tests (compiles native assets too)
```

---

## Project Structure

```
zerocopy/
├── hook/
│   └── build.dart            ← Dart 3 Native Assets build hook
├── lib/
│   ├── zerocopy.dart         ← Public library barrel export
│   └── src/
│       ├── domain/
│       │   └── zerocopy_buffer.dart    ← Public API (ZeroCopyBuffer)
│       └── infrastructure/
│           └── zerocopy_ffi_bridge.dart ← @Native FFI bindings
├── src/
│   ├── zerocopy.h            ← C++ public header
│   └── zerocopy.cpp          ← C++ native implementation
├── test/
│   └── zerocopy_test.dart    ← Dart unit tests
└── example/                  ← Full Flutter benchmark app
```

---

## Making Changes

### C++ Changes

- All C++ code must compile on **all five platforms**: Android, iOS, macOS, Windows, Linux.
- Use `#if defined(_MSC_VER) || defined(__MINGW32__)` guards for Windows-specific APIs (e.g., `_aligned_malloc`).
- Do not introduce any external C++ library dependencies.
- Ensure exported symbols are wrapped in `extern "C"` and decorated with `DART_EXPORT`.

### Dart Changes

- All public APIs must have **full `///` dartdoc comments**.
- Keep `lib/src/infrastructure/` private (not exported from the barrel).
- Only `ZeroCopyBuffer` (and any future domain classes) should be exported from `lib/zerocopy.dart`.
- Run `dart format .` and `dart analyze` before committing.

### Tests

- Add tests for any new Dart-layer behaviour in `test/zerocopy_test.dart`.
- The test suite also serves as a native compilation check — tests will fail to compile if the C++ is broken.

---

## Submitting a Pull Request

1. Create a branch: `git checkout -b feat/my-feature` or `fix/my-bug`.
2. Make your changes.
3. Ensure CI passes locally:
   ```sh
   dart format --output=none --set-exit-if-changed .
   dart analyze
   dart test
   ```
4. Update `CHANGELOG.md` under an `## Unreleased` section.
5. Push your branch and open a PR against `main`.
6. Describe **what** changed and **why** in the PR description.

For **major** features or breaking changes, please open a GitHub Issue first to discuss the design before writing code.

---

## Support

- 🌐 Author website: [momarkhan.com](https://momarkhan.com/)
- 💼 LinkedIn: [Muhammad Omar](https://www.linkedin.com/in/muhammad-omar-0335/)
- 🐛 Bug reports: [github.com/umarKhan1/zerocopy/issues](https://github.com/umarKhan1/zerocopy/issues)
