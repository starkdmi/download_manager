import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Directory;

class Globals {
  Globals._();
  static final Globals instance = Globals._();

  static int isolates = 2;
  static String directory = "/tmp/downloads";
  static Map<String ,String> links = {
    "Dart": "https://storage.googleapis.com/dart-archive/channels/stable/release/2.17.5/sdk/dartsdk-macos-arm64-release.zip",
    "Golang": "https://golang.org/dl/go1.17.3.src.tar.gz",
    "Python": "https://www.python.org/ftp/python/3.10.5/python-3.10.5-macos11.pkg",
    "Ruby": "https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.2.tar.gz",
    "Scala": "https://github.com/lampepfl/dotty/releases/download/3.1.3/scala3-3.1.3.zip",
    "NodeJS": "https://nodejs.org/dist/v16.15.1/node-v16.15.1.pkg",
    "HTML": "https://not.found/html.txt"
  };

  static Future<void> init() async {
    // default directory
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    directory = "$appDocPath/downloads";
    debugPrint(directory);

    await clean();

    // create if none
    final dir = Directory(directory);
    if (!await dir.exists()) {
      await dir.create();
    }
  }

  static Future<void> clean({removeDirectory = false}) async {
    // remove files in default directory 
    final dir = Directory(directory);
    if (await dir.exists()) {
      await for (final file in dir.list()) {
        if (await file.exists()) {
          await file.delete();
        }
      }
      if (removeDirectory) {
        dir.delete();
      }
    }
  }
}