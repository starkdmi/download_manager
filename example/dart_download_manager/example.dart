import 'dart:io';
import 'package:isolated_download_manager/download_manager.dart';

const directory = "/Users/starkdmi/Downloads/test";
const links = [
  "https://golang.org/dl/go1.17.3.src.tar.gz",
  "https://storage.googleapis.com/dart-archive/channels/stable/release/2.17.5/sdk/dartsdk-macos-arm64-release.zip",
  "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
];

void main() async {
  // Initialize
  final manager = DownloadManager.instance;
  // Here we create `n` amount of long running isolates available for downloader
  await manager.init(isolates: 1, directory: directory);
  await Future.delayed(const Duration(seconds: 1));

  void dispose() {
    // Clean-up isolates
    manager.dispose().then((_) => exit(0));
  }

  // Download
  final request = manager.download(links[2]);
  // final request = manager.download(links[1], path: "$directory/dart.zip");
  
  // Progress
  request.events.listen((event) {
    if (event is DownloadState) {
      print("event: $event");
      /*switch (event) {
        case DownloadEvent.queued:
          break;
        case DownloadEvent.started:
          break;
        case DownloadEvent.paused:
          break;
        case DownloadEvent.resumed:
          break;
        case DownloadEvent.cancelled:
          break;
        case DownloadEvent.finished:
          break;
      }*/
    } else if (event is double) {
      print("progress: ${event * 100}%");
    }
  }, onError: (error) {
    print("error $error");
    dispose();
  }, onDone: () async {
    await Future.delayed(const Duration(milliseconds: 1500));
    dispose();
  });

  // Methods
  await Future.delayed(const Duration(milliseconds: 1000));
  request.pause();
  await Future.delayed(const Duration(milliseconds: 1000));
  request.resume();
  // await Future.delayed(const Duration(milliseconds: 1000));
  // request.cancel();

  // Properties
  // print(request.progress);
  // print(request.isPaused);
  // print(request.isCancelled);
}