part of '../isolated_download_manager.dart';

/// Request created by adding url to downloading queue
/// Used for communication with [DownloadManager] and internally [Isolate]
class DownloadRequest {
  DownloadRequest._({
    required this.url,
    this.path,
    this.filesize,
    this.safeRange,
    required this.cancel,
    required this.resume,
    required this.pause,
  }) {
    _controller = StreamController.broadcast(onListen: () {
      if (_lastEvent == null) return;
      if (_lastEvent is Exception) {
        _controller.addError(_lastEvent);
      }
      _controller.add(_lastEvent);
    });
  }

  String url;
  String? path;
  int? filesize;
  bool? safeRange;

  bool isPaused = false;
  bool isCancelled = false;

  /// Progress with ceiling
  /// `-1.0` for queued process and values in range [0.0, 1.0]
  double progress = -1.0;

  /// Stream controller used to forward isolate events to user
  late final StreamController<dynamic> _controller;
  Stream<dynamic> get events => _controller.stream;

  void _addEvent(dynamic event) {
    _controller.add(event);
    _lastEvent = event;
  }

  void _addError(dynamic event) {
    _controller.addError(event);
    _lastEvent = event;
  }

  /// Current state
  dynamic _lastEvent;
  dynamic get event => _lastEvent;

  /// Control methods
  final void Function() cancel;
  final void Function() resume;
  final void Function() pause;
}
