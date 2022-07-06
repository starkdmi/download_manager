part of 'package:isolated_download_manager/src/download_manager.dart';

/// Request created by adding url to downloading queue
/// Used for communication with [DownloadManager] and internally [Isolate]
class DownloadRequest {
  DownloadRequest._({ 
    required this.url, 
    this.path, 
    required void Function() cancel,
    required void Function() resume,
    required void Function() pause,
  }) : _cancel = cancel, _resume = resume, _pause = pause;

  String url;
  String? path;

  bool isPaused = false;
  bool isCancelled = false;

  /// Progress with ceiling
  /// `-1.0` for queued process and values in range [0.0, 1.0]
  double progress = -1.0;
  
  /// Stream controller used to forward isolate events to user
  final StreamController<dynamic> _controller = StreamController<dynamic>();
  Stream<dynamic> get events => _controller.stream;

  final void Function() _cancel;
  void cancel() {
    if (!isCancelled) {
      _cancel();
    }
  }

  final void Function() _resume;
  void resume() {
    if (isPaused && !isCancelled) {
      _resume();
    }
  }

  final void Function() _pause;
  void pause() {
    if (!isPaused && !isCancelled) {
      _pause();
    }
  }
}