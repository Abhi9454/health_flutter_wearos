import 'package:flutter/material.dart';
import 'package:health_flutter/screens/read_health_widget.dart';
import 'package:health_flutter/viewModels/getData.dart';
import 'package:workmanager/workmanager.dart';

// @pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) {
//     GetData getData = GetData();
//     getData.readData();
//     return Future.value(true);
//   });
//}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Workmanager().initialize(
  //     callbackDispatcher, // The top level function, aka callbackDispatcher
  //     isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  // );
  // Workmanager().registerPeriodicTask("task-identifier", "simpleTask", frequency: const Duration(minutes: 30),);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HealthApp(),
    )
);}
