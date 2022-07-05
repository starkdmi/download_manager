part of 'package:isolated_download_manager/src/download_manager.dart';

/// Request created by adding url to downloading queue
/// Used for communication with [DownloadManager] and internally [Isolate]
class DownloadRequest {
  DownloadRequest._({ required this.url });
  String url;

  bool isPaused = false;
  bool isCancelled = false;

  /// Progress with ceiling
  /// `-1.0` for queued process and values in range [0.0, 100.0]
  double progress = -1.0;
  
  /// Stream controller used to forward isolate events to user
  final StreamController<dynamic> _controller = StreamController<dynamic>();
  Stream<dynamic> get events => _controller.stream;

  void cancel() => DownloadManager.instance._cancel(url);
  void resume() => DownloadManager.instance._resume(url);
  void pause() => DownloadManager.instance._pause(url);
}