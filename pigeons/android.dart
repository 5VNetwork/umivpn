import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/utils/android_host_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/app/src/main/kotlin/com5vnetwork/umi/Messages.g.kt',
    kotlinOptions: KotlinOptions(),
  ),
)
@HostApi()
abstract class AndroidHostApi {
  @async
  void startXApiServer(Uint8List config);
  Uint8List generateTls();
  void redirectStdErr(String path);
  void requestAddTile();
  void startBindToDefaultNetwork();
}

@FlutterApi()
abstract class AndroidFlutterApi {
  void defaultNetworkChanged(bool isPhysical);
}
