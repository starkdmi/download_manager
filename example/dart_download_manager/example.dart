import 'dart:io';
import 'package:isolated_download_manager/download_manager.dart';

void main() async {
  // Initialize
  final manager = DownloadManager.instance;
  // Here we create `n` amount of long running isolates available for downloader
  await manager.init(isolates: 1, directory: "/Users/starkdmi/Downloads/test");
  await Future.delayed(const Duration(seconds: 1));

  void dispose() {
    // Clean-up isolates
    manager.dispose().then((_) => exit(0));
  }

  // Download
  // final url = "https://storage.googleapis.com/dart-archive/channels/stable/release/2.17.5/sdk/dartsdk-macos-arm64-release.zip";
  final url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  final request = manager.add(url);
  request.events.listen((event) {
    if (event is DownloadEvent) {
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
      print("progress: $event%");
    }
  }, onError: (error) {
    print("error $error");
    dispose();
  }, onDone: () {
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