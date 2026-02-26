import 'dart:io';

String getCpuArch() {
  // Get the Dart VM version string which contains architecture information
  final vmVersion = Platform.version.toLowerCase();
  
  if (vmVersion.contains('arm64') || vmVersion.contains('aarch64')) {
    return 'arm64';
  } else if (vmVersion.contains('x64') || vmVersion.contains('x86_64') || vmVersion.contains('amd64')) {
    return 'amd64';
  } else if (vmVersion.contains('arm')) {
    return 'arm';
  } else if (vmVersion.contains('x86') || vmVersion.contains('ia32')) {
    return 'x86';
  } else {
    return 'unknown';
  }
}