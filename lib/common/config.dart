import 'package:flutter/material.dart';
import 'package:tm/protos/common/net/net.pb.dart';
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';
import 'package:umivpn/theme.dart';

ProxyProtocolLabel getProtocolTypeFromAny(Any any) {
  // unpack the any to the specific config type
  switch (any.typeUrl) {
    case 'type.googleapis.com/x.proxy.ShadowsocksClientConfig':
      return ProxyProtocolLabel.shadowsocks;
    case 'type.googleapis.com/x.proxy.VmessClientConfig':
      return ProxyProtocolLabel.vmess;
    case 'type.googleapis.com/x.proxy.TrojanClientConfig':
      return ProxyProtocolLabel.trojan;
    case 'type.googleapis.com/x.proxy.SocksClientConfig':
      return ProxyProtocolLabel.socks;
    case 'type.googleapis.com/x.proxy.VlessClientConfig':
      return ProxyProtocolLabel.vless;
    case 'type.googleapis.com/x.proxy.Hysteria2ClientConfig':
      return ProxyProtocolLabel.hysteria2;
    default:
      throw Exception('unknown protocol: ${any.typeUrl}');
  }
}


enum ProxyProtocolLabel {
  vmess('VMess'),
  trojan('Trojan'),
  vless('VLESS'),
  shadowsocks('Shadowsocks'),
  socks('Socks'),
  hysteria2('Hysteria2');

  const ProxyProtocolLabel(this.label);
  final String label;
}

/// [ports] should be in format of "123,5000-6000"
/// Return a non empty list if ports is valid, otherwise return null.
List<PortRange>? tryParsePorts(String ports) {
  List<PortRange> pr = [];
  final ranges = ports.split(',');
  for (var r in ranges) {
    if (r.contains('-')) {
      final range = r.split('-');
      if (range.length != 2) {
        return null;
      }
      final from = int.tryParse(range[0]);
      final to = int.tryParse(range[1]);
      if (from == null || to == null) {
        return null;
      }
      pr.add(PortRange(from: from, to:to));
    } else {
      final port = int.tryParse(r);
      if (port == null) {
        return null;
      }
      pr.add(PortRange(from: port, to: port));
    }
  }
  if (pr.isEmpty) {
    return null;
  }
  return pr;
}
