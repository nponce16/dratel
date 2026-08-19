class BoardDataModel {
  // --- Telemetry ---
  final String boardName;
  final int id;
  final int status;
  final double frequency;
  final double voltage;
  final double temperature;
  final double humidity;
  final double power;
  final double pressure;

  // --- GPIO Registers ---
  // USB & PCI-E
  final bool usb0PowSw;
  final bool usb0Reset;
  final bool usb0HsLed;
  final bool usb0DetectedLed;
  final bool usb1PowSw;
  final bool usb1Reset;
  final bool usb1HsLed;
  final bool usb1DetectedLed;
  final bool usbcEsdStatus;
  final bool pcieStatus;
  final int pcieOutputs;
  final bool pcieSsSelTri;
  final int pcieBufferState;

  // INT & ALERT
  final bool asicEthInt;
  final bool alertSigAsicMonitor;
  final bool adcInt;
  final bool motherboardEthInt;

  // Power, Clocks & Resets
  final bool pmicControl;
  final int sataConnectorJ21Power;
  final bool sedesClkEn;
  final bool i2cMuxReset;
  final bool ftdiReset;
  final bool bromSdEn;
  final int bromSdSel;

  // Muxers & Peripherals
  final int uartAsicFtdiMux;
  final int jtagAsicFtdiMux;
  final bool sataERedriverEn;
  final bool displayportRedriver;
  final int pmodSpi;
  final int i2sAudioDacGain;

  BoardDataModel({
    required this.boardName,
    required this.id,
    required this.status,
    required this.frequency,
    required this.voltage,
    required this.temperature,
    required this.humidity,
    required this.power,
    required this.pressure,
    required this.usb0PowSw,
    required this.usb0Reset,
    required this.usb0HsLed,
    required this.usb0DetectedLed,
    required this.usb1PowSw,
    required this.usb1Reset,
    required this.usb1HsLed,
    required this.usb1DetectedLed,
    required this.usbcEsdStatus,
    required this.pcieStatus,
    required this.pcieOutputs,
    required this.pcieSsSelTri,
    required this.pcieBufferState,
    required this.asicEthInt,
    required this.alertSigAsicMonitor,
    required this.adcInt,
    required this.motherboardEthInt,
    required this.pmicControl,
    required this.sataConnectorJ21Power,
    required this.sedesClkEn,
    required this.i2cMuxReset,
    required this.ftdiReset,
    required this.bromSdEn,
    required this.bromSdSel,
    required this.uartAsicFtdiMux,
    required this.jtagAsicFtdiMux,
    required this.sataERedriverEn,
    required this.displayportRedriver,
    required this.pmodSpi,
    required this.i2sAudioDacGain,
  });

  factory BoardDataModel.initial() {
    return BoardDataModel(
      boardName: "Unknown",
      id: 012345,
      status: 1,
      frequency: 50.0,
      voltage: 3.3,
      temperature: 35.0,
      humidity: 30.0,
      power: 12.0, 
      pressure: 1013.0,
      usb0PowSw: false,
      usb0Reset: false,
      usb0HsLed: false,
      usb0DetectedLed: false,
      usb1PowSw: false,
      usb1Reset: false,
      usb1HsLed: false,
      usb1DetectedLed: false,
      usbcEsdStatus: false,
      pcieStatus: false,
      pcieOutputs: 0,
      pcieSsSelTri: false,
      pcieBufferState: 0,
      asicEthInt: false,
      alertSigAsicMonitor: false,
      adcInt: false,
      motherboardEthInt: false,
      pmicControl: false,
      sataConnectorJ21Power: 0,
      sedesClkEn: false,
      i2cMuxReset: false,
      ftdiReset: false,
      bromSdEn: false,
      bromSdSel: 0,
      uartAsicFtdiMux: 0,
      jtagAsicFtdiMux: 0,
      sataERedriverEn: false,
      displayportRedriver: false,
      pmodSpi: 0,
      i2sAudioDacGain: 0,
    );
  }

  BoardDataModel copyWith({
    String? boardName,
    int? id,
    int? status,
    double? frequency,
    double? voltage,
    double? temperature,
    double? humidity,
    double? power,
    double? pressure,
    bool? usb0PowSw,
    bool? usb0Reset,
    bool? usb0HsLed,
    bool? usb0DetectedLed,
    bool? usb1PowSw,
    bool? usb1Reset,
    bool? usb1HsLed,
    bool? usb1DetectedLed,
    bool? usbcEsdStatus,
    bool? pcieStatus,
    int? pcieOutputs,
    bool? pcieSsSelTri,
    int? pcieBufferState,
    bool? asicEthInt,
    bool? alertSigAsicMonitor,
    bool? adcInt,
    bool? motherboardEthInt,
    bool? pmicControl,
    int? sataConnectorJ21Power,
    bool? sedesClkEn,
    bool? i2cMuxReset,
    bool? ftdiReset,
    bool? bromSdEn,
    int? bromSdSel,
    int? uartAsicFtdiMux,
    int? jtagAsicFtdiMux,
    bool? sataERedriverEn,
    bool? displayportRedriver,
    int? pmodSpi,
    int? i2sAudioDacGain,
  }) {
    return BoardDataModel(
      boardName: boardName ?? this.boardName,
      id: id ?? this.id,
      status: status ?? this.status,
      frequency: frequency ?? this.frequency,
      voltage: voltage ?? this.voltage,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      power: power ?? this.power,
      pressure: pressure ?? this.pressure,
      usb0PowSw: usb0PowSw ?? this.usb0PowSw,
      usb0Reset: usb0Reset ?? this.usb0Reset,
      usb0HsLed: usb0HsLed ?? this.usb0HsLed,
      usb0DetectedLed: usb0DetectedLed ?? this.usb0DetectedLed,
      usb1PowSw: usb1PowSw ?? this.usb1PowSw,
      usb1Reset: usb1Reset ?? this.usb1Reset,
      usb1HsLed: usb1HsLed ?? this.usb1HsLed,
      usb1DetectedLed: usb1DetectedLed ?? this.usb1DetectedLed,
      usbcEsdStatus: usbcEsdStatus ?? this.usbcEsdStatus,
      pcieStatus: pcieStatus ?? this.pcieStatus,
      pcieOutputs: pcieOutputs ?? this.pcieOutputs,
      pcieSsSelTri: pcieSsSelTri ?? this.pcieSsSelTri,
      pcieBufferState: pcieBufferState ?? this.pcieBufferState,
      asicEthInt: asicEthInt ?? this.asicEthInt,
      alertSigAsicMonitor: alertSigAsicMonitor ?? this.alertSigAsicMonitor,
      adcInt: adcInt ?? this.adcInt,
      motherboardEthInt: motherboardEthInt ?? this.motherboardEthInt,
      pmicControl: pmicControl ?? this.pmicControl,
      sataConnectorJ21Power: sataConnectorJ21Power ?? this.sataConnectorJ21Power,
      sedesClkEn: sedesClkEn ?? this.sedesClkEn,
      i2cMuxReset: i2cMuxReset ?? this.i2cMuxReset,
      ftdiReset: ftdiReset ?? this.ftdiReset,
      bromSdEn: bromSdEn ?? this.bromSdEn,
      bromSdSel: bromSdSel ?? this.bromSdSel,
      uartAsicFtdiMux: uartAsicFtdiMux ?? this.uartAsicFtdiMux,
      jtagAsicFtdiMux: jtagAsicFtdiMux ?? this.jtagAsicFtdiMux,
      sataERedriverEn: sataERedriverEn ?? this.sataERedriverEn,
      displayportRedriver: displayportRedriver ?? this.displayportRedriver,
      pmodSpi: pmodSpi ?? this.pmodSpi,
      i2sAudioDacGain: i2sAudioDacGain ?? this.i2sAudioDacGain,
    );
  }
}
