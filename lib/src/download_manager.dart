import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:download_task/download_task.dart';
import 'package:http/http.dart' as http;

part 'package:isolated_download_manager/src/types/request.dart';
part 'package:isolated_download_manager/src/types/worker.dart';
part 'package:isolated_download_manager/src/types/comm.dart';

class DownloadManager {

  /// Singletone
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();

  /// Public constructor
  DownloadManager();

  /// Current initialization status
  bool initialized = false;

  /// Base directory where to save files
  String? _directory; 

  /// Base client cloned for each isolate during spawning
  http.BaseClient? _client; 

  /// Initialize instance 
  /// [isolates] amount of isolates to use
  /// [isolates] should be less than `Platform.numberOfProcessors - 3`
  /// [directory] where to save files, without trailing slash `/`, default to `/tmp`
  Future<void> init({ int isolates = 3, String? directory, http.BaseClient? client }) async {
    if (initialized) throw Exception("Already initialized");

    // Must be set before isolates initializing, otherwise default one will be used
    _directory = directory;
    _client = client;

    await Future.wait([
      for (var i = 0; i < isolates; i++) _initWorker(index: i)
    ]).then(_workers.addAll);

    for (var i = 0; i < isolates; i++) {
      _freeWorkersIndexes.add(i);
    }

    initialized = true;
    _processQueue();
  }

  Future<void> dispose() async {
    _queue.clear();

    for (var worker in _workers) { 
      worker.isolate.kill();
    }
    _activeWorkers.forEach((request, worker) { 
      Future.delayed(const Duration(milliseconds: 50))
        .then((_) => worker.port.send(WorkerCommand.cancel));
      Future.delayed(const Duration(milliseconds: 100))
        .then((_) => worker.isolate.kill());
    });
    await Future.delayed(const Duration(milliseconds: 100));
    _workers.clear();
    _activeWorkers.clear();
    _freeWorkersIndexes.clear();

    initialized = false;
  }

  /// Queue of requests 
  final _queue = Queue<DownloadRequest>();
  /// Queued requests (unmodifiable)
  List<DownloadRequest> get queue => _queue.toList();

  /// Isolates references
  final List<Worker> _workers = [];
  final Set<int> _freeWorkersIndexes = {};
  final Map<DownloadRequest, Worker> _activeWorkers = {};

  /// Add request to the queue
  /// if [path] is empty base [_directory] used
  DownloadRequest download(String url, { String? path, int? filesize }) {
    late final DownloadRequest request;
    request = DownloadRequest._(
      url: url,
      path: path,
      filesize: filesize,
      cancel: () { _cancel(request); },
      resume: () { _resume(request); },
      pause: () { _pause(request); }
    );
    _queue.add(request);
    request._addEvent(DownloadState.queued);
    _processQueue();
    return request;
  }

  /// Clear the queue and cancel all active requests
  void cancelAll() async {
    final requests = _queue.toList();
    _queue.clear();
    for (var request in requests) {
      request._addEvent(DownloadState.cancelled);
      request.isCancelled = true;
    }
    _activeWorkers.forEach((request, worker) { 
      worker.port.send(WorkerCommand.cancel);
      // ensure if wasn't cancelled due to pre-started downloading state
      for (final delay in [500, 1000, 1500]) {
        Future.delayed(Duration(milliseconds: delay)).then((_) {
          if (worker.request == request) {
            worker.port.send(WorkerCommand.cancel);
          }
        });
      }
    });
  }

  /// Removes request from the queue or sending cancellation request to isolate
  void _cancel(DownloadRequest request) {
    if (_queue.remove(request)) {
      // removed
      request._addEvent(DownloadState.cancelled);
      request.isCancelled = true;
    } else {
      // wasn't removed, already in progress
      _activeWorkers[request]?.port.send(WorkerCommand.cancel);
    }
  }

  /// Send pause request to isolate if exists 
  void _pause(DownloadRequest request) => _activeWorkers[request]?.port.send(WorkerCommand.pause);

  /// Send resume request to isolate if exists 
  void _resume(DownloadRequest request) => _activeWorkers[request]?.port.send(WorkerCommand.resume);

  /// Process queued requests
  void _processQueue() {
    if (_queue.isNotEmpty && _freeWorkersIndexes.isNotEmpty) {
      // request
      final request = _queue.removeFirst();
      final link = request.url;
      final path = request.path;

      // data 
      final Map<String, String> data = {
        "url": link,
        if (path != null) "path": path,
        "size": request.filesize.toString(),
      };

      // worker
      final index = _freeWorkersIndexes.first;
      _freeWorkersIndexes.remove(index);
      final worker = _workers[index];
      worker.request = request;

      // proceed
      worker.port.send(data);
      _activeWorkers[request] = worker;
    }
  }

