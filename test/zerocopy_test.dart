import 'package:test/test.dart';
import 'package:zerocopy/zerocopy.dart';

void main() {
  group('ZeroCopyBuffer', () {
    test('allocates and frees memory correctly', () {
      final buffer = ZeroCopyBuffer(sizeInBytes: 1024);
      
      expect(buffer.view.length, 1024);
      
      // Write some data
      for (int i = 0; i < 1024; i++) {
        buffer.view[i] = i % 256;
      }
      
      // Verify data
      for (int i = 0; i < 1024; i++) {
        expect(buffer.view[i], i % 256);
      }
      
      buffer.dispose();
      
      // Accessing view after dispose should throw StateError
      expect(() => buffer.view, throwsStateError);
    });

    test('acquires and releases lock', () {
      final buffer = ZeroCopyBuffer(sizeInBytes: 1024);
      
      // We can't really test thread contention purely in a single-threaded Dart test easily,
      // but we can ensure lock and unlock don't crash or dead-lock when called sequentially.
      buffer.lock();
      buffer.view[0] = 42;
      buffer.unlock();
      
      expect(buffer.view[0], 42);
      
      buffer.dispose();
    });
  });
}
