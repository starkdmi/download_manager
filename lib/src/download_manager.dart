import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:downlow/downlow.dart' as downlow;

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

  /// Initialize instance 
  /// [isolates] amount of isolates to use
  /// [isolates] should be less than `Platform.numberOfProcessors - 3`
  /// [directory] where to save files, without trailing slash `/`, default to `/tmp`
  Future<void> init({ int isolates = 3, String? directory }) async {
    if (initialized) throw Exception("Already initialized");

    // Must be set before isolates initializing, otherwise default one will be used
    _directory = directory;

    await Future.wait([
      for (var i = 0; i < isolates; i++) _initWorker(index: i)
    ]).then(_workers.addAll);

    for (var i = 0; i < isolates; i++) {
      _freeWorkersIndexes.add(i);
    }

    initialized = true;
  }

  Future<void> dispose() async {
    _queue.clear();

    for (var worker in _workers) { 
      worker.event(DownloadState.cancelled);
      Future.delayed(const Duration(milliseconds: 100))
        .then((_) => worker.isolate.kill());
    }
    await Future.delayed(const Duration(milliseconds: 100));
    _workers.clear();
    _activeWorkers.clear();
    _freeWorkersIndexes.clear();

    initialized = false;
  }

  /// Queue of requests 
  final _queue = Queue<DownloadRequest>();

  /// Isolates references
  final List<Worker> _workers = [];
  final Set<int> _freeWorkersIndexes = {};
  final Map<DownloadRequest, Worker> _activeWorkers = {};

  /// Add request to the queue
  /// if [path] is empty base [_directory] used
  DownloadRequest download(String url, { String? path }) {
    late final DownloadRequest request;
    request = DownloadRequest._(
      url: url,
      path: path,
      cancel: () { _cancel(request); },
      resume: () { _resume(request); },
      pause: () { _pause(request); }
    );
    _queue.add(request);
    request._controller.add(DownloadState.queued);
    _processQueue();
    return request;
  }

  /// Removes request from the queue or sending cancellation request to isolate
  void _cancel(DownloadRequest request) {
    if (!_queue.remove(request)) {
      // if wasn't removed from queue due to absence
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
        if (path != null) "path": path
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
    if (worker.request?._controller.hasListener == true) {
      // worker.event(DownloadEvents.finished);
      worker.request?._controller.close();
    } 
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
    
    downlow.DownloadController? task;
    double previousProgress = -1.0;
    isolatePort.listen((event) {
      if (event is Map<String, String>) {
        // download info
        try {
          final String url = event["url"]!;
          final String? path = event["path"];

          final File file;
          if (path == null) {
            // use base directory, extract name from url
            final uri = Uri.parse(url);
            final lastSegment = uri.pathSegments.last;
            final filename = lastSegment.substring(lastSegment.lastIndexOf("/") + 1);
            file = File("$directory/$filename");
          } else {
            // custom location
            file = File(path);
            // final filename = file.uri.pathSegments.last;
          }

          final options = downlow.DownloadOptions(
            file: file,
            deleteOnCancel: true,
            progressCallback: (current, total) {
              final progress = (current / total * 100).floorToDouble() / 100;

              // skip duplicates
              if (previousProgress != progress) {
                sendPort.send(progress);
                previousProgress = progress;
              }
            },
            onDone: () {
              sendPort.send(DownloadState.finished);
            }
          );
          
          previousProgress = -1.0;
          
          // run zoned to catch async download excaptions without breaking isolate
          runZonedGuarded(() async {
            await downlow.download(url, options)
              .then((controller) => task = controller)
              .then((_) => sendPort.send(DownloadState.started));
          }, (e, s) => sendPort.send(e));  
          
        } catch (error) {
          // catch sync exception
          sendPort.send(error);
        }
      } else if (event is WorkerCommand) {
        // control events
        switch (event) {
          case WorkerCommand.pause:
            if (task?.isCancelled == false && task?.isDownloading == true) {
              task?.pause().then((_) => sendPort.send(DownloadState.paused));
            }
            break;
          case WorkerCommand.resume:
            if (task?.isCancelled == false && task?.isDownloading == false) {
              task?.resume().then((_) => sendPort.send(DownloadState.resumed));
            }
            break;
          case WorkerCommand.cancel:
            if (task?.isCancelled == false) {
              task?.cancel().then((_) => sendPort.send(DownloadState.cancelled));
            }
            break;
        }
      }
    });

    sendPort.send(isolatePort.sendPort);
  }
}