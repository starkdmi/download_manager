import 'package:flutter/material.dart';
import 'package:flutter_download_manager_example/screens/setup.dart';
import 'package:flutter_download_manager_example/screens/list.dart';
import 'package:flutter_download_manager_example/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Globals.init();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({ super.key }) : super();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Download Manager",
      theme: ThemeData(
        primarySwatch: Colors.red,
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade400) 
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => const Setup(),
        "/home": (context) => const DownloadList(),
      },
    );
  }
}