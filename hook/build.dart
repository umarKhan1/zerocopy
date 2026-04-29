import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    
    final cbuilder = CBuilder.library(
      name: packageName,
      assetName: 'zerocopy.dart',
      sources: [
        'src/zerocopy.cpp',
      ],
      flags: [
        '-O3',
        '-ffast-math',
        '-fPIC',
        '-std=c++17',
      ],
    );

    await cbuilder.run(
      input: input,
      output: output,
    );
  });
}
