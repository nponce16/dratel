// BLE Protocol Definition for Mondragon
// 
// Implements the serial protocol for communication over BLE.
// - TX Characteristic: Write (without response)
// - RX Characteristic: Notify
// - MTU: 247 bytes
// - Timeout: 1000-2000 ms per operation
// - Sequence Numbers: 1-255 (wraps to 1)

import 'dart:typed_data';

class BleCommand {
  static const int ack = 0x00;
  static const int nak = 0x01;
  static const int readReg = 0x03;
  static const int writeReg = 0x04;
  static const int resetCpu = 0x98;
  static const int shutdown = 0x99;
}

class BleErrorCode {
  static const Map<int, String> errorNames = {
    0x01: 'InvalidCommand',
    0x02: 'InvalidAddress',
    0x03: 'WriteProtected',
    0x04: 'SequenceMismatch',
    0x05: 'HardwareFault',
    0x06: 'DeviceBusy',
    0x07: 'PayloadCorrupted',
    0x08: 'ValueOutOfRange',
    0x09: 'HardwareTimeOut',
    0x0A: 'InvalidFloat',
  };

  static String getName(int code) => errorNames[code] ?? 'UnknownError';
}

/// Represents a BLE protocol frame
class BleFrame {
  final int command;
  final int sequenceNum;
  final int? address;
  final Uint8List? data;

  BleFrame({
    required this.command,
    required this.sequenceNum,
    this.address,
    this.data,
  });

  /// Serialize frame to bytes according to protocol specification
  Uint8List toBytes() {
    switch (command) {
      case BleCommand.readReg:
        // TX: [0x03, seq_num, addr]
        if (address == null) throw ArgumentError('readReg requires address');
        return Uint8List.fromList([command, sequenceNum, address!]);

      case BleCommand.writeReg:
        // TX: [0x04, seq_num, addr, data0, data1, data2, data3]
        if (address == null || data == null || data!.length != 4) {
          throw ArgumentError('writeReg requires 4-byte data payload');
        }
        final buffer = <int>[command, sequenceNum, address!];
        buffer.addAll(data!);
        return Uint8List.fromList(buffer);

      case BleCommand.resetCpu:
        // TX: [0x98, seq_num]
        return Uint8List.fromList([command, sequenceNum]);

      case BleCommand.shutdown:
        // TX: [0x99, seq_num]
        return Uint8List.fromList([command, sequenceNum]);

      default:
        throw ArgumentError('Unknown command: 0x${command.toRadixString(16)}');
    }
  }

  @override
  String toString() =>
      'BleFrame(cmd:0x${command.toRadixString(16)}, seq:$sequenceNum, addr:$address, data_len:${data?.length ?? 0})';
}

/// Represents a BLE protocol response
class BleResponse {
  final int command; // 0x00=ACK, 0x01=NAK
  final int sequenceNum;
  final int? errorCode; // For NAK responses
  final Uint8List? payload; // For ACK with data (4 bytes)

  BleResponse({
    required this.command,
    required this.sequenceNum,
    this.errorCode,
    this.payload,
  });

  bool get isAck => command == BleCommand.ack;
  bool get isNak => command == BleCommand.nak;

  String? get errorName => isNak ? BleErrorCode.getName(errorCode ?? 0) : null;

  /// Parse response from received bytes
  static BleResponse fromBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError('Empty response bytes');
    }

    final cmd = bytes[0];
    final seq = bytes.length > 1 ? bytes[1] : 0;

    if (cmd == BleCommand.ack) {
      // ACK: [0x00, seq_num, data0, data1, data2, data3]
      if (bytes.length >= 6) {
        final payload = Uint8List.fromList(bytes.sublist(2, 6));
        return BleResponse(
          command: cmd,
          sequenceNum: seq,
          payload: payload,
        );
      }
      // ACK without data: [0x00, seq_num]
      return BleResponse(command: cmd, sequenceNum: seq);
    } else if (cmd == BleCommand.nak) {
      // NAK: [0x01, seq_num, error_code]
      final errorCode = bytes.length > 2 ? bytes[2] : 0xFF;
      return BleResponse(
        command: cmd,
        sequenceNum: seq,
        errorCode: errorCode,
      );
    } else {
      throw ArgumentError('Invalid response command: 0x${cmd.toRadixString(16)}');
    }
  }

  @override
  String toString() {
    if (isAck) {
      if (payload != null) {
        final value = bytesToU32(payload!);
        return 'BleResponse.ACK(seq:$sequenceNum, data:0x${value.toRadixString(16)})';
      }
      return 'BleResponse.ACK(seq:$sequenceNum)';
    } else {
      return 'BleResponse.NAK(seq:$sequenceNum, error:$errorName)';
    }
  }

  /// Convert little-endian bytes to u32
  static int bytesToU32(Uint8List bytes) {
    if (bytes.length < 4) throw ArgumentError('Need at least 4 bytes');
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
  }

  /// Convert u32 to little-endian bytes
  static Uint8List u32ToBytes(int value) {
    return Uint8List.fromList([
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ]);
  }
}

/// Protocol helper for sequence number management
class SequenceNumGenerator {
  int _current = 0;

  int next() {
    _current++;
    if (_current > 255) _current = 1; // Wraps to 1 (not 0)
    return _current;
  }

  void reset() => _current = 0;
}
