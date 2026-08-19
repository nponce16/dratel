import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

class Permissions {
  static Future<bool> requestBluetoothPermissions() async {
    try {
      if (Platform.isAndroid) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();

        final isScanGranted = statuses[Permission.bluetoothScan] ==
            PermissionStatus.granted;
        final isConnectedGranted = statuses[Permission.bluetoothConnect] ==
            PermissionStatus.granted;
        final isLocationGranted = statuses[Permission.location] ==
            PermissionStatus.granted;

        return isScanGranted && isConnectedGranted && isLocationGranted;
      }
      else if (Platform.isIOS || Platform.isMacOS) {
        var status = await Permission.bluetooth.request();
        return status == PermissionStatus.granted;
      }
      else if (Platform.isLinux || Platform.isWindows) {
        return true;
      }
    } catch(e) {
      debugPrint("Permission Error: $e");
      return false;
    }
    // Default
    return false;
  }
}