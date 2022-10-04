part of '../isolated_download_manager.dart';

/// [Worker] class stores long live isolate reference and current [DownloadRequest] if any
class Worker {
  Worker({required this.isolate, required this.port});
  final Isolate isolate;
  final SendPort port;
  DownloadRequest? request;

  /// Shortcuts to communicate with user
  void event(dynamic event) => request?._addEvent(event);
  void error(dynamic error) => request?._addError(error);
}
