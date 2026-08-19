import 'package:flutter/foundation.dart';

import 'board_viewmodel.dart';

// Register information
class RegisterData {
  final String name;
  final String category;
  final List<String> options;
  String? selectedValue;

  RegisterData({
    required this.name,
    required this.category,
    required this.options,
    this.selectedValue,
  });
}

class ConfigurationViewModel extends ChangeNotifier {
  final BoardViewModel boardViewModel;

  List<RegisterData> _registers = [];
  List<RegisterData> get registers => _registers;

  bool _isCurrentlySim = true;

  ConfigurationViewModel({required this.boardViewModel}) {
    loadHardwareRegisters();

    boardViewModel.addListener(() {
      if (_isCurrentlySim != boardViewModel.isSimulation) {
        _isCurrentlySim = boardViewModel.isSimulation;
        loadHardwareRegisters();
      }
    });
  }

  void loadHardwareRegisters() {
    if (boardViewModel.isSimulation) {
      _registers = [
        // --- USB REG ---
        RegisterData(
          name: 'usb0 pow sw',
          category: 'USB REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'usb0 reset',
          category: 'USB REG',
          options: ['Reset'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'usb0 hs led',
          category: 'USB REG',
          options: [],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'usb0 detect led',
          category: 'USB REG',
          options: [],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'usb1 pow sw',
          category: 'USB REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'usb1 reset',
          category: 'USB REG',
          options: ['Reset'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'usb1 hs led',
          category: 'USB REG',
          options: [],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'usb1 detect led',
          category: 'USB REG',
          options: [],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'usb-c esd status',
          category: 'USB REG',
          options: [],
          selectedValue: 'Disabled',
        ),

        // --- PCI-e REG ---
        RegisterData(
          name: 'PCIe status',
          category: 'PCI-e REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'PCIe outputs',
          category: 'PCI-e REG',
          options: ['Disabled', 'Output 0', 'Output 1', 'Both Outputs'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'PCIe ss_sel_tri',
          category: 'PCI-e REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'PCIe buffer state',
          category: 'PCI-e REG',
          options: ['Disabled', 'Source 0', 'Source 1'],
          selectedValue: 'Disabled',
        ),

        // --- INT and ALERT REG ---
        RegisterData(
          name: "ASIC's eth int",
          category: 'INT and ALERT REG',
          options: [],
          selectedValue: '-',
        ),
        RegisterData(
          name: "Alert sig ASIC's monitor",
          category: 'INT and ALERT REG',
          options: [],
          selectedValue: '-',
        ),
        RegisterData(
          name: 'ADC int',
          category: 'INT and ALERT REG',
          options: [],
          selectedValue: '-',
        ),
        RegisterData(
          name: "Motherboard's eth int",
          category: 'INT and ALERT REG',
          options: [],
          selectedValue: '-',
        ),

        // --- PWR and CLK REG ---
        RegisterData(
          name: 'PMIC control',
          category: 'PWR and CLK REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'Sata Connector (J21) Power',
          category: 'PWR and CLK REG',
          options: ['Disabled', 'Port 5V', 'Port 12V', 'Both Ports'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'SerDes clk en',
          category: 'PWR and CLK REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'I2C mux reset',
          category: 'PWR and CLK REG',
          options: ['Reset'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'FTDI reset',
          category: 'PWR and CLK REG',
          options: ['Reset'],
          selectedValue: 'Disabled',
        ),

        // --- INTERFACE MUX REG ---
        RegisterData(
          name: 'brom_sd enable',
          category: 'INTERFACE MUX REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'rom_sd selector',
          category: 'INTERFACE MUX REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'uart-asic/ftdi mux',
          category: 'INTERFACE MUX REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'jtag-asic/ftdi mux',
          category: 'INTERFACE MUX REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'sata-e redriver enable',
          category: 'INTERFACE MUX REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'displayport redriver',
          category: 'INTERFACE MUX REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'PMOD spi',
          category: 'INTERFACE MUX REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
        RegisterData(
          name: 'I2S-Audio DAC/Gain',
          category: 'INTERFACE MUX REG',
          options: ['Enabled', 'Disabled'],
          selectedValue: 'Disabled',
        ),
      ];
    } else {
      // TODO: Implement Bluetooth
      // 1. Request the 64 registers via BLE.
      // 2. Parse the incoming bytes from Rust.
      _registers = [];
    }
    notifyListeners();
  }

  void updateRegisterValue(int index, String? newValue) {
    if (newValue != null && _registers[index].selectedValue != newValue) {
      _registers[index].selectedValue = newValue;
      notifyListeners();

      if (!boardViewModel.isSimulation) {
        // TODO: Send write command via Bluetooth to update the specific register on the board.
      }
    }
  }
}