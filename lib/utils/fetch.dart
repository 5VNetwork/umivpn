import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Decrypts the encrypted URLs string using the version secret
Future<List<String>> decryptUrls(
  String encryptedData,
  String versionSecret,
) async {
  // 1. Decode base64
  final combined = base64Decode(encryptedData);

  // 2. Extract IV (first 12 bytes), ciphertext, and MAC (last 16 bytes)
  if (combined.length < 28) { // 12 (IV) + 16 (MAC) minimum
    throw Exception('Encrypted data too short');
  }
  final iv = combined.sublist(0, 12);
  final mac = combined.sublist(combined.length - 16); // Last 16 bytes are the MAC
  final ciphertext = combined.sublist(12, combined.length - 16);

  // 3. Derive key using PBKDF2 (same parameters as JavaScript)
  final salt = utf8.encode('umivpn-salt');
  final secretKey = SecretKey(utf8.encode(versionSecret));

  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256, // 32 bytes = 256 bits
  );

  final derivedKey = await pbkdf2.deriveKey(
    secretKey: secretKey,
    nonce: salt,
  );

  // 4. Create AES-GCM cipher
  final algorithm = AesGcm.with256bits();

  // 5. Decrypt
  final secretBox = SecretBox(
    ciphertext,
    nonce: iv,
    mac: Mac(mac),
  );

  final plaintext = await algorithm.decrypt(
    secretBox,
    secretKey: derivedKey,
  );

  // 6. Decode JSON to get URLs array
  final jsonString = utf8.decode(plaintext);
  final urls = (jsonDecode(jsonString) as List)
      .map((e) => e as String)
      .toList();

  return urls;
}

// Example usage
void main() async {
  final encryptedData = 'your_encrypted_base64_string_here';
  final versionSecret = 'your_version_secret_here';

  try {
    final urls = await decryptUrls(encryptedData, versionSecret);
    print('Decrypted URLs:');
    for (var i = 0; i < urls.length; i++) {
      print('${i + 1}: ${urls[i]}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
