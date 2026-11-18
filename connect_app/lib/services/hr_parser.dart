// Pure packet parsing for Fireboltt 124 heart-rate notifications.
//
// No Bluetooth or Flutter imports here on purpose, so this file can be
// unit tested without a device.

/// Every heart-rate packet starts with these 4 bytes: BC 5C 03 01.
const List<int> hrPacketPrefix = [0xBC, 0x5C, 0x03, 0x01];

/// Index of the heart-rate byte (the 5th byte). Byte 5 repeats the same value.
const int hrBpmIndex = 4;

/// Values outside this range are treated as invalid.
const int minValidBpm = 30;
const int maxValidBpm = 220;

/// Returns the BPM in [packet], or null if the packet is not a valid
/// heart-rate packet (wrong prefix, too short, or BPM out of range).
int? parseHeartRate(List<int> packet) {
  if (packet.length <= hrBpmIndex) return null;

  for (var i = 0; i < hrPacketPrefix.length; i++) {
    if (packet[i] != hrPacketPrefix[i]) return null;
  }

  final bpm = packet[hrBpmIndex];
  if (bpm < minValidBpm || bpm > maxValidBpm) return null;
  return bpm;
}

/// Formats bytes as spaced, uppercase hex, e.g. "BC 5C 03 01 67 67".
String toHex(List<int> bytes) => bytes
    .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
    .join(' ');
