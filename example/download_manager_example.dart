import 'dart:io' show exit;
import 'package:isolated_download_manager/download_manager.dart';

void main() async {
  // Initialize
  await DownloadManager.instance.init(isolates: 3);

  // Download
  final request = DownloadManager.instance
      .download("https://golang.org/dl/go1.19.1.src.tar.gz");

  // Listen
  request.events.listen((event) {
    if (event is DownloadState) {
      print("event: $event");
      if (event == DownloadState.finished) dispose();
    } else if (event is double) {
      print("progress: ${(event * 100.0).toStringAsFixed(0)}%");
    }
  }, onError: (error) {
    print("error $error");
    dispose();
  });

  // Methods
  await Future.delayed(const Duration(milliseconds: 1500));
  request.pause();
  await Future.delayed(const Duration(milliseconds: 1500));
  request.resume();
  await Future.delayed(const Duration(milliseconds: 1500));
  request.cancel();

  // Properties
  print(request.progress);
  print(request.isPaused);
  print(request.isCancelled);

  // List queued requests
  print(DownloadManager.instance.queue);
}

// Clean-up isolates and exit
void dispose() => DownloadManager.instance.dispose().then((_) => exit(0));
