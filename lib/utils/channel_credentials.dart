import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';

class MyChannelCredentials extends ChannelCredentials {
  MyChannelCredentials.secure({
    this.clientCertBytes,
    this.clientCertPrivateKeyBytes,
    this.trustedServerCertBytes, //server CA or cert
    BadCertificateHandler? badCertificate,
    String? sni,
  }) : super.secure(
         certificates: trustedServerCertBytes,
         onBadCertificate: badCertificate,
         authority: sni,
       );

  final Uint8List? clientCertBytes;
  final Uint8List? clientCertPrivateKeyBytes;
  final Uint8List? trustedServerCertBytes;

  @override
  SecurityContext? get securityContext {
    final ctx = super.securityContext!;
    if (clientCertBytes != null && clientCertPrivateKeyBytes != null) {
      ctx.useCertificateChainBytes(clientCertBytes!);
      ctx.usePrivateKeyBytes(clientCertPrivateKeyBytes!);
    }
    return ctx;
  }
}
