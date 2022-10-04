File download manager based on reusable isolates with progress, cancellation, pause and resume

## Features

- **Fully isolated** - create any amount of reusable isolates, all handled internally
- **Powerfull** - pause, resume, cancel, download queue and many more
- **Listen to updates** - realtime progress and failure handling
- **UI** - use ready-to-use Flutter widgets (optionally via [isolated_download_manager_flutter](https://pub.dev/packages/isolated_download_manager_flutter))
- **Pure Dart** - only `http` dependency 

## Getting started

Include latest version from [pub.dev](https://pub.dev/packages/isolated_download_manager) to `pubspec.yaml`

## Usage

```dart
// initialize
await DownloadManager.instance.init(isolates: 3);

// download
final request = DownloadManager.instance.download(url);

// listen to state changes
request.events.listen((event) { ... }

// control the task
request.pause();
request.resume();
request.cancel();
```
Example full source code available at [example's directory](example/isolated_download_manager_example.dart)

## Additional information

For resumable downloads [download_task](https://pub.dev/packages/download_task) package used
