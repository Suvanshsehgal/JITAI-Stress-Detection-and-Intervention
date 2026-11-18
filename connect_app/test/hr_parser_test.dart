import 'package:flutter_test/flutter_test.dart';

import 'package:connect_app/services/hr_parser.dart';

void main() {
  group('parseHeartRate', () {
    test('BC-5C-03-01-67-67 decodes to 103 BPM', () {
      expect(parseHeartRate([0xBC, 0x5C, 0x03, 0x01, 0x67, 0x67]), 103);
    });

    test('BC-5C-03-01-4A-4A decodes to 74 BPM', () {
      expect(parseHeartRate([0xBC, 0x5C, 0x03, 0x01, 0x4A, 0x4A]), 74);
    });

    test('accepts the boundary values 30 and 220', () {
      expect(parseHeartRate([0xBC, 0x5C, 0x03, 0x01, 30, 30]), 30);
      expect(parseHeartRate([0xBC, 0x5C, 0x03, 0x01, 220, 220]), 220);
    });

    test('rejects values outside 30..220', () {
      expect(parseHeartRate([0xBC, 0x5C, 0x03, 0x01, 29, 29]), isNull);
      expect(parseHeartRate([0xBC, 0x5C, 0x03, 0x01, 221, 221]), isNull);
      expect(parseHeartRate([0xBC, 0x5C, 0x03, 0x01, 0, 0]), isNull);
      expect(parseHeartRate([0xBC, 0x5C, 0x03, 0x01, 0xFF, 0xFF]), isNull);
    });

    test('ignores the 10-byte BC-48-03-05 packet type', () {
      final packet = [0xBC, 0x48, 0x03, 0x05, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05];
      expect(parseHeartRate(packet), isNull);
    });

    test('rejects a wrong prefix', () {
      expect(parseHeartRate([0xBC, 0x5C, 0x03, 0x02, 0x67, 0x67]), isNull);
      expect(parseHeartRate([0xAA, 0x5C, 0x03, 0x01, 0x67, 0x67]), isNull);
    });

    test('rejects packets too short to contain the BPM byte', () {
      expect(parseHeartRate([]), isNull);
      expect(parseHeartRate([0xBC, 0x5C, 0x03, 0x01]), isNull);
    });
  });

  group('toHex', () {
    test('formats bytes as spaced uppercase hex', () {
      expect(toHex([0xBC, 0x5C, 0x03, 0x01, 0x67, 0x67]), 'BC 5C 03 01 67 67');
    });

    test('pads single-digit bytes with a leading zero', () {
      expect(toHex([0x00, 0x0A, 0xFF]), '00 0A FF');
    });
  });
}