  /// Prepare isolate for the next request
  Future<void> _cleanWorker(int index) async {
    await Future.delayed(Duration.zero);

    final worker = _workers[index];
    /*if (worker.request?._controller.hasListener == true) {
      // worker.event(DownloadEvents.finished);
      worker.request?._controller.close();
    } */
    _activeWorkers.remove(worker.request);
    worker.request = null;
    _freeWorkersIndexes.add(index);
    _processQueue();
  }

  /// Initialize long running isolate with two-way communication channel
  Future<Worker> _initWorker({ required int index }) async {
    final completer = Completer<Worker>();
    final mainPort = ReceivePort();
    late final Isolate isolate;

    Worker? process;
    mainPort.listen((event) {
      if (event is SendPort) {
        // port received after isolate is ready (once)
        process = Worker(isolate: isolate, port: event);
        completer.complete(process);
      } else if (event is Exception) {
        // errors 
        process?.error(event);
        _cleanWorker(index);
      } else if (event is DownloadState) {
        // other incoming messages from isolate 
        switch (event) {
          case DownloadState.cancelled:
            process?.event(event);
            _cleanWorker(index);
            process?.request?.isCancelled = true;
            break;
          case DownloadState.finished:
            process?.event(event);
            _cleanWorker(index);
            break;
          case DownloadState.started:
            process?.event(event);
            break;
          case DownloadState.resumed:
            process?.event(event);
            process?.request?.isPaused = false;
            break;
          case DownloadState.paused:
            process?.event(event);
            process?.request?.isPaused = true;
            break;
          default: break;
        }
      } else if (event is double) {
        // states
        process?.event(event);
        process?.request?.progress = event;
      }
    });
    
    isolate = await Isolate.spawn(_isolatedWork, mainPort.sendPort);
    
    return completer.future;
  }

  /// Isolate's body. After two-way binding isolate receives urls and proceed downloadings
  void _isolatedWork(SendPort sendPort) {
    final isolatePort = ReceivePort();
    final directory = _directory ?? "/tmp";
    // clone the client
    final client = _client ?? http.Client();

    DownloadTask? task;
    double previousProgress = -1.0;
    isolatePort.listen((event) {
      if (event is Map<String, String>) {
        // download info
        try {
          final Uri url = Uri.parse(event["url"]!);
          final String? path = event["path"];
          final String? sizeString = event["size"];
          final int? size = sizeString != null ? int.tryParse(sizeString) : null;

          final File file;
          if (path == null) {
            // use base directory, extract name from url
            final lastSegment = url.pathSegments.last;
            final filename = lastSegment.substring(lastSegment.lastIndexOf("/") + 1);
            file = File("$directory/$filename");
          } else {
            // custom location
            file = File(path);
            // final filename = file.uri.pathSegments.last;
          }
          previousProgress = -1.0;
          
          // run zoned to catch async download excaptions without breaking isolate
          runZonedGuarded(() async {
            await DownloadTask.download(url, file: file, client: client, deleteOnCancel: true, size: size).then((t) {
              task = t;
              task!.events.listen((event) { 
                switch (event.state) {
                  case TaskState.downloading:
                    final bytesReceived = event.bytesReceived!;
                    final totalBytes = event.totalBytes!;
                    
                    double progress;
                    if (totalBytes == -1) {
                      // total is undefined
                      progress = 0.0;
                    } else {
                      progress = (bytesReceived / totalBytes * 100).floorToDouble() / 100;
                    }

                    // skip duplicates
                    if (previousProgress != progress) {
                      sendPort.send(progress);
                      previousProgress = progress;
                    }
                    break;
                  case TaskState.paused:
                    sendPort.send(DownloadState.paused);
                    break;
                  case TaskState.success:
                    sendPort.send(DownloadState.finished);
                    break;
                  case TaskState.canceled:
                    sendPort.send(DownloadState.cancelled);
                    break;
                  case TaskState.error:
                    sendPort.send(event.error!);
                    break;
                }
              });
              sendPort.send(DownloadState.started);
            });
          }, (e, s) => sendPort.send(e));  
          
        } catch (error) {
          // catch sync exception
          sendPort.send(error);
        }
      } else if (event is WorkerCommand) {
        // control events
        switch (event) {
          case WorkerCommand.pause:
            task?.pause();
            break;
          case WorkerCommand.resume:
            task?.resume().then((status) {
              if (status) sendPort.send(DownloadState.resumed);
            });
            break;
          case WorkerCommand.cancel:
            task?.cancel();
            break;
        }
      }
    });

    sendPort.send(isolatePort.sendPort);
  }
}