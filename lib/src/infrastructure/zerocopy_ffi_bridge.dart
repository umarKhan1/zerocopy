import 'dart:ffi';

// Define the asset ID matching the hook/build.dart assetName
const String _assetName = 'package:zerocopy/zerocopy.dart';

@Native<Pointer<Void> Function(Size)>(assetId: _assetName)
external Pointer<Void> get_buffer_address(int size);

@Native<Void Function(Pointer<Void>)>(assetId: _assetName)
external void free_buffer_address(Pointer<Void> ptr);

// Export the function pointer for NativeFinalizer
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    freeBufferAddressPtr =
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
        free_buffer_address);

@Native<Void Function()>(assetId: _assetName)
external void lock_buffer();

@Native<Void Function()>(assetId: _assetName)
external void unlock_buffer();
