import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current;
  final pin = jsonDecode(
    File('${root.path}/toolchain.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  if (pin['flutter_version'] != '3.47.7' ||
      pin['dart_version'] != '3.13.5' ||
      pin['bundle_identifier'] != 'com.infinityball.cordcard') {
    throw StateError('Toolchain or bundle identifier changed');
  }
  final markers = <String, String>{
    'windows/CMakeLists.txt': 'set(BINARY_NAME "cord_card")',
    'windows/runner/main.cpp': 'Win32Window',
    'android/app/build.gradle.kts':
        'applicationId = "com.infinityball.cordcard"',
    'android/app/src/main/kotlin/com/infinityball/cordcard/MainActivity.kt':
        'package com.infinityball.cordcard',
    'ios/Runner.xcodeproj/project.pbxproj':
        'PRODUCT_BUNDLE_IDENTIFIER = com.infinityball.cordcard;',
    'android/gradle/wrapper/gradle-wrapper.properties': 'gradle-9.3.1-all.zip',
  };
  for (final entry in markers.entries) {
    if (!File('${root.path}/${entry.key}')
        .readAsStringSync()
        .contains(entry.value)) {
      throw StateError('Invalid platform scaffold: ${entry.key}');
    }
  }
  for (final path in [
    'android/gradlew',
    'android/gradlew.bat',
    'android/gradle/wrapper/gradle-wrapper.jar',
    'ios/Runner/Info.plist',
    'windows/runner/resources/app_icon.ico',
  ]) {
    if (File('${root.path}/$path').lengthSync() == 0) {
      throw StateError('Empty platform file: $path');
    }
  }
  stdout.writeln('Platform scaffolds and IDs verified: Windows, Android, iOS');
}
