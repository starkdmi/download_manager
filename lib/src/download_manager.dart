import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:downlow/downlow.dart' as downlow;

part 'package:isolated_download_manager/src/types/request.dart';
part 'package:isolated_download_manager/src/types/worker.dart';
part 'package:isolated_download_manager/src/types/comm.dart';

class DownloadManager {
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();

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
      worker.event(DownloadEvent.cancelled);
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
  final List<_Worker> _workers = [];
  final Set<int> _freeWorkersIndexes = {};
  final Map<String, _Worker> _activeWorkers = {};

  /// Add request to the queue
  DownloadRequest add(String url) {
    final request = DownloadRequest._(url: url);
    _queue.add(request);
    request._controller.add(DownloadEvent.queued);
    _processQueue();
    return request;
  }

  /// Removes request from the queue or sending cancellation request to isolate
  void _cancel(String url) {
    if (!_queue.remove(url)) {
      // if wasn't removed from queue due to absence
      _activeWorkers[url]?.port.send(_WorkerCommand.cancel);
    }
  }

  /// Send pause request to isolate if exists 
  void _pause(String url) => _activeWorkers[url]?.port.send(_WorkerCommand.pause);

  /// Send resume request to isolate if exists 
  void _resume(String url) => _activeWorkers[url]?.port.send(_WorkerCommand.resume);

  /// Process queued requests
  void _processQueue() {
    if (_queue.isNotEmpty && _freeWorkersIndexes.isNotEmpty) {
      // request
      final request = _queue.removeFirst();
      final link = request.url;

      // worker
      final index = _freeWorkersIndexes.first;
      _freeWorkersIndexes.remove(index);
      final worker = _workers[index];
      worker.request = request;
      worker.port.send(link);
      _activeWorkers[link] = worker;
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
    _activeWorkers.remove(worker.request?.url);
    worker.request = null;
    _freeWorkersIndexes.add(index);
    _processQueue();
  }

  /// Initialize long running isolate with two-way communication channel
  Future<_Worker> _initWorker({ required int index }) async {
    final completer = Completer<_Worker>();
    final mainPort = ReceivePort();
    late final Isolate isolate;

    _Worker? process;
    mainPort.listen((event) {
      if (event is SendPort) {
        // port received after isolate is ready (once)
        process = _Worker(isolate: isolate, port: event);
        completer.complete(process);
      } else if (event is Exception) {
        // errors 
        process?.error(event);
        _cleanWorker(index);
      } else if (event is DownloadEvent) {
        // other incoming messages from isolate 
        switch (event) {
          case DownloadEvent.cancelled:
            process?.event(event);
            _cleanWorker(index);
            process?.request?.isCancelled = true;
            break;
          case DownloadEvent.finished:
            process?.event(event);
            _cleanWorker(index);
            break;
          case DownloadEvent.started:
            process?.event(event);
            break;
          case DownloadEvent.resumed:
            process?.event(event);
            process?.request?.isPaused = false;
            break;
          case DownloadEvent.paused:
            process?.event(event);
            process?.request?.isPaused = true;
            break;
          default: break;
        }
      } else if (event is double) {
        // progress events
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
      if (event is String) {
        // url to download
        final uri = Uri.parse(event);
        final lastSegment = uri.pathSegments.last;
        final filename = lastSegment.substring(lastSegment.lastIndexOf("/") + 1);

        final file = File("$directory/$filename");

        final options = downlow.DownloadOptions(
          file: file,
          deleteOnCancel: true,
          progressCallback: (current, total) {
            final progress = (current / total * 100).ceilToDouble();
            // skip duplicates
            if (previousProgress != progress) {
              sendPort.send(progress);
              previousProgress = progress;
            }
          },
          onDone: () {
            sendPort.send(DownloadEvent.finished);
          }
        );
        previousProgress = -1.0;
        
        // run zoned to catch download errors without breaking isolate
        runZonedGuarded(() async {
          await downlow.download(event, options)
            .then((controller) => task = controller)
            .then((_) => sendPort.send(DownloadEvent.started));
        }, (e, s) => sendPort.send(e));  

      } else if (event is _WorkerCommand) {
        // control events
        switch (event) {
          case _WorkerCommand.pause:
            task?.pause().then((_) => sendPort.send(DownloadEvent.paused));
            break;
          case _WorkerCommand.resume:
            task?.resume().then((_) => sendPort.send(DownloadEvent.resumed));
            break;
          case _WorkerCommand.cancel:
            task?.cancel().then((_) => sendPort.send(DownloadEvent.cancelled));
            break;
        }
      }
    });

    sendPort.send(isolatePort.sendPort);
  }
}