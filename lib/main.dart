import 'package:flutter/material.dart';
import 'package:mondragon_app/viewmodel/bt_viewmodel.dart';
import 'package:provider/provider.dart';

import './viewmodel/home_viewmodel.dart';
import './viewmodel/board_viewmodel.dart';
import './viewmodel/configuration_viewmodel.dart';
import './viewmodel/monitor_viewmodel.dart';

import './view/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => BoardViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => BluetoothViewModel(),
        ),
        ChangeNotifierProxyProvider<BoardViewModel, ConfigurationViewModel>(
          create: (context) => ConfigurationViewModel(
              boardViewModel: context.read<BoardViewModel>(),
          ),
          update: (context, boardViewModel, previousViewModel) =>
          previousViewModel ?? ConfigurationViewModel(boardViewModel: boardViewModel),
        ),
        ChangeNotifierProxyProvider<BoardViewModel, MonitorViewModel>(
          create: (context) => MonitorViewModel(
            boardViewModel: context.read<BoardViewModel>(),
          ),
          update: (context, boardViewModel, previousViewModel) =>
          previousViewModel ?? MonitorViewModel(boardViewModel: boardViewModel),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mondragon App Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const HomeScreen(),
    );
  }
}