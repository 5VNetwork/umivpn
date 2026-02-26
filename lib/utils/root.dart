
import 'dart:io';

Future<bool> checkLinuxRootPrivileges() async {
  try {
    final result = await Process.run('id', ['-u']);
    return result.exitCode == 0 && result.stdout.toString().trim() == '0';
  } catch (e) {
    return false;
  }
}