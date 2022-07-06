import 'package:flutter/material.dart';
import 'package:flutter_download_manager/setup.dart';
import 'package:flutter_download_manager/list.dart';

class App extends StatelessWidget {
  const App({ super.key }) : super();

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
        "/home": (context) => const Home(),
      },
    );
  }
}