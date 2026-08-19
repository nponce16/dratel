import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/configuration_viewmodel.dart';

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

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configurationViewModel = context.watch<ConfigurationViewModel>();

    final groupedData = <String, List<MapEntry<int, RegisterData>>>{};
    for (var i = 0; i < configurationViewModel.registers.length; i++) {
      final reg = configurationViewModel.registers[i];
      final category = reg.category.isNotEmpty ? reg.category : 'Others';
      groupedData.putIfAbsent(category, () => []).add(MapEntry(i, reg));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        title: const Text("Board Configuration"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: configurationViewModel.registers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            itemCount: groupedData.keys.length,
            itemBuilder: (context, index) {
              final category = groupedData.keys.elementAt(index);
              final registers = groupedData[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 16.0),
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Column(
                      children: registers.asMap().entries.map((entry) {
                        final isLast = entry.key == registers.length - 1;
                        final originalIndex = entry.value.key;
                        final register = entry.value.value;

                        return Column(
                          children: [
                            RegisterRow(
                              register: register,
                              originalIndex: originalIndex,
                              viewModel: configurationViewModel,
                            ),
                            if (!isLast)
                              Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class RegisterRow extends StatelessWidget {
  final RegisterData register;
  final int originalIndex;
  final ConfigurationViewModel viewModel;

  const RegisterRow({
    super.key,
    required this.register,
    required this.originalIndex,
    required this.viewModel,
  });

  double getResponsiveControlWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // If desktop/linux
    if (screenWidth > 600) {
      return 160.0;
    }
    // If mobile
    else {
      return screenWidth * 0.38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlWidth = getResponsiveControlWidth(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              register.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: controlWidth,
            child: _buildDynamicControl(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicControl(BuildContext context) {
    // Read-only
    if (register.options.isEmpty) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          register.selectedValue ?? 'N/A',
          style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
              fontStyle: FontStyle.italic
          ),
        ),
      );
    }

    // Action Buttons
    if (register.options.contains('Reset') || register.options.contains('Trigger')) {
      return SizedBox(
        height: 38,
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            elevation: 0,
            foregroundColor: Colors.blueGrey.shade700,
            side: BorderSide(color: Colors.blueGrey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.zero,
          ),
          onPressed: () async {
            final confirmed = await _showConfirmationDialog(
              context,
              'Confirm ${register.options.contains('Reset') ? 'Reset' : 'Trigger'}',
              'Are you sure you want to ${register.options.contains('Reset') ? 'reset' : 'trigger'} ${register.name}?',
            );
            if (!confirmed) return;

            debugPrint('Hardware action triggered for: ${register.name}');
          },
          child: Text(
            register.options.contains('Reset') ? 'Reset' : 'Trigger',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // Dropdown Menu
    return Container(
      height: 38,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
          value: register.selectedValue,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
          items: register.options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            viewModel.updateRegisterValue(originalIndex, newValue);
          },
        ),
      ),
    );
  }
}