import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
      dartOut: 'lib/utils/windows_host_api.g.dart',
      dartOptions: DartOptions(),
      cppOptions: CppOptions(namespace: 'x'),
      cppHeaderOut: 'windows/runner/messages.g.h',
      cppSourceOut: 'windows/runner/messages.g.cpp'),
)
@HostApi()
abstract class WindowsHostApi {
  // dns requests that is not from the current process and interface index is
  // not [index] will be blocked.
  // Windows only
  void disableDNS({required int index});
  // Windows only
  void undoDisableDNS();
  bool isRunningAsAdmin();
}

// class SplitTunnelSettings {
//   SplitTunnelSettings({this.blackList, this.whiteList});
//   List<String>? blackList;
//   List<String>? whiteList;
// }

@FlutterApi()
abstract class MessageFlutterApi {
  @async
  void notifyShutdown();
}