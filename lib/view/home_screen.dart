import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/board_viewmodel.dart';
//import '../viewmodel/home_viewmodel.dart';

import 'bt_screen.dart';
import 'control_screen.dart';
//import 'home_screen_mm.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void showSimulationWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bluetooth is disabled in Simulation Mode"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //final homeViewModel = context.watch<HomeViewModel>();
    final boardViewModel = context.watch<BoardViewModel>();
    final isSimulation = boardViewModel.isSimulation;
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        title: GestureDetector(
          onTap:() {
            // TODO: easter egg logic :)
          },
          child: const Text(
            "Hello Board!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
        ),

        actions: [
          Padding (
            padding: const EdgeInsets.only(right: 16.0),
            child: Transform.scale(
              scale: 1.0,
              child: Switch(
                value: isSimulation,

                activeThumbColor: Colors.green,
                activeTrackColor: Colors.green.shade300,

                inactiveThumbColor: Colors.lightBlue,
                inactiveTrackColor: Colors.lightBlue.shade300,

                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),

                thumbIcon: WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Icon(Icons.memory, color: Colors.white); // SIM mode
                  }
                  return const Icon(Icons.bluetooth, color: Colors.white); // BT mode
                }),

                onChanged: (bool value) {
                  context.read<BoardViewModel>().toggleSimulationMode(value);
                },
              ),
            ),
          ),
        ],
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // -- Bluetooth Devices Button --
            CustomMenuButton(
              buttonIcon: Icons.bluetooth,

              // if disable change to grey
              iconColor: isSimulation ? Colors.grey : Colors.lightBlue,
              buttonLabel: "Bluetooth Devices",

              // if disable show warning
              onButtonPressed: isSimulation
                  ? () => showSimulationWarning(context)
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BluetoothScreen()),
                      );
                    },
            ),

            const SizedBox(height: 40),

            // -- Control Panel Button --
            CustomMenuButton(
              buttonIcon: Icons.settings_remote,
              iconColor: Colors.amberAccent,
              buttonLabel: "Control Panel",
              onButtonPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ControlScreen()),
                );
              },
            ),
          ],
        ),
      )
    );
  }
}

// Reusable custom widget for the menu buttons
class CustomMenuButton extends StatelessWidget {
  final IconData buttonIcon;
  final Color iconColor;
  final String buttonLabel;
  final VoidCallback onButtonPressed;

  const CustomMenuButton({
    super.key,
    required this.buttonIcon,
    required this.iconColor,
    required this.buttonLabel,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(buttonIcon, size: 36, color: iconColor),
      label: Text(
        buttonLabel,
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        elevation: 12,
      ),
      onPressed: onButtonPressed,
    );
  }
}