import 'dart:ffi';

// Define the asset ID matching the hook/build.dart assetName
const String _assetName = 'package:zerocopy/zerocopy.dart';

@Native<Pointer<Void> Function(Size)>(
    assetId: _assetName, symbol: 'get_buffer_address')
external Pointer<Void> getBufferAddress(int size);

@Native<Void Function(Pointer<Void>)>(
    assetId: _assetName, symbol: 'free_buffer_address')
external void freeBufferAddress(Pointer<Void> ptr);

// Export the function pointer for NativeFinalizer
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    freeBufferAddressPtr =
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(
        freeBufferAddress);

@Native<Void Function()>(assetId: _assetName, symbol: 'lock_buffer')
external void lockBuffer();

@Native<Void Function()>(assetId: _assetName, symbol: 'unlock_buffer')
external void unlockBuffer();
