import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/board_viewmodel.dart';

import 'configuration_screen.dart';
import 'rt_monitor_screen.dart';
import 'manual_update_screen.dart';

Future<bool> _showConfirmationDialog(
    BuildContext context, String title, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
  return result == true;
}

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control Panel"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -- Board Information --
            BoardInfoCard(),
            const SizedBox(height: 24),

            // -- Grid with features --
            const Text(
              "Features",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),

            const Expanded(
              child: ControlFeaturesGrid(),
            ),
          ],
        ),
      ),
    );
  }
}

class BoardInfoCard extends StatelessWidget {
  const BoardInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final boardViewModel = context.watch<BoardViewModel>();
    final boardName = boardViewModel.boardName;
    final boardId = boardViewModel.boardId;
    final frequency = boardViewModel.voltage;
    final temperature = boardViewModel.temperature;
    final status = boardViewModel.status;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Connected Board",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),

                  InfoTextRow(label: "Name", value: boardName),
                  const SizedBox(height: 4),

                  InfoTextRow(label: "Id", value: boardId),
                  const SizedBox(height: 4),

                  InfoTextRow(label: "Frequency", value: "$frequency Hz"),
                  const SizedBox(height: 4),

                  InfoTextRow(label: "Status", value: status),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thermostat, color: Colors.deepOrange, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    "${temperature.toStringAsFixed(1)} ºC",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for the Grid of features
class ControlFeaturesGrid extends StatefulWidget {
  const ControlFeaturesGrid({super.key});

  @override
  State<ControlFeaturesGrid> createState() => _ControlFeaturesGridState();
}

class _ControlFeaturesGridState extends State<ControlFeaturesGrid> {
  @override
  Widget build(BuildContext context) {
    final boardViewModel = context.watch<BoardViewModel>();
    final isPoweredOn = boardViewModel.isPoweredOn;

    return GridView.builder(
      // This is the magic formula for responsive grids
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 160,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return FeatureTile(
              title: "Power",
              icon: Icons.power_settings_new,
              color: isPoweredOn ? Colors.green : Colors.redAccent,
              onTap: () async {
                // ignore: use_build_context_synchronously
                final boardViewModel = context.read<BoardViewModel>();
                final currentContext = context;
                if (boardViewModel.isPoweredOn) {
                  final confirmed = await _showConfirmationDialog(
                    currentContext,
                    'Turn off board?',
                    'Are you sure you want to turn off the board?',
                  );
                  if (!confirmed) return;

                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Turning the board off...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  await boardViewModel.togglePower();
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.popUntil(currentContext, (route) => route.isFirst);
                  }
                } else {
                  boardViewModel.togglePower();
                }
              },
            );
          case 1:
            return FeatureTile(
              title: "Manual Reset",
              icon: Icons.restart_alt,
              color: isPoweredOn ? Colors.orangeAccent : Colors.grey,
              onTap: isPoweredOn
                  ? () async {
                // ignore: use_build_context_synchronously
                final currentContext = context;
                final confirmed = await _showConfirmationDialog(
                  currentContext,
                  'Reset board?',
                  'Are you sure you want to reset the board?',
                );
                if (!confirmed) return;

                if (mounted) {
                  // ignore: use_build_context_synchronously
                  currentContext.read<BoardViewModel>().manualReset();
                }
              }
                  : null,
            );
          case 2:
            return FeatureTile(
              title: "Real-time Monitor",
              icon: Icons.monitor_heart,
              color: isPoweredOn ? Colors.lightBlue : Colors.grey,
              onTap: isPoweredOn
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RTMonitorScreen()),
                );
              }
                  : null,
            );
          case 3:
            return FeatureTile(
              title: "Configuration",
              icon: Icons.memory,
              color: isPoweredOn ? Colors.deepPurpleAccent : Colors.grey,
              onTap: isPoweredOn
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConfigurationScreen()),
                );
              }
                  : null,
            );
          case 4:
            return FeatureTile(
              title: "Manual Update",
              icon: Icons.sd_storage,
              color: isPoweredOn ? Colors.teal : Colors.grey,
              onTap: isPoweredOn
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManualUpdateScreen()),
                );
              }
                  : null,
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

// Reusable Widget for each individual tile
class FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const FeatureTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable rows to display label: value
class InfoTextRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoTextRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: Colors.blueGrey.shade800),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 16),
    );
  }
}