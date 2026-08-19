import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mondragon_app/viewmodel/board_viewmodel.dart';
import 'package:provider/provider.dart';

import '../viewmodel/monitor_viewmodel.dart';

class RTMonitorScreen extends StatelessWidget {
  const RTMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final monitorViewModel = context.watch<MonitorViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        title: const Text("Monitor"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
              children: [
              // Multi-line chart
              _buildChartSection(monitorViewModel),
              const SizedBox(height: 24),
              const Padding(
                // Parameters
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  "CURRENT VALUES",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              _buildCurrentValuesSection(context),
              ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(MonitorViewModel monitor) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metric selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: availableMetrics().map((metric) {
                  final isSelected = monitor.selectedMetric == metric; //metric == Metrics.all;//monitor.selectedMetric;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(printMetrics(metric)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          monitor.updateSelectedMetric(metric);
                        }
                      },
                      selectedColor: metric == Metrics.all
                          ? Colors.blue.shade100
                          : Colors.blueGrey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blueGrey.shade900 : Colors.grey.shade600,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            _buildLiveChart(monitor), //TODO
          ],
        ),
      ),
    );
  }

  Widget _buildLiveChart(MonitorViewModel monitor) {
    List<LineChartBarData> lines = [];

    LineChartBarData createLine(List<FlSpot> spots, Color color) {
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.1),
        ),
      );
    }

    // add lines based on current selection
    if (monitor.selectedMetric == Metrics.temperature || monitor.selectedMetric == Metrics.all) {
      lines.add(createLine(monitor.temperatureHistory, Colors.deepOrange));
    }
    if (monitor.selectedMetric == Metrics.power || monitor.selectedMetric == Metrics.all) {
      lines.add(createLine(monitor.powerHistory, Colors.green));
    }
    if (monitor.selectedMetric == Metrics.pressure || monitor.selectedMetric == Metrics.all) {
      lines.add(createLine(monitor.pressureHistory, Colors.blueAccent));
    }
    if (monitor.selectedMetric == Metrics.humidity || monitor.selectedMetric == Metrics.all) {
      lines.add(createLine(monitor.humidityHistory, Colors.purple));
    }

    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.only(right: 22, left: 12, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: lines.isEmpty || lines.first.spots.isEmpty
          ? Center(child: CircularProgressIndicator(color: Colors.blueGrey.shade200))
          : LineChart(
        LineChartData(
          lineBarsData: lines,
          minX: lines.first.spots.first.x,
          maxX: lines.first.spots.last.x,
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 10,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12));
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildCurrentValuesSection(BuildContext context) {
    final board = context.watch<BoardViewModel>();

    final Map<Metrics, String> currentValues = {
      Metrics.humidity: '${board.humidity.toStringAsFixed(1)} %',
      Metrics.pressure: '${board.pressure.toStringAsFixed(1)} hPa',
      Metrics.power: '${board.power.toStringAsFixed(2)} W',
      Metrics.temperature: '${board.temperature.toStringAsFixed(2)} ºC',
      //Metrics.voltage: '${board.voltage.toStringAsFixed(2)} V',
    };

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: currentValues.entries.map((entry) {
          final isLast = entry.key == currentValues.keys.last;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      printMetrics(entry.key),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }
}