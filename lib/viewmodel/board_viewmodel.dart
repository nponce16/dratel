import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../model/board_data.dart';
import '../model/bridge_generated.dart/api.dart' as bridge_api;

class BoardViewModel extends ChangeNotifier {
  BoardDataModel _boardData = BoardDataModel.initial();
  
  bool _isPoweredOn = false;
  bool _isSimulation = false;
  String _status = 'Disconnected';
  Timer? _simulationTimer;
  final Random _random = Random();

  // GPIO Register States
  bridge_api.UsbStatus? _usbStatus;
  bridge_api.PcieStatus? _pcieStatus;
  bridge_api.PwrClkStatus? _pwrClkStatus;
  bridge_api.IntrAlertStatus? _intrAlertStatus;
  bridge_api.InterfaceMuxStatus? _interfaceMuxStatus;

  BoardDataModel get boardData => _boardData;
  String get boardName => _boardData.boardName;
  String get boardId => '0x${_boardData.id.toRadixString(16).toUpperCase().padLeft(4, '0')}';
  int get statusCode => _boardData.status;
  String get status => _status;
  double get frequency => _boardData.frequency;
  double get voltage => _boardData.voltage;
  double get temperature => _boardData.temperature;
  double get humidity => _boardData.humidity;
  double get power => _boardData.power;
  double get pressure => _boardData.pressure;
  bool get isPoweredOn => _isPoweredOn;
  bool get isSimulation => _isSimulation;

  // GPIO Register State Getters
  bridge_api.UsbStatus? get usbStatus => _usbStatus;
  bridge_api.PcieStatus? get pcieStatus => _pcieStatus;
  bridge_api.PwrClkStatus? get pwrClkStatus => _pwrClkStatus;
  bridge_api.IntrAlertStatus? get intrAlertStatus => _intrAlertStatus;
  bridge_api.InterfaceMuxStatus? get interfaceMuxStatus => _interfaceMuxStatus;

  Future<void> toggleSimulationMode(bool value) async {
    _isSimulation = value;
    await bridge_api.setSimulationMode(on_: value);

    if (value) {
      _loadSimulationData();
    } else {
      _stopSensorSimulation();
      if (_isPoweredOn) {
        await fetchRealTimeData();
      } else {
        _clearBoardData();
      }
    }
  }

  Future<void> togglePower() async {
    if (_isPoweredOn) {
      await powerOff();
    } else {
      debugPrint('Power on is handled externally; connect the board instead.');
    }
  }

  Future<void> powerOff() async {
    if (!_isPoweredOn) return;

    if (_isSimulation) {
      await Future.delayed(const Duration(seconds: 1));
      _isPoweredOn = false;
      _status = 'OFF';
      _boardData = _boardData.copyWith(status: 0, voltage: 0.0, power: 0.0);
      _stopSensorSimulation();
      notifyListeners();
      return;
    }

    try {
      final newPowerState = await bridge_api.togglePower();
      _isPoweredOn = newPowerState;
      _status = newPowerState ? 'ON' : 'OFF';
      if (!newPowerState) {
        _boardData = _boardData.copyWith(status: 0, voltage: 0.0, power: 0.0);
      }
    } catch (error) {
      _status = 'Error turning off';
      debugPrint('Board powerOff error: $error');
    }

    _stopSensorSimulation();
    notifyListeners();
  }

  Future<void> manualReset() async {
    if (!_isPoweredOn) {
      debugPrint('Reset command ignored: Board is powered off.');
      return;
    }

    _status = 'Resetting';
    _boardData = _boardData.copyWith(status: 2);
    notifyListeners();

    if (_isSimulation) {
      await _simulateReset();
    } else {
      await _sendHardwareResetCommand();
    }
  }

  Future<void> fetchRealTimeData() async {
    if (_isSimulation) {
      _simulateDataFetch();
    } else {
      await _fetchHardwareData();
    }
  }

  void _loadSimulationData() {
    _isPoweredOn = true;
    _boardData = _boardData.copyWith(
      boardName: 'Mondragon 2.0',
      id: 0xB0A7,
      status: 1,
      frequency: 50.0,
      voltage: 3.3,
      temperature: 35.0,
      humidity: 30.0,
      power: 12.0,
      pressure: 1013.0,
    );
    _status = 'ON';
    _startSensorSimulation();
    notifyListeners();
  }

  void _startSensorSimulation() {
    _stopSensorSimulation();
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isSimulation || !_isPoweredOn) {
        timer.cancel();
        return;
      }

