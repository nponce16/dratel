import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
//import 'package:mondragon_app/model/api.dart';

import 'board_viewmodel.dart';

enum Metrics {
  all,
  humidity,
  power,
  pressure,
  temperature
}

String printMetrics(Metrics metric) {
  switch (metric) {
    case Metrics.all:
      return "All";
    case Metrics.humidity:
      return "Humidity";
    case Metrics.power:
      return "Power";
    case Metrics.temperature:
      return "Temperature";
    case Metrics.pressure:
      return "Pressure";
  }
}

List<Metrics> availableMetrics() {
  return <Metrics>[
    Metrics.all,
    Metrics.humidity,
    Metrics.power,
    Metrics.pressure,
    Metrics.temperature
  ];
}

class MonitorViewModel extends ChangeNotifier {
  final BoardViewModel boardViewModel;

  Metrics _selectedMetric = Metrics.all;
  Metrics get selectedMetric => _selectedMetric;

  // Data configuration
  final int _maxDataPoint = 50;
  double _timeCounter = 0;

  // Lists to store the data
  List<FlSpot> humidityHistory = [];
  List<FlSpot> powerHistory = [];
  List<FlSpot> pressureHistory = [];
  List<FlSpot> temperatureHistory = [];
  List<FlSpot> voltageHistory = [];

  MonitorViewModel({required this.boardViewModel}) {
    boardViewModel.addListener(_captureData);
  }

  void updateSelectedMetric(Metrics metric) {
    if (_selectedMetric != metric) {
      _selectedMetric = metric;
      notifyListeners();
    }
  }

  void _addPoint(List<FlSpot> list, double value) {
    if (list.length >= _maxDataPoint) list.removeAt(0);

    list.add(FlSpot(_timeCounter, value));
  }

  void _captureData() {
    _timeCounter += 1;

    _addPoint(humidityHistory, boardViewModel.humidity);
    _addPoint(powerHistory, boardViewModel.power);
    _addPoint(pressureHistory, boardViewModel.pressure);
    _addPoint(temperatureHistory, boardViewModel.temperature);
    _addPoint(voltageHistory, boardViewModel.voltage);

    //TODO: 1. read all the metrics
    //TODO: 2. add the metrics to the historical list

    notifyListeners();
  }

}