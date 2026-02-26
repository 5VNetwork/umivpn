import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateHMAC_SHA256(String message, List<int> secretBytes) {
  final messageBytes = utf8.encode(message);
  final hmacSha256 = Hmac(sha256, secretBytes);
  final digest = hmacSha256.convert(messageBytes);
  return digest.toString();
}
