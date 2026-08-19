import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../viewmodel/bt_viewmodel.dart';

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text(
          "Bluetooth Devices",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        actions: [
          Consumer<BluetoothViewModel>(
            builder: (context, viewModel, child) {
              return TextButton(
                onPressed: () {
                 if (viewModel.isScanning) {
                   viewModel.stopBluetoothScan();
                 }
                 else {
                   viewModel.startBluetoothScan();
                 }
                },

                child: viewModel.isScanning
                  ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoActivityIndicator(),
                      SizedBox(width: 6),
                      Text(
                        "Stop",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                  : const Text(
                    "Scan",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
              );
            },
          )
        ],
      ),

      body: Consumer<BluetoothViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16,24,16,8),
                child: Text(
                  "OTHER DEVICES",
                  style: TextStyle(
                    fontSize: 13,
                    // color: Color(0xFF8E8E93),  //iOS style
                  ),
                ),
              ),

              Expanded(child: _buildDeviceList(viewModel)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceList(BluetoothViewModel viewModel) {
    if (viewModel.scanResults.isEmpty && !viewModel.isScanning) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(
          child: Text(
            "Tap to refresh to find devices",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),

      // List view
      child: ListView.separated(
        itemCount: viewModel.scanResults.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 16, // Line starts slightly to the right
          color: Color(0xFFE5E5EA),
        ),
        itemBuilder: (context, index) {
          final result = viewModel.scanResults[index];
          final deviceName = result.device.advName.isNotEmpty
              ? result.device.advName
              : "Unknown Device";

          final deviceMacAddress = result.device.remoteId.toString();

          return ListTile(
            title: Text(
              deviceName,
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: Text(
              deviceMacAddress,
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            trailing: const Text(
              "Not Connected",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            onTap: () {
              debugPrint("Tapped on: $deviceName");
            },
          );
        },
      ),
    );
  }
}