import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:umivpn/utils/logger.dart';

class ScanQrCode extends StatefulWidget {
  const ScanQrCode({super.key});

  @override
  State<ScanQrCode> createState() => _ScanQrCodeState();
}

class _ScanQrCodeState extends State<ScanQrCode> {
  bool _popOnce = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: MobileScanner(
        onDetect: (result) {
          if (result.barcodes.isNotEmpty) {
            if (!_popOnce) {
              _popOnce = true;
              Navigator.of(context).pop(result.barcodes.first);
            }
          }
        },
      ),
    );
  }
}
