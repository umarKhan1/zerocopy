# zerocopy — Example & Benchmark App

This Flutter application demonstrates the `zerocopy` package and benchmarks its performance against two traditional data-transfer methods.

## What It Benchmarks

| Method | Description |
| :--- | :--- |
| **MethodChannel** | Standard Flutter platform channel — serializes data on every call |
| **Dart Isolate** | Sends data via `SendPort` — copies into the isolate's memory space |
| **ZeroCopy** | Shares a native C++ memory address directly — **zero serialization** |

## Running the Benchmark

Run in **profile mode** for accurate, JIT-warm numbers without debug overhead:

```sh
flutter run --profile
```

The app runs each method **100 times** with a **10 MB** payload and reports:

- Total latency (ms)
- Number of jank frames (>16 ms)
- Qualitative GC heap impact

## Expected Results

| Method | Total Latency | Jank Frames |
| :--- | :--- | :--- |
| MethodChannel | ~4,200 ms | 100 / 100 |
| Dart Isolate | ~1,800 ms | 85 / 100 |
| **ZeroCopy** | **< 10 ms** | **0 / 100** |

## Support

- 🌐 [momarkhan.com](https://momarkhan.com/)
- 💼 [LinkedIn](https://www.linkedin.com/in/muhammad-omar-0335/)
- 🐛 [File an issue](https://github.com/umarKhan1/zerocopy/issues)
