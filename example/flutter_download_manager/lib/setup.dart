import 'package:flutter/material.dart';

class Setup extends StatelessWidget {
  const Setup({ super.key }) : super();

  // static const url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  // static const url = "https://storage.googleapis.com/dart-archive/channels/stable/release/2.17.5/sdk/dartsdk-macos-arm64-release.zip";

  static int isolates = 1;
  static String directory = "/Users/starkdmi/Downloads/test";
  static Map<String ,String> links = {
    "Dart": "https://storage.googleapis.com/dart-archive/channels/stable/release/2.17.5/sdk/dartsdk-macos-arm64-release.zip",
    "Golang": "https://golang.org/dl/go1.17.3.src.tar.gz",
    "Python": "https://www.python.org/ftp/python/3.10.5/python-3.10.5-macos11.pkg",
    "Ruby": "https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.2.tar.gz",
    "Scala": "https://github.com/lampepfl/dotty/releases/download/3.1.3/scala3-3.1.3.zip",
    "NodeJS": "https://nodejs.org/dist/v16.15.1/node-v16.15.1.pkg"
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Download Manager"),
      ),
      body: Center(child: 

        // TODO isolates amount, directory

        TextButton(
          onPressed: () => Navigator.of(context).pushNamed("/home"), 
          child: const Text("Let's go")
        )
      )
    );
  }
}