      final humidity = (_boardData.humidity + (_random.nextDouble() - 0.5)).clamp(40.0, 60.0);
      final power = (_boardData.power + (_random.nextDouble() - 0.5) * 1.5).clamp(12.0, 18.0);
      final pressure = (_boardData.pressure + (_random.nextDouble() - 0.5) * 0.4).clamp(1000.0, 1025.0);
      final temperature = (_boardData.temperature + (_random.nextDouble() - 0.5)).clamp(30.0, 45.0);
      final voltage = (_boardData.voltage + (_random.nextDouble() - 0.02)).clamp(3.0, 3.5);

      _boardData = _boardData.copyWith(
        humidity: humidity,
        power: power,
        pressure: pressure,
        temperature: temperature,
        voltage: voltage,
      );
      notifyListeners();
    });
  }

  void _stopSensorSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  @override
  void dispose() {
    _stopSensorSimulation();
    super.dispose();
  }

  Future<void> _simulateReset() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!_isPoweredOn) {
      debugPrint('Reset aborted: Board powered off.');
      return;
    }

    _boardData = _boardData.copyWith(
      status: 1,
      temperature: 30.0,
      humidity: 35.0,
      power: 13.0,
      pressure: 1013.0,
    );
    _status = 'ON';
    notifyListeners();
  }

  void _simulateDataFetch() {
    if (!_isPoweredOn) return;

    final humidity = (_boardData.humidity + (_random.nextDouble() - 0.5)).clamp(40.0, 60.0);
    final power = (_boardData.power + (_random.nextDouble() - 0.5) * 1.5).clamp(12.0, 18.0);
    final pressure = (_boardData.pressure + (_random.nextDouble() - 0.5) * 0.4).clamp(1000.0, 1025.0);
    final temperature = (_boardData.temperature + (_random.nextDouble() - 0.5)).clamp(30.0, 45.0);

    _boardData = _boardData.copyWith(
      humidity: humidity,
      power: power,
      pressure: pressure,
      temperature: temperature,
    );
    notifyListeners();
  }

  void _clearBoardData({String? error}) {
    _stopSensorSimulation();
    _isPoweredOn = false;
    _status = error != null ? 'Error: $error' : 'Disconnected';
    _boardData = BoardDataModel.initial().copyWith(status: 0);
    notifyListeners();
  }

  // REAL HARDWARE LOGIC
  Future<void> _sendHardwareResetCommand() async {
    try {
      await bridge_api.resetCpuApi(); //0x98
      await _fetchHardwareData();
    } catch (error) {
      _clearBoardData(error: 'Reset failed: $error');
    }
  }

  /// Fetches all GPIO register statuses from the hardware
  Future<void> fetchAllGpioStatuses() async {
    if (_isSimulation) {
      debugPrint('[Simulation] GPIO status fetch skipped in simulation mode');
      return;
    }

    try {
      _usbStatus = await bridge_api.readUsbStatus();
      _pcieStatus = await bridge_api.readPcieStatus();
      _pwrClkStatus = await bridge_api.readPwrClkStatus();
      _intrAlertStatus = await bridge_api.readIntrAlertStatus();
      _interfaceMuxStatus = await bridge_api.readInterfaceMuxStatus();
      notifyListeners();
    } catch (error) {
      debugPrint('GPIO status fetch error: $error');
    }
  }

  Future<void> _fetchHardwareData() async {
    try {
      final telemetry = await bridge_api.getTelemetry();
      
      _isPoweredOn = telemetry.powerOn;
      _status = telemetry.powerOn ? 'ON' : 'OFF';
      
      _boardData = _boardData.copyWith(
        boardName: telemetry.name,
        status: telemetry.powerOn ? 1 : 0,
        voltage: telemetry.voltage,
        temperature: telemetry.temperature,
        frequency: telemetry.frequency,
        humidity: telemetry.humidity,
        power: telemetry.power,
        pressure: telemetry.pressure,
      );

      // Fetch all GPIO statuses after telemetry
      await fetchAllGpioStatuses();
    } catch (error) {
      _status = 'Error reading hardware';
      debugPrint('Hardware fetch error: $error');
    }
    notifyListeners();
  }

  // ============================================================================
  // Control Wrappers: USB Controls
  // ============================================================================

  /// Toggles USB0 power switch
  Future<void> toggleUsb0Power(bool enable) async {
    if (_isSimulation) {
      debugPrint('[Simulation] Toggling USB0 power to: $enable');
      return;
    }

    try {
      await bridge_api.toggleUsb0Power(enable: enable);
      await fetchAllGpioStatuses();
    } catch (error) {
      debugPrint('USB0 power toggle error: $error');
      _status = 'USB0 control error';
      notifyListeners();
    }
  }

  /// Toggles USB0 reset line
  Future<void> toggleUsb0Reset(bool enable) async {
    if (_isSimulation) {
      debugPrint('[Simulation] Toggling USB0 reset to: $enable');
      return;
    }

    try {
      await bridge_api.toggleUsb0Reset(enable: enable);
      await fetchAllGpioStatuses();
    } catch (error) {
      debugPrint('USB0 reset toggle error: $error');
      _status = 'USB0 reset error';
      notifyListeners();
    }
  }

  /// Toggles USB1 power switch
  Future<void> toggleUsb1Power(bool enable) async {
    if (_isSimulation) {
      debugPrint('[Simulation] Toggling USB1 power to: $enable');
      return;
    }

    try {
      await bridge_api.toggleUsb1Power(enable: enable);
      await fetchAllGpioStatuses();
    } catch (error) {
      debugPrint('USB1 power toggle error: $error');
      _status = 'USB1 control error';
      notifyListeners();
    }
  }

  /// Toggles USB1 reset line
  Future<void> toggleUsb1Reset(bool enable) async {
    if (_isSimulation) {
      debugPrint('[Simulation] Toggling USB1 reset to: $enable');
      return;
    }

    try {
      await bridge_api.toggleUsb1Reset(enable: enable);
      await fetchAllGpioStatuses();
    } catch (error) {
      debugPrint('USB1 reset toggle error: $error');
      _status = 'USB1 reset error';
      notifyListeners();
    }
  }

  // ============================================================================
  // Control Wrappers: Power & Clock Management
  // ============================================================================

  /// Sets SATA connector power level (0-15)
  Future<void> setSataPower(int level) async {
    if (_isSimulation) {
      debugPrint('[Simulation] Setting SATA power level to: $level');
      return;
    }

    try {
      await bridge_api.setSataPower(level: level);
      await fetchAllGpioStatuses();
    } catch (error) {
      debugPrint('SATA power control error: $error');
      _status = 'SATA power error';
      notifyListeners();
    }
  }

  /// Toggles SerDes clock enable
  Future<void> toggleSerdesClock(bool enable) async {
    if (_isSimulation) {
      debugPrint('[Simulation] Toggling SerDes clock to: $enable');
      return;
    }

    try {
      await bridge_api.toggleSerdesClock(enable: enable);
      await fetchAllGpioStatuses();
    } catch (error) {
      debugPrint('SerDes clock toggle error: $error');
      _status = 'SerDes clock error';
      notifyListeners();
    }
  }

  /// Toggles I2C MUX reset
  Future<void> toggleI2cMuxReset(bool enable) async {
    if (_isSimulation) {
      debugPrint('[Simulation] Toggling I2C MUX reset to: $enable');
      return;
    }

    try {
      await bridge_api.toggleI2CMuxReset(enable: enable);
      await fetchAllGpioStatuses();
    } catch (error) {
      debugPrint('I2C MUX reset toggle error: $error');
      _status = 'I2C MUX reset error';
      notifyListeners();
    }
  }

  /// Toggles FTDI reset
  Future<void> toggleFtdiReset(bool enable) async {
    if (_isSimulation) {
      debugPrint('[Simulation] Toggling FTDI reset to: $enable');
      return;
    }

    try {
      await bridge_api.toggleFtdiReset(enable: enable);
      await fetchAllGpioStatuses();
    } catch (error) {
      debugPrint('FTDI reset toggle error: $error');
      _status = 'FTDI reset error';
      notifyListeners();
    }
  }

  // ============================================================================
  // Control Wrappers: PCIe Management
  // ============================================================================

  /// Sets PCIe output level (0-15)
  Future<void> setPcieOutputs(int level) async {
    if (_isSimulation) {
      debugPrint('[Simulation] Setting PCIe outputs to: $level');
      return;
    }

    try {
      await bridge_api.setPcieOutputs(level: level);
      await fetchAllGpioStatuses();
    } catch (error) {
      debugPrint('PCIe outputs control error: $error');
      _status = 'PCIe control error';
      notifyListeners();
    }
  }
}