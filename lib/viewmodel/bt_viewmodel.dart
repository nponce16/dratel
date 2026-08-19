import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';

import '../services/ble_controller.dart';
import '../services/permissions.dart';

/// Bluetooth ViewModel - Manages device scanning and connection
class BluetoothViewModel extends ChangeNotifier {
  final BleController _bleController = BleController();

  // Device scanning
  List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResults => _scanResults;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // Connection state
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _connectedDeviceName;
  String? get connectedDeviceName => _connectedDeviceName;

  String _connectionStatus = 'Disconnected';
  String get connectionStatus => _connectionStatus;

  // Error handling
  String? _lastError;
  String? get lastError => _lastError;

  // Permissions
  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  /// Start scanning for BLE devices
  void startBluetoothScan() async {
    // Request permissions
    final granted = await Permissions.requestBluetoothPermissions();
    if (!granted) {
      _lastError = 'Bluetooth permissions denied';
      notifyListeners();
      debugPrint('Error: Bluetooth permissions denied by user');
      return;
    }

    _hasPermission = true;
    _isScanning = true;
    _scanResults = [];
    _lastError = null;
    notifyListeners();

    await _bleController.startScan();

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });

    // Listen to scanning state
    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });
  }

  /// Stop scanning for BLE devices
  Future<void> stopBluetoothScan() async {
    await _bleController.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a Mondragon device
  Future<void> connectToDevice(ScanResult scanResult) async {
    try {
      _connectionStatus = 'Connecting...';
      _lastError = null;
      notifyListeners();

      debugPrint('BT: Connecting to ${scanResult.device.advName}...');
      final success = await _bleController.connectToDevice(scanResult.device);

      if (success) {
        _isConnected = true;
        _connectedDeviceName = scanResult.device.advName.isEmpty
            ? scanResult.device.remoteId.str
            : scanResult.device.advName;
        _connectionStatus = 'Connected to $_connectedDeviceName';
        _lastError = null;
        debugPrint('BT: Connected successfully to $_connectedDeviceName');
      } else {
        _isConnected = false;
        _connectedDeviceName = null;
        _connectionStatus = 'Connection failed';
        _lastError = 'Failed to setup device characteristics';
        debugPrint('BT: Connection setup failed');
      }
    } catch (e) {
      _isConnected = false;
      _connectedDeviceName = null;
      _connectionStatus = 'Disconnected';
      _lastError = e.toString();
      debugPrint('BT: Connection error - $e');
    }

    notifyListeners();
  }

  /// Disconnect from device
  Future<void> disconnectDevice() async {
    try {
      await _bleController.disconnect();
      _isConnected = false;
      _connectedDeviceName = null;
      _connectionStatus = 'Disconnected';
      _lastError = null;
      debugPrint('BT: Disconnected');
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('BT: Disconnect error - $e');
      notifyListeners();
    }
  }

  // Helper getters for UI
  bool get canConnect => !_isConnected && !_isScanning;
  bool get canDisconnect => _isConnected;
}
