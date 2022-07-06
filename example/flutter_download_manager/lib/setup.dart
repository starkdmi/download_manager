import 'package:flutter/material.dart';

class Setup extends StatelessWidget {
  const Setup({ super.key }) : super();

  // static const url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  static const url = "https://storage.googleapis.com/dart-archive/channels/stable/release/2.17.5/sdk/dartsdk-macos-arm64-release.zip";
  static const directory = "/Users/starkdmi/Downloads/test";
  static int isolates = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Download Manager"),
      ),
      body: Center(child: 
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed("/home"), 
          child: const Text("Let's go")
        )
      )
    );
  }
}