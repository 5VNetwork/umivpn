import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/utils/darwin_host_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'darwin/Messages.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
@HostApi()
abstract class DarwinHostApi {
  String appGroupPath();
  @async
  void startXApiServer(Uint8List config);
  @async
  void redirectStdErr(String path);
  Uint8List generateTls();
  void setupShutdownNotification();
}

@FlutterApi()
abstract class DarwinFlutterApi {
  void onSystemWillShutdown();
  void onSystemWillRestart();
  void onSystemWillSleep();
}

// class SplitTunnelSettings {
//   SplitTunnelSettings({this.blackList, this.whiteList});
//   List<String>? blackList;
//   List<String>? whiteList;
// }
