part of 'package:isolated_download_manager/src/download_manager.dart';

/// Communication types
/// User <-> DownloadManager <-> Isolate

/// Isolate commands
enum WorkerCommand {
  cancel, pause, resume
}

/// Stream return types
/// Errors will be send as throw 
/// progress send as double [0.0, 1.0]
/// other events are part of [DownloadState]
enum DownloadState {
  queued, started, paused, resumed, cancelled, finished
}
