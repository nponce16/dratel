import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../model/ble_protocol.dart';

/// BLE Controller - Manages BLE connection and communication with Mondragon device

class BleController {
  // Singleton
  static final BleController _instance = BleController._internal();
  factory BleController() => _instance;
  BleController._internal();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? txCharacteristic;
  BluetoothCharacteristic? rxCharacteristic;
  late final SequenceNumGenerator _seqGen = SequenceNumGenerator();

  static const String serviceUuid = '5f652760-f56d-4003-9f94-b0a13151e03b';
  static const String txUuid = '5f652761-f56d-4003-9f94-b0a13151e03b';
  static const String rxUuid = '5f652762-f56d-4003-9f94-b0a13151e03b';
  static const Duration timeout = Duration(milliseconds: 2000);
  static const int mtu = 247;

  // -- SCANNING --
  Future<void> startScan() async {
    debugPrint('BLE: Starting scan for Mondragon devices...');

    if (await FlutterBluePlus.isSupported == false) {
      debugPrint('BLE Error: Bluetooth not supported');
      return;
    }

    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // -- CONNECTION --
  /// Connect to a Mondragon device
  /// Returns true if connection and setup was successful
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      debugPrint('BLE: Connecting to ${device.advName} (${device.remoteId})...');
      await device.connect(autoConnect: false);
      connectedDevice = device;
      _seqGen.reset();
      debugPrint('BLE: Connected successfully');
      return await _setupCharacteristics();
    } catch (e) {
      debugPrint('BLE: Connection failed - $e');
      return false;
    }
  }

  /// Discover services and setup TX/RX characteristics
  Future<bool> _setupCharacteristics() async {
    try {
      if (connectedDevice == null) return false;

      // Request MTU size
      await connectedDevice!.requestMtu(mtu);
      debugPrint('BLE: MTU set to $mtu bytes');

      // Discover services
      final services = await connectedDevice!.discoverServices();
      debugPrint('BLE: Found ${services.length} services');

      // Find Mondragon service
      final service = services.firstWhere(
        (s) => s.uuid.str.toLowerCase() == serviceUuid.toLowerCase(),
        orElse: () => throw Exception('Service $serviceUuid not found'),
      );
      debugPrint('BLE: Found Mondragon service');

      // Find TX characteristic (Write)
      txCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid.str.toLowerCase() == txUuid.toLowerCase(),
        orElse: () => throw Exception('TX characteristic $txUuid not found'),
      );

      // Find RX characteristic (Notify)
      rxCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid.str.toLowerCase() == rxUuid.toLowerCase(),
        orElse: () => throw Exception('RX characteristic $rxUuid not found'),
      );

      debugPrint('BLE: TX and RX characteristics found');

      // Subscribe to RX notifications
      await rxCharacteristic!.setNotifyValue(true);
      debugPrint('BLE: Notifications enabled on RX characteristic');

      return true;
    } catch (e) {
      debugPrint('BLE: Setup failed - $e');
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      await connectedDevice?.disconnect();
      connectedDevice = null;
      txCharacteristic = null;
      rxCharacteristic = null;
      debugPrint('BLE: Disconnected');
    } catch (e) {
      debugPrint('BLE: Disconnect error - $e');
    }
  }

  bool get isConnected => connectedDevice != null && connectedDevice!.isConnected;

  // -- COMMUNICATION --
  /// Read a GPIO register (4-byte value)
  /// Throws exception if hardware returns NAK or timeout occurs
  Future<int> readRegister(int address) async {
    if (!isConnected || txCharacteristic == null || rxCharacteristic == null) {
      throw Exception('Not connected to device');
    }

    try {
      final frame = BleFrame(
        command: BleCommand.readReg,
        sequenceNum: _seqGen.next(),
        address: address,
      );

      debugPrint('BLE TX: $frame');
      await txCharacteristic!.write(frame.toBytes(), withoutResponse: true);

      final response = await _waitForResponse(frame.sequenceNum);
      debugPrint('BLE RX: $response');

      if (response.isNak) {
        throw Exception('Hardware error: ${response.errorName}');
      }

      if (response.payload == null) {
        throw Exception('No data in response');
      }

      return BleResponse.bytesToU32(response.payload!);
    } catch (e) {
      debugPrint('BLE: Read error - $e');
      rethrow;
    }
  }

  /// Write a GPIO register (4-byte value)
  /// Throws exception if hardware returns NAK or timeout occurs
  Future<void> writeRegister(int address, int value) async {
    if (!isConnected || txCharacteristic == null || rxCharacteristic == null) {
      throw Exception('Not connected to device');
    }

    try {
      final frame = BleFrame(
        command: BleCommand.writeReg,
        sequenceNum: _seqGen.next(),
        address: address,
        data: BleResponse.u32ToBytes(value),
      );

      debugPrint('BLE TX: $frame');
      await txCharacteristic!.write(frame.toBytes(), withoutResponse: true);

      final response = await _waitForResponse(frame.sequenceNum);
      debugPrint('BLE RX: $response');

      if (response.isNak) {
        throw Exception('Hardware error: ${response.errorName}');
      }
    } catch (e) {
      debugPrint('BLE: Write error - $e');
      rethrow;
    }
  }

  /// Wait for a response matching the sequence number with timeout
  Future<BleResponse> _waitForResponse(int expectedSeq) async {
    if (rxCharacteristic == null) {
      throw Exception('RX characteristic not available');
    }

    final completer = Completer<BleResponse>();
    late StreamSubscription<List<int>> subscription;

    subscription = rxCharacteristic!.onValueReceived.listen(
      (value) {
        try {
          final response = BleResponse.fromBytes(Uint8List.fromList(value));
          if (response.sequenceNum == expectedSeq) {
            subscription.cancel();
            if (!completer.isCompleted) {
              completer.complete(response);
            }
          }
        } catch (e) {
          debugPrint('BLE: Parse error - $e');
        }
      },
    );

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          subscription.cancel();
          throw TimeoutException('No response from device', timeout);
        },
      );
    } catch (e) {
      subscription.cancel();
      rethrow;
    }
  }
}