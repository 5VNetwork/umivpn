import 'package:flutter_test/flutter_test.dart';
import 'package:umivpn/common/config.dart';

void main() {
  group('tryParsePorts', () {
    test('should parse single port', () {
      final result = tryParsePorts('123');
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].from, 123);
      expect(result[0].to, 123);
    });

    test('should parse port range', () {
      final result = tryParsePorts('5000-6000');
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].from, 5000);
      expect(result[0].to, 6000);
    });

    test('should parse multiple ports and ranges', () {
      final result = tryParsePorts('123,5000-6000,8080');
      expect(result, isNotNull);
      expect(result!.length, 3);
      expect(result[0].from, 123);
      expect(result[0].to, 123);
      expect(result[1].from, 5000);
      expect(result[1].to, 6000);
      expect(result[2].from, 8080);
      expect(result[2].to, 8080);
    });

    test('should return null for empty input', () {
      final result = tryParsePorts('');
      expect(result, isNull);
    });

    test('should return null for invalid port number', () {
      final result = tryParsePorts('abc');
      expect(result, isNull);
    });

    test('should return null for invalid port range', () {
      final result = tryParsePorts('5000-');
      expect(result, isNull);
    });

    test('should return null for invalid port range format', () {
      final result = tryParsePorts('5000-6000-7000');
      expect(result, isNull);
    });

    test('should return null for invalid port range values', () {
      final result = tryParsePorts('abc-def');
      expect(result, isNull);
    });

    test('should return null for invalid multiple ports', () {
      final result = tryParsePorts('123,abc,456');
      expect(result, isNull);
    });

    test('should return null for invalid multiple ranges', () {
      final result = tryParsePorts('123-456,abc-def,789-012');
      expect(result, isNull);
    });
  });
} 