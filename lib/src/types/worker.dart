part of 'package:isolated_download_manager/src/download_manager.dart';

/// [_Worker] class stores long live isolate reference and current [DownloadRequest] if any 
class _Worker {
  _Worker({ required this.isolate, required this.port });
  final Isolate isolate;
  final SendPort port;
  DownloadRequest? request;

  /// Shortcuts to communicate with user
  void event(dynamic event) => request?._controller.add(event);
  void error(dynamic error) => request?._controller.addError(error);
}