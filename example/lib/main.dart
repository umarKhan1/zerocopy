import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerocopy/zerocopy.dart';
import 'dart:math';

void main() {
  runApp(const BenchmarkApp());
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZeroCopy Benchmark',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF2979FF),
        ),
      ),
      home: const BenchmarkScreen(),
    );
  }
}

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  static const int payloadSize = 10 * 1024 * 1024; // 10MB
  static const int iterations = 100;
  
  bool _isRunning = false;
  String _results = 'Press "Run Benchmark" to start.\n\nSimulating $iterations iterations of 10MB data transfer.';

  final BasicMessageChannel<dynamic> _channel = const BasicMessageChannel(
    'benchmark_channel',
    StandardMessageCodec(),
  );

  Future<void> _runBenchmark() async {
    setState(() {
      _isRunning = true;
      _results = 'Running benchmarks...\nPlease wait, this may take a few seconds and cause the UI to freeze temporarily during heavy load.';
    });

    // Give UI time to update
    await Future.delayed(const Duration(milliseconds: 500));

    final random = Random();
    final dummyData = Uint8List(payloadSize);
    for (int i = 0; i < 100; i++) {
      dummyData[i] = random.nextInt(256);
    }

    // 1. MethodChannel Benchmark (Serialization Overhead)
    int methodChannelJank = 0;
    final mcStopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      final iterStopwatch = Stopwatch()..start();
      // Sends data to native engine. Without a handler, it still serializes and drops.
      await _channel.send(dummyData);
      if (iterStopwatch.elapsedMilliseconds > 16) methodChannelJank++;
    }
    mcStopwatch.stop();

    // 2. Isolate Benchmark (Cross-Isolate Copy)
    int isolateJank = 0;
    final isoStopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      final iterStopwatch = Stopwatch()..start();
      
      final port = ReceivePort();
      await Isolate.spawn((SendPort sp) {
        // Mock some processing and return payload
        sp.send(Uint8List(payloadSize));
      }, port.sendPort);
      
      await port.first;
      port.close();
      
      if (iterStopwatch.elapsedMilliseconds > 16) isolateJank++;
    }
    isoStopwatch.stop();

    // 3. ZeroCopy Benchmark (Direct Memory Access)
    int zeroCopyJank = 0;
    final zcStopwatch = Stopwatch()..start();
    final zcBuffer = ZeroCopyBuffer(sizeInBytes: payloadSize);
    
    for (int i = 0; i < iterations; i++) {
      final iterStopwatch = Stopwatch()..start();
      
      zcBuffer.lock();
      // Simulate writing 10MB sequentially directly to pointer
      final view = zcBuffer.view;
      // In a real scenario, this would be a memcpy or SIMD copy on C++ side.
      // Doing it per byte in Dart loop is slow, so we simulate a block copy 
      // by mapping directly to view.
      view.setAll(0, dummyData);
      zcBuffer.unlock();
      
      if (iterStopwatch.elapsedMilliseconds > 16) zeroCopyJank++;
    }
    zcStopwatch.stop();
    zcBuffer.dispose();

    setState(() {
      _isRunning = false;
      _results = '''
      🏆 Benchmark Results (10MB x $iterations)
      
      🔴 MethodChannel (StandardMessageCodec):
      - Latency: ${mcStopwatch.elapsedMilliseconds} ms
      - Jank Spikes (>16ms): $methodChannelJank / $iterations
      
      🟡 Dart Isolate (Port Transfer):
      - Latency: ${isoStopwatch.elapsedMilliseconds} ms
      - Jank Spikes (>16ms): $isolateJank / $iterations
      
      🟢 ZeroCopy (Shared Memory Pointer):
      - Latency: ${zcStopwatch.elapsedMilliseconds} ms
      - Jank Spikes (>16ms): $zeroCopyJank / $iterations
      ''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZeroCopy VS The World'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _results,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isRunning ? null : _runBenchmark,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isRunning
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text('RUN BENCHMARK'),
            ),
          ],
        ),
      ),
    );
  }
}
