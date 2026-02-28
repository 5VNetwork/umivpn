import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const geoipUrls = [
  'https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat',
  'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat',
];
const geositeUrls = [
  'https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat',
  'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat',
];

const geoIPPathDebug = '../../../../temp/geoip.dat';
const geositePathDebug = '../../../../temp/geosite.dat';

const nsCfIp = '1.1.1.1';
const googleDnsIp = '8.8.8.8';
const ns223Ip = '223.5.5.5';
const oneFourFourDnsIp = '114.114.114.114';
const localhost = 'localhost';

const boxH4 = SizedBox(
  height: 4,
);

const boxH8 = SizedBox(
  height: 8,
);

const boxH10 = SizedBox(
  height: 10,
);

const boxW4 = SizedBox(
  width: 4,
);

const boxW10 = SizedBox(
  width: 10,
);

const boxW20 = SizedBox(
  width: 20,
);

// const outboundHandlerGroup = 'outboundHandlerGroup';
// const outboundHandlerConfig = 'outboundHandlerConfig';
// const dnsRecord = 'dnsRecord';
// const geoDomain = 'geoDomain';
// const geoCidr = 'geoCidr';
// const persistentAppState = 'persistentAppState';

const cfCdnIp4Ranges = [
  '173.245.48.0/20',
  '103.21.244.0/22',
  '103.22.200.0/22',
  '103.31.4.0/22',
  '141.101.64.0/18',
  '108.162.192.0/18',
  '190.93.240.0/20',
  '188.114.96.0/20',
  '197.234.240.0/22',
  '198.41.128.0/17',
  '162.158.0.0/15',
  '104.16.0.0/13',
  '104.24.0.0/14',
  '172.64.0.0/13',
  '131.0.72.0/22',
];

const cfCdnIp6Ranges = [
  '2400:cb00::/32',
  '2606:4700::/32',
  '2803:f800::/32',
  '2405:b500::/32',
  '2405:8100::/32',
  '2a06:98c0::/29',
  '2c0f:f248::/32',
];
